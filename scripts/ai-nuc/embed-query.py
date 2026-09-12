#!/usr/bin/env python3
"""
embed-query.py — semantic search over everything dropped into the ingest folder.

    ~/ai/venv/bin/python ~/ai/scripts/embed-query.py "eGPU oculink troubleshooting"
    ~/ai/venv/bin/python ~/ai/scripts/embed-query.py -k 8 "vendor pricing"
    ~/ai/venv/bin/python ~/ai/scripts/embed-query.py --json "..."   # machine-readable

Meant for both you and any NUC-side agent: point it at a question, get back
the most relevant chunks with their source file and a relevance distance
(lower = closer), then go read the actual file if a chunk looks right.
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import embed_lib  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("query", nargs="+", help="natural-language search text")
    ap.add_argument("-k", "--top-k", type=int, default=5, help="number of results (default 5)")
    ap.add_argument("--json", action="store_true", help="emit JSON lines instead of formatted text")
    args = ap.parse_args()

    query = " ".join(args.query)
    try:
        hits = embed_lib.search(query, top_k=args.top_k)
    except Exception as exc:  # noqa: BLE001 — top-level CLI boundary
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if not hits:
        print("(no results — nothing embedded yet, or nothing matched)", file=sys.stderr)
        return 0

    if args.json:
        for h in hits:
            print(json.dumps(h, ensure_ascii=False))
        return 0

    for i, h in enumerate(hits, 1):
        preview = h["text"][:280].replace("\n", " ")
        print(f"[{i}] {h['rel']}  (chunk {h['chunk_index']}, distance {h['distance']:.4f})")
        print(f"    {preview}{'...' if len(h['text']) > 280 else ''}")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
