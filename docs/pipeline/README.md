# Idea Pipeline — from shower thought to shipped product

This is the intake-to-ship pipeline that turns a rough idea into a complete,
working product with minimal human driving. It is the "do this the same way
every time" backbone for the whole LLC.

## The flow

```
    YOU                          VP OF PMs (Buzz)                     BUILD TEAM
  ┌─────────┐   1. send brief   ┌─────────────────┐   2. delegate   ┌──────────────┐
  │  Idea   │ ────────────────▶ │  Intake / Triage │ ──────────────▶ │ Fizz/Honey/  │
  │ + brief │ ◀──────────────── │  Scope / Proposal │ ◀───────────── │ Pollen / ... │
  └─────────┘  3. review        └─────────────────┘  4. status      └──────────────┘
                     │  GO / NO-GO / AUTO
                     ▼
                 5. BUILD (autonomous, gated)   →   6. SHIP (Definition of Done)
                     └─────── 7. Completion report w/ evidence + links
```

**Step 1 — You send a brief.** One message, one channel (`idea-forge`). Use the
[Idea Brief Template](idea-brief-template.md). The brief can be as rough as a
shower thought or as complete as a spec. Include the `auto-mvp` flag if you want
it to skip straight to build (see below).

**Step 2 — VP of PMs opens a project.** It turns the brief into a
`PROJECT-PROPOSAL`: scope, work breakdown, timeline, risks, open questions,
success criteria, and the Definition of Done it will be held to. It does **not**
start building yet.

**Step 3 — You review.** Two paths, chosen by the brief:

| Brief flag | What happens | When to use |
|---|---|---|
| `auto-mvp: false` (default) | VP scopes with you via questions until you reply **GO** | Fuzzy idea, real decisions, money/scope unknowns |
| `auto-mvp: true` | If the brief already has enough info, VP proceeds to MVP **without** waiting | The idea is fully specified and you're done talking |

The GO gate is a standing guardrail, not a suggestion. **Nothing with real-world
side effects (trading, payments, third-party accounts, public publishing,
destructive infra) goes forward without an explicit owner GO in-channel.**

**Step 4 — Autonomous build.** Once GO is in (or `auto-mvp` is set and the brief
is complete), the VP schedules the work, hands tasks to the build team
(Fizz / Honey / Pollen and any other agents), owns the timeline, checks status,
and unblocks. You get periodic "milestone" check-ins, not task chatter — ping
only when a decision is needed or at milestone boundaries.

**Step 5 — Ship to the Definition of Done.** The ship bar is non-negotiable and
lives in [Definition of Done](definition-of-done.md): working repo, functioning
MVP, docs site, blog if warranted, walkthrough, unit + integration + UI tests
passing, QA, timeline evidence, product research if any, wiki, documentation
written as it goes (the way `office-plan` is being documented), a benchmark
baseline, and stateless-compute-friendly code.

**Step 6 — Completion report.** A single channel message with: repo link, docs
link, blog link (if any), test results (with the actual exit codes / summaries),
benchmark baseline, what's known-broken, and the next-3-recommendations.

## The VP of PMs

The agent that runs this pipeline lives on the Buzz relay in the `idea-forge`
channel. Its canonical identity (system prompt) is version-controlled in
[vp-of-pms-identity.md](vp-of-pms-identity.md) so that the *source of truth*
for the agent lives here in git, and the running agent is a projection of it.
If you change the identity file, re-push the draft.

## Why it is shaped this way

- **Approval-gate is structural, not aspirational.** Buzz's `agents draft-create`
  does not create anything until the owner saves the draft in the Desktop app.
  The same discipline is written into the VP's system prompt for the build step,
  so "no silent autonomous action" is the default state, not a rule to remember.
- **The repo is the memory.** Every brief, every proposal, every completion
  report is a file in this repo (or a Buzz channel message that can be lifted
  back here). If an agent dies, a relay is rebuilt, or a project loses context
  mid-build, the next agent picks up from the files, not from a lost chat.
- **The definition of done is a checklist, not a vibe.** The VP is told to
  check off the [Definition of Done](definition-of-done.md) before it posts a
  completion report. If a box is unchecked, the report says so explicitly —
  "shipped with known gap: X, plan: Y" — rather than silently claiming done.

## Live channel

- **Where ideas go:** the `idea-forge` channel on the Buzz relay (private).
- **Who the VP is:** the agent named in `idea-forge` (identity in
  [vp-of-pms-identity.md](vp-of-pms-identity.md)).
- **First live brief:** [ideas/creator-provenance-key.md](ideas/creator-provenance-key.md)
  — captured 2026-09-12. The first thing the pipeline ever runs against, so we
  have a real artifact to grade it by.

## Loose ends / follow-ups

- Relay choice is currently *hosted* (`bryanwills.communities.buzz.xyz`) —
  the key works and the build team (Fizz/Honey/Pollen) is already there.
  Migrating the pipeline onto the self-hosted relay `buzz.bryanwills.dev`
  is a later hardening step; it needs the self-hosted owner key first.
- The build team (Fizz/Honey/Pollen) currently runs on the managed (Claude
  backed) runtime. Re-pointing the pipeline at the local NUC Ollama for
  privacy-only stages is on the list; not required for the pipeline to work.
