#!/usr/bin/env python3
"""
embed-file.py — embed or delete one file's chunks in the ingest vector store.

Called from index-ingest.sh's EMBED HOOK, one file per invocation:

    embed-file.py upsert <path> <rel> <sha256> <mime>
    embed-file.py delete <path>

Prints one JSON line to stdout describing what happened, and exits non-zero
on failure (e.g. Ollama unreachable) so the caller's log shows a real error
instead of a silently-empty result.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import embed_lib  # noqa: E402


def main() -> int:
    if len(sys.argv) < 2:
        print(json.dumps({"status": "error", "reason": "usage: embed-file.py upsert|delete ..."}))
        return 2

    action = sys.argv[1]
    try:
        if action == "upsert":
            _, path, rel, sha256, mime = sys.argv[1:6]
            result = embed_lib.upsert_file(path, rel, sha256, mime)
        elif action == "delete":
            path = sys.argv[2]
            removed = embed_lib.delete_file(path)
            result = {"status": "deleted", "chunks_removed": removed}
        else:
            result = {"status": "error", "reason": f"unknown action '{action}'"}
            print(json.dumps(result))
            return 2
    except Exception as exc:  # noqa: BLE001 — this is the top-level CLI boundary
        print(json.dumps({"status": "error", "reason": str(exc)}))
        return 1

    print(json.dumps(result, ensure_ascii=False))
    return 0 if result.get("status") != "error" else 1


if __name__ == "__main__":
    sys.exit(main())
