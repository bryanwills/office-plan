# Capture and build spine (one inbox, many inputs)

**Date:** 2026-09-20  
**Status:** design, not a new stack. Finish NUC + netcup + Mac hygiene first.

You do not need Plaud to talk to Obsidian, or Notion to talk to Hermes. You need **every capture method to land in one inbox**. Automations fan out from there. Bidirectional sync between every tool is how you get three second brains and none of them trustworthy.

## The spine (keep it to these lanes)

| Lane | One owner | What it is |
|---|---|---|
| **Capture inbox** | One folder + one queue | Raw notes, voice dumps, jrnl lines, photos of whiteboards. Unprocessed. |
| **Human notes** | Obsidian (you already have `obsidian-bryans-journal`) | Readable pages after process. Not Notion *and* Obsidian *and* Open Brain. |
| **Agent memory** | Honcho via Hermes | Facts Hermes should recall. Not a dump of every note. |
| **Chat desk** | Open WebUI on the NUC | Local chat, Knowledge, Drive. |
| **Product channels** | Buzz | Outbound / agent teams. Still finishing setup. |
| **Build** | git + Cursor/Hermes | Repos, docs sites, MVPs. Multica later as the *one* coding board. |
| **Infra continuity** | `PROJECT_STATE.md` | What the machines are doing. Not idea capture. |

Freeze for now: Open Brain, LLM-wiki, a second Notion brain, a second memory injector. Open Brain stays a later netcup experiment, not a parallel production brain.

## Capture anywhere, same inbox

| Where you are | How you capture | Lands in |
|---|---|---|
| Home / Mac | Hermes, jrnl, Obsidian quick note | Inbox |
| Work terminal | jrnl one-liner or Hermes | Inbox (sync via git/Obsidian/iCloud *after* it is text) |
| Road / car | Plaud / other recorder | n8n (later) → inbox markdown. Not a second vault. |
| Phone | Voice or photo | Same inbox folder |
| Open WebUI | Chat you mark “keep” | Honcho (fact) or inbox (project idea) |

Plaud will **not** sync back into the recorder. That is correct. Recorder → transcript → inbox. Obsidian does not need to write to Plaud.

n8n (already on Little Creek, to migrate with the rest) is the pipe, not the brain.

## What “idea to reviewable project” looks like

1. **Capture** (any medium) → inbox item with a date and one sentence.
2. **Triage** (you, 10 minutes, not an agent swarm): keep / later / drop.
3. **One page** in Obsidian: problem, user, constraint (local vs cloud), “done when”.
4. **Scaffold** only after that page exists: git repo, docs stub, optional Buzz agent.
5. **Agents work in the repo** (Hermes / Cursor). Honcho remembers decisions. Open WebUI is not the project manager.
6. **Handoff to you** = PR or a folder with demo + docs. Not “the AI finished the company.”

That is the same HTN / approval-gated pattern already in [product architecture notes](../product-architecture-notes.md). The Surface rule still applies: do not surface every idea every day.

## Grok Bot (later, not this week)

Hermes can already use a Grok **subscription** via xAI OAuth ([Hermes Grok OAuth](https://hermes-agent.nousresearch.com/docs/guides/xai-grok-oauth), [xAI + Hermes](https://x.ai/news/grok-hermes)). That is a **model provider**, not a second gateway.

A “Grok Bot” bridge that makes Grok the front door and Hermes the worker is extra chrome ([GrokBot ↔ Hermes Bridge](https://glama.ai/mcp/servers/iamsupersocks/grokbot-hermes-bridge)). Do not add it until Hermes + Honcho + Buzz are boring. Local 27B stays the default for customer / address / Ring data.

## Finish order (do not start the whole vision)

1. Honcho JWT in Hermes (mint script on the NUC).
2. Mac hygiene **dry-run TSV**, then Time Machine finished, then one folder.
3. Remaining ai-nuc containers you already planned (no new product stacks).
4. Little Creek → netcup (n8n moves with that; Plaud pipe waits for n8n).
5. Finish Buzz onboarding.
6. Trading agent after the desk is stable.
7. Then: one inbox folder, jrnl, Obsidian, optional Plaud→n8n.

One capture inbox. One notes vault. One agent memory. One chat desk. One board later.
