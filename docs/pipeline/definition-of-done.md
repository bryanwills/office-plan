# Definition of Done (base)

The base bar for anything the pipeline ships. A project brief may **add to**
this list but may not remove items. When the VP of PMs posts a completion
report, it must check each of these boxes and report any unchecked ones
explicitly as "known gap."

## Repo

- [ ] **Working repository**, publicly or private, with a clear `README.md`
      that a stranger can follow to run it.
- [ ] **Git history** is meaningful (commits map to features/fixes), not a
      single "initial commit."
- [ ] **Branch protection** on `main` (at minimum: require review, no
      force-push, no delete).
- [ ] **License** declared, or an explicit "all rights reserved" note.

## MVP

- [ ] **The MVP works end-to-end** for the primary user story, demonstrated
      with a reproducible command, URL, or script.
- [ ] **No fatal errors** on the primary path. Warnings are acceptable,
      documented.
- [ ] **A smoke test** exists (one command) that exits non-zero if the primary
      path is broken, and it is wired into CI or a `make check` target.

## Tests

- [ ] **Unit tests** cover the core logic (the functions the MVP depends on).
- [ ] **Integration tests** cover cross-boundary behavior (APIs, DB, CLI, UI).
- [ ] **UI tests** (if there is a UI) cover the primary user flow.
- [ ] Tests are **deterministic** (no flaky time, random, or network
      dependency without a fixture), and can be run with a single command.
- [ ] **Test results are captured** — actual exit codes / pass counts — and
      attached to the completion report.

## Documentation

- [ ] **Docs site** up (MkDocs or equivalent) with at minimum: quickstart,
      CLI/API reference, concept doc, troubleshooting.
- [ ] **Blog post or changelog** entry (if warranted) describing what shipped.
- [ ] **Walkthrough steps** — a step-by-step "here's how you'd actually use
      this" doc, written for the target user.
- [ ] **Wiki / in-progress notes** as relevant (mirrors the `office-plan`
      documentation style — the doc grows with the code, not after).
- [ ] **Product research** attached if the brief required it (market, prior
      art, failure modes).

## QA & Benchmarks

- [ ] **QA pass** — a human or an agent (with owner on the record) has
      exercised the primary path and reported it.
- [ ] **Benchmark baseline** captured (perf + correctness) so future changes
      can be diffed against it. If the project has no measurable perf axis,
      the report says so.
- [ ] **Stateless-compute-friendly** — the code does not assume a warm cache,
      a specific machine identity, or a specific relay/node; it can be run on
      a fresh stateless box.

## Operational

- [ ] **Secrets** live in a server-side `.env` (or equivalent). Nothing
      secret is committed. The repo's `.gitignore` and a pre-commit or CI
      secret scan (e.g. `gitleaks`) are in place.
- [ ] **No orphan state** — any infra the MVP depends on is either in the
      repo as infra-as-code OR documented with a one-paragraph setup note.
- [ ] **Rollback path** is known — if the MVP has to be taken off, the steps
      are written somewhere.

## Completion report (the artifact that closes the project)

One message (or one `COMPLETION.md` in the repo) containing:

- Repo URL, docs URL, blog URL (if any).
- Test output (exit codes, pass/fail counts) — the real thing, not "tests pass."
- Benchmark baseline numbers.
- Known gaps (anything unchecked above) with a one-line plan for each.
- Next 3 recommendations, in priority order.
- Time-to-done and cost (agent hours, model calls, infra spend) — honest
  numbers, no rounding.
