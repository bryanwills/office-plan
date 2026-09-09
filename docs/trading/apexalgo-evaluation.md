# ApexAlgo Evaluation & Trading Bot Architecture Plan

**Date:** 2026-09-07
**Source studied:** [`github.com/Stenvro/ApexAlgo`](https://github.com/Stenvro/ApexAlgo) — full repo cloned and indexed (backend + frontend + docs), not just the README.

**Why this doc exists:** Bryan found ApexAlgo on Reddit as a more polished, self-hosted alternative to the original Humbled Trader blog-post inspiration for the day-trading-bot project (see `PROJECT-CONTEXT.md` → `day-trading-bot`). This doc records what ApexAlgo actually is, how it compares to the IBKR/Alpaca plan already in progress, and a concrete plan to take the good architectural ideas without inheriting ApexAlgo's asset-class and licensing limitations.

---

## 1. What ApexAlgo actually is

A self-hosted, no-code **crypto** algorithmic trading platform:

- **Backend:** FastAPI + SQLAlchemy + SQLite (WAL mode), async event-driven bot engine (`asyncio`), ~4,800 lines of Python across `engine/`, `core/`, `models/`, `routers/`.
- **Frontend:** React + ReactFlow visual node editor, TradingView `lightweight-charts`, Vite build, served by nginx behind a same-origin `/api` proxy.
- **Strategy model:** Strategies are a **node graph** — Indicator → Condition → Logic Gate → Action(BUY/SELL) → Risk (TP/SL) — serialized to JSON (`.apex.json`) and evaluated **per closed candle**, purely on numeric technical-indicator values (51+ indicators via `pandas_ta`). There is no LLM, no news/sentiment input, no discretionary layer anywhere in the engine — "advanced" here means engine performance/robustness (WAL mode, indicator fingerprinting/memoization, drawdown caching, incremental backfill, event bus), not AI-driven decision-making.
- **Market data & execution:** 100% via **CCXT**, REST-polled per `(exchange, symbol, timeframe)`. Three modes: forward-test (local sim, no key), paper (exchange sandbox), live (real orders). Supported exchanges: **OKX, Binance, Bitvavo, Coinbase, Crypto.com, Kraken, KuCoin** — all crypto, none are US equities/options brokers.
- **Security model worth copying regardless of broker:** Fernet-encrypted credentials at rest, `X-API-Key` header with timing-safe comparison + per-IP rate limiting on failed attempts, ports bound to `127.0.0.1` by default (LAN access is opt-in), non-root container, mandatory `max_order_value` cap before any live bot can start, mandatory max-drawdown auto-stop evaluated after every closed position.
- **Deployment:** two Docker containers (backend, frontend/nginx), or bare-metal via `screen` sessions using setup scripts under `install/`. Everything lives under a single `data/` folder (SQLite DB, `.env`, TLS certs) — trivially portable, which matters for your "transport the NUC between home and work" plan.
- **License:** README states explicitly — **"This project does not currently have an open-source license. All rights reserved."** No `LICENSE` file in the repo. That means: no forking-and-relabeling as your own hosted product, no redistributing its code in a public repo (yours is public), no building your "nicer hosted dashboard" out of its actual source without asking the author first. Treat it as **reference architecture to study, not a codebase to inherit.**

## 2. Comparison table

| | ApexAlgo | Humbled Trader / your original plan | Your actual accounts |
|---|---|---|---|
| Asset class | Crypto spot | Equities/options via IBKR, TradingView MCP | Equities/options |
| Broker/exchange | CCXT (7 crypto exchanges) | Interactive Brokers (TWS API), Alpaca | Alpaca + IBKR (both open) |
| Decision model | Deterministic node-graph on technical indicators only | Claude/LLM via MCP calling IBKR + TradingView tools directly (conversational/agentic control) | Your stated design: multi-factor — quant signals **+ news + geopolitics + Polymarket/Kalshi sentiment** |
| Backtesting | Built-in, vectorized, shared-capital-pool, fee/slippage-adjusted | Not part of the MCP approach itself | Required — your hard rule is 30-45 days paper before real money |
| Dashboard | Yes — bot manager, live console, chart overlays, analytics (equity curve, win rate, drawdown, buy&hold) | None described in the blog post | You want this — "nicer to have hosted for people to see live progress" |
| Risk controls | Tiered TP/SL, trailing/ATR stops, cooldown, position limits, max-drawdown auto-stop, max-order-value cap | Manual / LLM-judgment based | You want hard, non-LLM safety rails regardless of what decides entries |
| License | None (all rights reserved) | N/A (blog post, not a repo) | — |

**The gap ApexAlgo doesn't fill and Humbled Trader's approach doesn't fill either:** your stated multi-factor signal layer (news, geopolitics, prediction-market sentiment). ApexAlgo's node graph can only compare numbers derived from OHLCV candles. Humbled Trader's MCP approach puts the LLM in the execution loop directly, which conflicts with your own hard rule ("paper only, human approval gate, no auto-execution until validated" — PROJECT_STATE.md §3) — you don't want an LLM with tool-call access to a live brokerage account making the entry/exit decision itself.

## 3. Recommended architecture: ApexAlgo's chassis, your broker, your signal layer

Don't fork ApexAlgo. Build a new repo, clean-room, borrowing the architecture patterns that are genuinely good and swapping out the two things that don't fit (broker layer, decision model):

```
apex-derivative/  (working name — actual repo name TBD)
├── backend/
│   ├── engine/            # same shape as ApexAlgo: bot_manager, evaluator, candle_poller
│   │   └── broker_registry.py   # replaces exchange_registry.py — see §3a
│   ├── signals/           # NEW — not in ApexAlgo at all, see §3b
│   │   ├── news_ingest.py
│   │   ├── sentiment_score.py   # Polymarket/Kalshi + news → normalized per-symbol score
│   │   └── llm_client.py        # calls Qwen3.8:27B on the eGPU rig over local network, read-only
│   ├── core/              # Fernet encryption, event bus, WAL SQLite — copy the pattern, not the code
│   └── routers/
├── frontend/              # React + ReactFlow builder, same UX pattern as ApexAlgo
└── docker-compose.yml     # same two-service (backend/frontend) shape
```

### 3a. Broker adapter layer (replaces CCXT)

CCXT cannot be reused for IBKR or Alpaca — it's crypto-exchange-only by design. Two adapters, one interface (`fetch_ohlcv`, `place_order`, `fetch_order`, `fetch_balance`, `fetch_positions` — same method shape ApexAlgo's `exchange_registry.py` already establishes, which is why the pattern is worth keeping):

- **Alpaca adapter** — `alpaca-py` SDK. REST + WebSocket, has **built-in paper trading** (a real sandbox account, not a simulated one), supports equities, options, and crypto under one API. This is the easiest of the two and should be built first.
- **IBKR adapter** — `ib_async` (maintained fork of `ib_insync`) talking to IB Gateway or TWS over its socket API. **Important architectural wrinkle vs. your stateless-compute principle:** IB Gateway/TWS must stay logged in and running as a persistent, stateful process (session tokens, 2FA re-auth every ~24h) — it is not a stateless REST call you can poll from anywhere. This needs to run as a long-lived service (on the netcup VPS or the MS-01/NUC), with the bot backend connecting to it over the local network, not embedded per-request. Flag this explicitly as an open decision: where does IB Gateway live, and how does it survive the NUC traveling between home and work.

Both adapters implement forward-test / paper / live exactly like ApexAlgo's three modes — that three-way split is a good idea worth copying directly regardless of broker.

### 3b. Signal service (the part neither reference project has)

A separate process, not inside the per-candle evaluator loop (keeps the deterministic engine deterministic and testable):

1. Runs on a schedule (e.g. every 15-60 min, not per-candle) on the MS-01 + 3090 Ti, using Qwen3.8:27B via Ollama.
2. Ingests: news headlines/wire feeds, Polymarket/Kalshi market prices for relevant contracts, macro calendar.
3. Emits a normalized score per symbol (e.g. -1.0 to +1.0) into the same SQLite DB as a new table (`external_signals`), timestamped.
4. Exposed to the node-graph evaluator as a **new node type** — `external_signal` — that behaves like a Price Data node (feeds into a Condition node, e.g. `sentiment_score > 0.3`). This keeps the LLM strictly advisory/data-producing, never decision-making or order-placing, which matches both your explicit hard rule and ApexAlgo's condition→action wiring model.
5. Every score the LLM produces gets logged with its reasoning text (not just the number) so the "why did it enter" question is always answerable from the DB — same spirit as ApexAlgo's per-bot log console, applied to the signal layer too.

### 3c. Dashboard hosting (the "nicer to have hosted for people to see" part)

Two different concerns, keep them separated:

- **The live trading engine + real broker credentials** stay on hardware you control end-to-end — the MS-01/eGPU rig at home, or a private-network-only service. Never expose `MASTER_API_KEY`-equivalent auth or a path to real order placement on a public endpoint.
- **The public-facing dashboard** (what visitors/your ND-community contacts/AI:NOW-style audience would see) is a **read-only view**: charts, equity curve, win/loss stats, bot console history — no trade controls, no credential entry, no start/stop buttons. Host that on the netcup VPS behind Traefik (matches your existing file-provider Traefik pattern from the other stacks — see `docs/infrastructure/stacks/`), as `trading.bryanwills.dev` or similar, fed by a one-way sync (the local engine pushes read-only snapshots/DB replicas to the VPS, the VPS never has write access back to the engine or the broker keys). This satisfies "hosted for people to see live progress" without turning a public URL into an attack surface against your brokerage account.

## 4. What to keep from ApexAlgo almost verbatim (as patterns, reimplemented)

- WAL-mode SQLite + incremental-commit backfill (avoids the startup race conditions they specifically solved)
- Event bus (`asyncio.Queue`, bounded, drop-oldest) for CANDLE_CLOSED / BOT_STATE_CHANGED style events
- Per-bot persisted log buffer table, polled by the frontend every 2s while a console panel is open — cheap and simple, no websockets needed
- Indicator fingerprinting/memoization per evaluation cycle (`resolve_node()` caching) — directly reusable regardless of broker, since it's about the node-graph evaluator, not the exchange
- Backtest capital-pool model (shared pool across whitelist symbols, dynamic position sizing from running equity, capital-depletion guard)
- Risk node set: tiered TP/SL, trailing %, ATR-multiplier trailing, max-drawdown auto-stop (peak-to-trough on mark-to-market equity), mandatory max-order-value cap before any live bot starts
- `.apex.json`-style export/import for strategies, and a `STRATEGY_CONTEXT.md`-style file so any AI assistant (including a local Qwen3.8:27B session) can generate an importable strategy JSON without inventing invalid node types — worth writing your own equivalent doc once the node schema is defined for the equities version

## 5. Phased build plan (tied to current hardware timeline)

1. **Now — before MS-01 arrives:** design doc only (this file) + decide the actual repo name and whether it lives standalone or as a module the freqtrade fork gets retired in favor of. **Recommendation: retire the freqtrade fork** — it has the identical crypto-only mismatch against your accounts as ApexAlgo does, so keeping it around as "the trading bot repo" is misleading.
2. **MS-01 + eGPU first power-on (today/this week):** stand up Ollama + Qwen3.8:27B on the new box first (this was already priority #1 in `PROJECT_STATE.md` §6 for OpenJarvis/Hermes reasons too — the signal service in §3b reuses that exact same model/serving setup, no separate GPU work needed).
3. **Backend skeleton:** FastAPI app + SQLAlchemy models (Bot, Position, Order, Signal, Candle, BrokerKey) copying ApexAlgo's schema shapes, `broker_registry.py` with the Alpaca adapter only (paper mode) to start — get a full forward-test → paper-trade loop working end-to-end on one symbol before adding IBKR.
4. **Node-graph evaluator + minimal builder UI** — can literally start by importing one of ApexAlgo's three example strategies conceptually (RSI dip, EMA trend, Bollinger bounce) reimplemented against Alpaca paper data, to validate the engine before building the drag-and-drop React UI.
5. **Signal service** — once the engine loop is proven, add the `external_signal` node type and the Ollama-backed ingestion job.
6. **IBKR adapter** — after Alpaca path is validated in paper mode for the 30-45 day minimum window already established as a hard rule.
7. **Public read-only dashboard on netcup** — last step, only after there's real (even if small) paper-trading history worth showing.

## 6. Asset universe update (2026-09-07, after Bryan clarified his full account picture)

The original version of this doc assumed the bot's scope was IBKR + Alpaca only. Bryan has more accounts already open than that, which changes the plan:

> **Editorial note on this section:** deliberately kept generic — no specific balances, holdings, quantities, or cost-basis figures are recorded here or anywhere else in this repo, since `office-plan` is public. Those specifics live wherever Bryan tracks personal finances privately, not in git history.

- **Coinbase (crypto, funded, active holdings)** — this is the one account where reusing ApexAlgo's actual dependency choice (not its code) makes sense: **CCXT is MIT-licensed and Coinbase is one of the exchanges it already supports directly.** The broker-adapter interface from §3a should include a `CoinbaseAdapter` built on CCXT alongside the Alpaca and IBKR adapters, using the exact same forward-test/paper/live mode split. This is a smaller lift than either equities adapter since the library already exists and is unencumbered.
- **Tangem cold hardware wallet** — holds tokens directly, not exchange-custodied. Recommend keeping this **entirely manual, out of the automated bot's reach.** Signing transactions from a cold wallet requires exposing a private key or a hardware-signing flow to whatever process would automate it, which is a materially different (and much higher-consequence) risk than an exchange API key with trade-only permissions. If Bryan wants bot-driven crypto exposure, that should route through the Coinbase adapter above, not the cold wallet.
- **Kalshi + Polymarket (already open, not just a future data source)** — the original plan (§3b) treated these purely as sentiment-data inputs for the signal service. They're also real, tradable venues in their own right. Worth deciding explicitly: are they (a) signal-service data sources only, (b) tradable venues the bot can also place event-contract positions in, or (c) both. Recommend starting with (a) — lower integration cost, and prediction-market contracts as direct trade targets is a meaningfully different order-execution model (event contracts, not continuous price feeds) that deserves its own design pass later rather than being bundled into the first build.
- **Schwab (SCHD dollar-cost-average holding + QQQI, buy-and-hold)** — Bryan explicitly does not want this account touched by the bot; it's a long-term accumulation position with real unrealized gains he doesn't want disturbed. **Do not build any automated write/trade path to this account.** If Schwab API access gets set up at all, scope it read-only (portfolio value for a personal net-worth dashboard), and only if Bryan decides he wants that visibility — not assumed here. If he later wants an *active* Schwab account for the bot, that should be a separate, newly-funded account, never the DCA one.
- **Roth IRA (open, unfunded)** — not in scope for the bot. IRAs also carry their own day-trading/pattern-day-trader and wash-sale complications that make them a poor fit for an active strategy account regardless.

**Net effect on §3a's broker adapter layer:** three adapters, not two — **Alpaca** (equities/options, build first), **IBKR** (equities/options via `ib_async`, second), **Coinbase via CCXT** (crypto, can realistically be built in parallel with Alpaca since the library work is already done upstream).

## 7. Catalyst / event-driven trading pattern (the XRP/Rakuten scenario)

Bryan described a concrete pattern that's distinct from both ApexAlgo's per-candle technical-indicator model and a generic slow sentiment score: a **news-catalyst momentum trade**. Worked example given: XRP moved from ~$1.00 to ~$1.52 overnight on a verified Rakuten cash-rewards integration announcement — the kind of move a fast, verified, well-sized entry could have captured meaningfully.

This needs its own signal path, separate from the periodic (15-60 min) sentiment scoring in §3b:

1. **Faster-cadence monitoring for genuine breaking news** on watched symbols/tokens — this is in tension with running a 27B model on a schedule; likely needs a cheap/fast filtering pass (lightweight keyword/embedding trigger) that only wakes the full Qwen3.8:27B reasoning pass when something looks like a real catalyst, rather than running full LLM inference continuously.
2. **Credibility verification is the safety-critical step Bryan called out explicitly** ("verifications in order to make sure that there isn't fake news and that it is legit and not a scam") — cross-reference multiple independent, reputable sources before treating anything as a confirmed catalyst. This is exactly the kind of check a pump-and-dump scheme is designed to defeat, so it deserves real design attention later (source allowlists, corroboration count thresholds, checking for the story on wire services vs. only social media) rather than a single-source LLM judgment call.
3. **Confidence-gated sizing** — once verified, size the position (up to the account's configured max, matching the `max_order_value` pattern from ApexAlgo's risk model in §4) rather than an all-or-nothing bet.
4. **Exit plan matters as much as entry** — a trailing stop or staged take-profit (same tiered TP/SL nodes from §4) to actually capture the "wait for the boom, then take the money" part, rather than relying on manually watching it.
5. **This is where the standing hard rule (paper only, human approval gate, no auto-execution until validated) needs an explicit design answer, not a default assumption.** A pure human-approval-gate defeats the purpose of a catalyst trade if the window is minutes-to-hours and a phone notification requires Bryan to see it, evaluate it, and act before the move plays out. Recommended middle ground, consistent with the approval-gated pattern already used for OpenJarvis/Buzz elsewhere: the bot detects the catalyst, runs verification, drafts the trade (symbol, size, entry, exit plan, and *why* — the verified sources), and pushes a one-tap-approve notification, rather than either fully autonomous execution or a passive dashboard Bryan has to remember to check. Whether one-tap-approve is fast enough to actually catch these moves, or whether it needs to graduate to true autonomy after a track record is established, is an open decision — flagged below, not decided here.
6. **This pattern is genuinely the "small wins, base hits, occasional good one" model Bryan described**, not a search for a repeatable guaranteed formula — worth keeping the language in any public-facing content about this honest about that (matches the existing "don't oversell a HUD that doesn't run yet" principle already in `PROJECT_STATE.md`).

## 8. Open decisions (do not assume settled)

- Actual repo name/location for the new bot (replacing the freqtrade fork reference in `PROJECT-CONTEXT.md`)
- Where IB Gateway/TWS runs long-term given the NUC will physically travel between home and work
- Whether to reach out to ApexAlgo's author about the license before reusing any of their code verbatim (current answer: don't, reimplement clean-room instead)
- Exact schedule/cadence for the LLM signal service (cost of running Qwen3.8:27B on a schedule vs. on-demand)
- Whether the public dashboard ships before or after the LLC is formed (public-facing financial trading content may need its own disclaimer language — flag for the Tax/Compliance section of this repo when it gets closer)
- Kalshi/Polymarket: data-source-only vs. also-tradable-venue (§6)
- Schwab API: whether to pursue it at all, and if so read-only-only, given the DCA account must not be touched
- Catalyst-trade approval latency: whether one-tap-approve notifications are fast enough to capture genuine breaking-news moves, or whether that pattern needs to earn its way to more autonomy over time — and what "earning it" looks like in concrete, measurable terms before that conversation happens
- Source-credibility verification design for the catalyst path (§7.2) — allowlists, corroboration thresholds — not yet designed, flagged as safety-critical

---

**Note on scope:** the "use local AI at work on the homebrew app" plan mentioned alongside this is a separate, work-owned initiative and should **not** be documented in this public repo — keep any work-specific app details, code, or screenshots out of `office-plan` entirely, same boundary already applied elsewhere in this repo between personal and employer-owned work.
