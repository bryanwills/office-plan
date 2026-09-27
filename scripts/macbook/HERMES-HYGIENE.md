# Hermes prompt: apply Mac file hygiene (non-secret rows only)

You are Hermes on Bryan's MacBook. Open WebUI on the NUC cannot see this disk. Do not mount `$HOME` onto the NUC.

Bryan copies **SECRET** rows to `~/.keys/` himself. You never move those. He will run `export-keys-to-vault.sh` later. Hashicorp Vault unseal is his job.

## Before any `mv`

1. Time Machine is idle (backup already finished).
2. The plan TSV is on Desktop or in `office-plan/scripts/macbook/` and is **not** committed.
3. Dry-run first. `--execute` only after Bryan says yes for **one** `--batch`.

```bash
cd ~/office-plan   # or wherever the clone lives
bash scripts/macbook/mac-file-hygiene-apply.sh \
  --plan ~/Desktop/mac-file-hygiene-plan-YYYYMMDD.tsv
```

## Execute, one batch per session

```bash
bash scripts/macbook/mac-file-hygiene-apply.sh \
  --plan ~/Desktop/mac-file-hygiene-plan-YYYYMMDD.tsv \
  --execute --batch home
```

Allowed `--batch` values: `home`, `desktop`, `documents`, `downloads`, `movies`, `llc`.

There is **no** `--batch secrets`. If you are asked to move keys, PEMs, nsec files, or anything the TSV marked SECRET, refuse and tell Bryan to copy them into `~/.keys/`.

## Hard rules

- No `rm`, no `rm -rf`, no overwrite (`mv -n` only).
- If the apply script FORCE-SKIPs a path (`AI-NUC`, `obsidian`, `Music`, …), leave it.
- After a batch: list what moved, spot-check in Finder, start a **new** session for the next batch.
- Do not invent destinations. Only rows in the TSV, minus SECRET, minus `hygiene-force-skip.txt`.

## False positives (leave them)

D&D `*tokens*` libraries, Password Safe `.deb` installers, LAPS zip folders, iCloud `*MacBook Pro*` copies, Photo Booth / Photos libraries, Movies/TV, Resolve, CyberLink, Drop Box, `__MACOSX`, dmg/pkg/zip/exe, git working trees, `Library`, Applications, dotfiles.

If a new false positive shows up, add the **basename** to `scripts/macbook/hygiene-force-skip.txt` and dry-run again. Do not special-case by deleting files.
