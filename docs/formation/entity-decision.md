# Entity & Name Decision

## Status: Open

## The core question

Three things got bundled together that don't actually have to be decided at the same time:

1. The **legal name** on the Articles of Organization
2. The **public brand** (what customers/clients see)
3. The **domain(s)** tied to the brand

Kentucky makes it cheap to decouple these — a DBA ("Certificate of Assumed Name") is $20 state + ~$33–46 county, renewed every 5 years. That means the legal name doesn't have to be the final brand decision.

## Options considered

| Option | Legal name | Brand | Tradeoff |
|---|---|---|---|
| A — Own name | Personal name LLC | DBA "Big Brain Coding" (or other) added later | Lowest friction, zero rework if brand direction changes, defers the hard branding call |
| B — Big Brain Coding LLC directly | Big Brain Coding LLC | Same | Matches existing domain/VPS/dev identity already in use; commits now |
| C — Neuro-inclusion-themed name | New brand name | Same | Aligns with the `divergentpath` project already started; brand-new territory, not yet validated |

## Recommendation

**Option A** — form under a neutral/personal legal name now, DBA the brand whenever it's ready. Reasoning:

- The financial benefits of having an LLC (liability protection, business purchasing accounts, expense deductibility) come from being a legitimate registered business — **not from which name is on the paperwork.** Nothing else in this plan is blocked by delaying the brand decision.
- Big Brain Coding already has real equity (`bigbraincoding.com`, existing VPS/Docker stack, existing dev identity) — it can be DBA'd in immediately if desired, or later.
- If the neuro-inclusion direction becomes a real product line, it can launch as a second DBA under the same LLC without touching the entity, EIN, or bank account.
- Multiple DBAs can run under one LLC simultaneously.

## Decision log

| Date | Decision | Notes |
|---|---|---|
| _TBD_ | _TBD_ | |
