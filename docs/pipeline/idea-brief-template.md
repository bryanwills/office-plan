# Idea Brief Template

Copy this, fill it in, send it to the `idea-forge` channel (or drop it at
`docs/pipeline/ideas/<slug>.md`). The VP of PMs will respond with a
`PROJECT-PROPOSAL`. The flags at the top tell it how to behave.

```yaml yaml
---
id: <slug, kebab-case>                       # e.g. creator-provenance-key
title: <one-line name>
auto-mvp: false                              # true = skip the GO gate if brief is complete
owner: bryanwills
priority: P0 | P1 | P2                       # P0 = this week, P1 = this month, P2 = backlog
deadline: null                               # ISO date, optional
linked-briefs: []                            # slugs of related ideas
---
```

## What problem does it solve?

*In 2–6 sentences. What is broken, expensive, risky, or missing today — and
for whom. This is the "why now" sentence the VP will use to scope the work.*

## What should the finished thing do?

*The user-facing behavior, in plain language, ideally as a short numbered list
of "when X, the thing does Y." This becomes the MVP acceptance criteria.*

## Inputs / Outputs

- **Inputs:** *(files, APIs, hardware, other projects, data sources)*
- **Outputs:** *(a repo, a site, a CLI, a service, a physical spec, a report)*

## Known constraints

- **Local inference:** *(yes/no — and which models; note any GPU or VRAM cap)*
- **Approvals required for:** *(trading, payments, third-party accounts, any
    other real-world side effects)*
- **Secrets / credentials:** *(where they live; they must stay in server-side
    `.env`, never in the repo)*
- **Hardware / OS targets:** *(macOS + NUC? iPhone? Raspberry Pi? specific card?)*

## Success criteria (Definition of Done for THIS project)

*Override or add to the base [Definition of Done](../definition-of-done.md).*
At minimum: working repo + functioning MVP + tests passing + docs + walkthrough.

## Timeline shape

- **Rough estimate:** *(e.g. "a few days of agent time," "a few weeks")*
- **Must-haves for MVP:** *(the smallest shippable subset)*
- **Nice-to-haves (v2):** *(explicitly out of scope for MVP)*

## Open questions (VP should ask, in order)

*List the decisions you haven't made. The VP will walk through these before
the GO gate. If you've already answered some, note the answers inline.*

## Notes / prior research

*Links, prior attempts, references, hardware in hand, relevant `office-plan`
docs, anything the VP should read before proposing scope.*

---

## Flag reference

| Flag | Values | Meaning |
|---|---|---|
| `auto-mvp` | `true` / `false` | `true` = if the brief is complete enough, VP proceeds to build without waiting for GO. `false` (default) = VP scopes with you and waits for an explicit **GO**. |
| `priority` | `P0` / `P1` / `P2` | Sequencing hint for the VP when multiple briefs are in flight. |
| `deadline` | ISO date | Hard date if any; VP will flag if the proposal can't hit it. |
