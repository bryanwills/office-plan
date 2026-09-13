# Tokens, context, and picking a model on this GPU

**Status:** living guide for this machine (ai-nuc, RTX 3090 Ti 24 GB)  
**Audience:** you, and anyone neurodivergent who got dumped into "262k context" talk and felt stupid. You are not. The words are overloaded.

This page is the practical version. Numbers below are for **this** 3090 Ti, not a datacenter.

---

## The one-sentence version

A **token** is a bite-sized piece of text. The **context window** is how many of those bites the model can hold in its head **for the chat that is loaded right now**. It is not how many chats you can save, and it is not a bank account of 300,000 tokens you spend down over a week.

---

## Three things people mix up

| Word people say | What they actually mean | Like | Lives where |
|---|---|---|---|
| **Tokens** | Chunks of text the model reads and writes | Lego bricks of language | In the request, then gone |
| **Context window** | How many tokens fit in **this** loaded chat at once | The size of the desk you are working on | GPU memory (VRAM), this second |
| **Saved chats / memory** | Old conversations, notes, Honcho observations | Filing cabinets | Disk (this new 1 TB drive, or OpenWebUI/Honcho) |

You can have **dozens of saved chats**. Only the one you are talking to uses the desk. Filling two Hermes windows does not "use up" 128,000 tokens of lifetime quota. Those chats sit on disk. When you open one, Ollama loads **that** transcript into the window. If that transcript is bigger than the live window, the oldest part falls off the desk. That is when Hermes starts 500-ing with `no user query found in messages`.

---

## What a token actually is

Models do not think in words. They think in **tokens**.

- English is roughly **100 tokens ≈ 75 words**, or about **1 token ≈ 4 characters**.
- `Hello` is 1 token. A long URL can be 20. Code is denser than email.
- A typical page of prose is about 500 to 800 tokens.
- A Hermes turn with tools (system prompt + tool schemas + a file listing + the model's reply) is often **6,000 to 36,000 tokens** before you typed anything interesting.

So "300,000 tokens" is not 300,000 words. It is closer to **200,000 to 225,000 words** of working memory **if** the model could actually open a window that big on your hardware. On this card, it cannot. See below.

---

## What your coworker meant by "300,000 tokens"

He did the **brochure math**, not the **desk math**.

`qwen3.8:27b` **advertises** a max context of **262,144 tokens** (about 262k). People round that to "300k". That number is:

- the model's **architectural maximum** (what the paper says it *can* attend over)
- **not** what Ollama loads by default (default live window is often **4,096**)
- **not** what fits in 24 GB of VRAM next to a 17 GB model

Two different numbers, same conversation, which is why this feels like a trick.

```
Advertised max   262,144 tokens   <- what he quoted
Hermes we set     65,536 tokens   <- what the alias asks for
Ollama default     4,096 tokens   <- what you get if you forget to set it
What actually fits on 24 GB
  with 27B Q4 + KV cache     ~16k to 64k, depending on KV quant
```

**Performance vs everyone else:** people on Claude / ChatGPT are using a rented building. You own a large workshop. Your workshop is private, has no monthly token bill, and is fast enough for real agent work (~50 tokens/sec on `qwen3.8:27b`). Their building has a bigger desk (200k+ context) and a receptionist who never drops the first page of the file. Your job is to pick a desk size that fits the room, not to pretend the room is a warehouse.

That is not worse. It is a different constraint. Local + private is the point of this build.

---

## Why a bigger window is slower and can 500

Every token in the window has to stay in **VRAM** as a "KV cache" (a scratchpad of everything already said).

Rough picture for **this** 27B Q4 model on the 3090 Ti (24 GB):

| Live window | Weights | Scratchpad (KV cache) | Fits? | Feels like |
|---|---|---|---|---|
| 4k (Ollama default) | ~17 GB | small | Yes, easy | Forgets the start of a long tool loop. Hermes 500s. |
| 16k | ~17 GB | medium | Yes | Good for short automations |
| 32k | ~17 GB | large | Tight | Good daily Hermes if chats stay trimmed |
| 64k (current `-hermes` alias) | ~17 GB | very large | Only with quantized KV, or it spills to RAM | Fine until the chat gets long, then slow or 500 |
| 262k (advertised) | ~17 GB | enormous | **No** | OOM, CPU offload, or truncated transcript |

So: raising context does **not** give you more saved chats. It makes **one** chat able to remember more of itself, at the cost of VRAM. When VRAM fills, Ollama either slows (CPU spill) or truncates. Truncation is what deletes the original user line and produces `no user query found`.

**What to do when a Hermes chat "fills up":** do not keep appending. Start a **new session**. Honcho (once running) is what should remember the important bits across sessions. The old chat can stay in the list. It is an archive, not a live desk.

You do not need to delete chats to "free tokens." You need a **new session** so the desk is empty again.

---

## What uses the desk (and what does not)

**Uses the 24 GB desk right now**

- The model weights currently loaded (`ollama ps`)
- The KV cache for the **active** request
- A second model, if you load two at once (usually a bad idea on 24 GB)

**Does not use the desk**

- OpenWebUI chat history on disk
- Hermes session files on the Mac (`~/.hermes/`)
- Honcho config on the Mac (`~/.config/.honcho/config.json`, Hermes finds it via `~/.honcho`)
- Honcho Postgres (observations, peer cards)
- The 1 TB `ai-data` drive
- How many chat tabs you have sitting idle

This is why "I had two chats and then it broke" feels like a quota, and is not one. Each of those chats, **when you send the next message**, tries to put its whole transcript on the desk. Two long transcripts are two separate attempts, each able to overflow 64k on its own.

---

## Picking a model for the job (this box, today)

Rule of thumb: **smallest model that is reliable at the job**. Save the 27B for the jobs that need it. The Deriver (Honcho, every message) should never steal the 27B or Hermes will hitch.

| What you are doing | Use this | Why | Live context to set |
|---|---|---|---|
| Hermes tools on the Mac (email, files, "do the thing") | `qwen3.8:27b-hermes` | Same weights as 27b, but `RENDERER qwen3.5` so tool loops do not 500 | 64000 in Hermes, `num_ctx 65536` on the alias |
| Everyday OpenWebUI chat / explain / draft | `qwen3.8:27b` or `qwen3.5:27b` | Stock renderer is fine when there is a normal user message | 8k to 16k is plenty |
| Fast drafts, classify, "rewrite this paragraph" | `qwen3.5:9b` or `ministral-3:8b` | 6 GB. Leaves the GPU free. Good enough for short text. | 8k |
| Honcho memory workers (every message) | `qwen3.5:9b` or `ministral-3:8b` | Must stay small or it evicts Hermes from VRAM | 8k to 16k |
| Embed / search your files | `nomic-embed-text` | Not a chat model. Turns text into vectors. Already on this box. | n/a |
| Trading signal sketch | `qwen3.8:27b` (advisory only) | Needs the stronger model. Still not allowed to place orders. | 8k to 16k |
| 35B MoE GGUFs already pulled | Only when **nothing else** is loaded | ~22 GB. Almost the whole card. Will kick Hermes out. | 8k unless you measure |
| `llama3.1:70b` or any ~40 GB Q4 | **Do not pull** | Will not fit. CPU offload will feel broken. | — |

If a new HuggingFace GGUF lands, do this before trusting it in Hermes:

```bash
ollama show MODEL --modelfile | grep -E '^(RENDERER|PARAMETER num_ctx)'
```

If you see `RENDERER qwen3.8`, make a `-hermes` alias first. Details: [Hermes + Ollama HTTP 500](hermes-ollama-500-fix.md).

---

## A workflow you can copy without thinking

1. **Agent work (Hermes):** `qwen3.8:27b-hermes`, context 64000, **new session** when it gets weird. Do not keep one immortal chat.
2. **Write code in Cursor:** Cursor can stay on a hosted model, or point at `http://100.73.71.29:11434/v1` + `qwen3.8:27b` for local. Local is slower at huge repos; that is the desk again.
3. **Automations that run in the background:** `qwen3.5:9b` or `ministral-3:8b` so they do not evict the agent model.
4. **Long-term memory:** disk (Honcho + OpenWebUI), not a 262k context window. The window is working memory. The drive is long-term memory.
5. **PDFs, connectors, MCP:** those are **tools** around the model. They do not need a bigger window. They need the tool to exist (Gotenberg, Tika, MCP). Separate job.

---

## What "local AI for a few users" actually costs you

For a handful of people (you, maybe a tester):

- **Compute** is this GPU. One heavy 27B chat at a time is the honest limit.
- **Storage** is the new 1 TB `ai-data` disk: chats, Honcho Postgres, OpenWebUI uploads, later app data.
- **Privacy** is the win. Weights and chat text stay on the NUC (embeddings can be local via `nomic-embed-text`).
- **You are not behind** someone with a 200k Claude window. You are ahead on cost, privacy, and "it works when the internet is rude." You are behind on "paste an entire book into one chat and keep going." That is a product choice, not a personal failing.

When you explain this in ND / awareness content, the honest line is:

> The marketed context number is the size of the novel the model *could* read. The number that matters is the size of the chapter that fits on your GPU next to the model. We plan for the chapter, and we file the rest on disk.

---

## Related

- [Hermes 500 / renderer / truncation](hermes-ollama-500-fix.md)
- [Honcho on ai-nuc](honcho-ai-nuc-setup.md)
- [AI-NUC stacks](stacks/ai-nuc-stacks-setup.md)
