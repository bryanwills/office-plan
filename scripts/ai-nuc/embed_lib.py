"""
embed_lib.py — shared code for the ingest-folder embedding pipeline.

Used by embed-file.py (called from index-ingest.sh's EMBED HOOK) and
embed-query.py (manual/agent CLI search). Not a general-purpose library —
scoped tightly to this one pipeline.

Storage: a single SQLite file with the sqlite-vec extension for vector
search. No new service, no new port, no cloud dependency — this is
deliberately the smallest thing that gives real semantic search over the
ingest folder. See docs/infrastructure/ai-nuc-smb-mount.md §10 for the
migration path to Postgres/pgvector (or Supabase) if/when the "Open Brain"
project in PROJECT_STATE.md gets built for real.
"""

from __future__ import annotations

import json
import os
import re
import sqlite3
import struct
import sys
from pathlib import Path

import requests
import sqlite_vec

DB_PATH = os.environ.get("EMBED_DB", os.path.expanduser("~/ai/embeddings.sqlite3"))
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
EMBED_MODEL = os.environ.get("EMBED_MODEL", "nomic-embed-text")
EMBED_DIM = 768  # nomic-embed-text's output size; change if EMBED_MODEL changes

CHUNK_CHARS = 2000
CHUNK_OVERLAP = 200

# Extensions we know how to turn into text. Anything else is left un-embedded
# — it still gets a manifest entry from index-ingest.sh, just no chunks.
TEXT_EXTS = {".txt", ".md", ".markdown", ".csv", ".json", ".yaml", ".yml", ".log"}


def _connect() -> sqlite3.Connection:
    Path(DB_PATH).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS chunks (
            id INTEGER PRIMARY KEY,
            path TEXT NOT NULL,
            rel TEXT NOT NULL,
            sha256 TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            chunk_text TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
        """
    )
    conn.execute(
        f"""
        CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks USING vec0(
            embedding float[{EMBED_DIM}]
        )
        """
    )
    conn.execute("CREATE INDEX IF NOT EXISTS idx_chunks_path ON chunks(path)")
    conn.commit()
    return conn


def extract_text(path: str, mime: str) -> str | None:
    """Best-effort plain-text extraction. Returns None if we don't know how."""
    ext = Path(path).suffix.lower()

    if ext in TEXT_EXTS or mime.startswith("text/"):
        try:
            return Path(path).read_text(encoding="utf-8", errors="replace")
        except OSError:
            return None

    if ext == ".pdf" or mime == "application/pdf":
        try:
            from pypdf import PdfReader

            reader = PdfReader(path)
            return "\n\n".join(page.extract_text() or "" for page in reader.pages)
        except Exception:
            return None

    if ext == ".docx" or mime == "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
        try:
            import docx

            d = docx.Document(path)
            return "\n".join(p.text for p in d.paragraphs)
        except Exception:
            return None

    return None


def chunk_text(text: str, size: int = CHUNK_CHARS, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """Sliding-window character chunking on whitespace-collapsed text.

    Simple on purpose: no tokenizer dependency, good enough for nomic-embed-text's
    8192-token window, and chunk boundaries only need to be "reasonable," not exact.
    """
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    if not text:
        return []
    if len(text) <= size:
        return [text]

    chunks = []
    start = 0
    while start < len(text):
        end = min(start + size, len(text))
        chunks.append(text[start:end])
        if end == len(text):
            break
        start = end - overlap
    return chunks


def embed_texts(texts: list[str]) -> list[list[float]]:
    """Call Ollama's embed API. Batches in one request; raises on failure."""
    if not texts:
        return []
    resp = requests.post(
        f"{OLLAMA_URL}/api/embed",
        json={"model": EMBED_MODEL, "input": texts},
        timeout=120,
    )
    resp.raise_for_status()
    data = resp.json()
    return data["embeddings"]


def _pack(vec: list[float]) -> bytes:
    return struct.pack(f"{len(vec)}f", *vec)


def upsert_file(path: str, rel: str, sha256: str, mime: str) -> dict:
    """Extract, chunk, embed, and store one file. Returns a status dict.

    Re-embedding the same path replaces its old chunks first, so edits and
    re-drops don't accumulate stale duplicates in search results.
    """
    text = extract_text(path, mime)
    if text is None or not text.strip():
        return {"status": "skipped", "reason": "no extractable text", "chunks": 0}

    pieces = chunk_text(text)
    if not pieces:
        return {"status": "skipped", "reason": "empty after chunking", "chunks": 0}

    vectors = embed_texts(pieces)

    conn = _connect()
    try:
        old_ids = [r[0] for r in conn.execute("SELECT id FROM chunks WHERE path = ?", (path,))]
        if old_ids:
            conn.executemany("DELETE FROM vec_chunks WHERE rowid = ?", [(i,) for i in old_ids])
            conn.execute("DELETE FROM chunks WHERE path = ?", (path,))

        for idx, (piece, vec) in enumerate(zip(pieces, vectors)):
            cur = conn.execute(
                "INSERT INTO chunks (path, rel, sha256, chunk_index, chunk_text) "
                "VALUES (?, ?, ?, ?, ?)",
                (path, rel, sha256, idx, piece),
            )
            conn.execute(
                "INSERT INTO vec_chunks (rowid, embedding) VALUES (?, ?)",
                (cur.lastrowid, _pack(vec)),
            )
        conn.commit()
    finally:
        conn.close()

    return {"status": "embedded", "chunks": len(pieces)}


def delete_file(path: str) -> int:
    """Remove all chunks for a deleted/moved-away file. Returns rows removed."""
    conn = _connect()
    try:
        ids = [r[0] for r in conn.execute("SELECT id FROM chunks WHERE path = ?", (path,))]
        if ids:
            conn.executemany("DELETE FROM vec_chunks WHERE rowid = ?", [(i,) for i in ids])
            conn.execute("DELETE FROM chunks WHERE path = ?", (path,))
            conn.commit()
        return len(ids)
    finally:
        conn.close()


def search(query: str, top_k: int = 5) -> list[dict]:
    """Embed a query and return the top_k nearest chunks with source info."""
    vec = embed_texts([query])[0]
    conn = _connect()
    try:
        rows = conn.execute(
            """
            SELECT c.rel, c.chunk_index, c.chunk_text, c.path, v.distance
            FROM vec_chunks v
            JOIN chunks c ON c.id = v.rowid
            WHERE v.embedding MATCH ? AND k = ?
            ORDER BY v.distance
            """,
            (_pack(vec), top_k),
        ).fetchall()
    finally:
        conn.close()
    return [
        {"rel": r[0], "chunk_index": r[1], "text": r[2], "path": r[3], "distance": r[4]}
        for r in rows
    ]


if __name__ == "__main__":
    # `python3 embed_lib.py "some query"` — quick manual smoke test.
    if len(sys.argv) > 1:
        for hit in search(" ".join(sys.argv[1:])):
            print(json.dumps(hit, ensure_ascii=False))
