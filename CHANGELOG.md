# Changelog — chainstream-service overlay

## [1.0.6] — 2026-05-04

* Pin bumped: framework v1.0.27+ (top_k default 3 → 5).
* `overlay/env.chainstream.template` mirrors the framework default with
  `AGENTFLOW_HOTSPOTS_SCHEDULE_TOP_K=5`.
* No other changes — this is purely a default-bump alignment release.

## [1.0.5] — 2026-05-04

* Pin bumped: framework v1.0.26+ required (introduces twitter_search
  collector). Default env in this overlay enables it.
* `overlay/sources.chainstream.seed.yaml` — twitter_kols block
  rewritten from a 5-handle hand-curated list to a 55-handle
  data-derived list:
  * Source: a 131,547-row Twitter KOL universe CSV the operator
    supplied; filtered down to 263 candidates with strict regex
    match on chainstream-domain tokens (MEV / on-chain / rollup /
    indexer / wallet / Solana / Cosmos / etc.) AND infra-flavored
    role tags (Developer / Defi / Blockchain / Founder / Technician
    / Analyst) AND ≥10k followers AND no NFT/memecoin/p2e/launchpad
    noise.
  * Top tier (25): @DefiLlama, @DuneAnalytics, @coinmetrics,
    @whale_map, @MapProtocol, @SolanaNews, etc. — flagged
    `weight: high`.
  * Mid tier (30): @sunnya97 (Cosmos/Osmosis), @HubbleProtocol,
    @Milkomeda_com, @Apillon, @TreehouseFi, etc. — flagged
    `weight: medium`.
  * 6 generalist accounts (@paulg / @sama / @karpathy / @simonw /
    @patrickc / @dhh) preserved at `weight: blocked` for visibility
    + easy un-blocking if brand pivot ever includes that beat.
* `overlay/sources.chainstream.seed.yaml` — added `twitter_search:`
  block with 6 chainstream-tailored Twitter v2 queries:
  * MEV / smart wallet / rollup / account abstraction
  * on-chain data / analytics / indexer
  * MCP / x402 (agent execution surface)
  * Solana mempool / DEX routing / smart money
  * intent settlement / EigenLayer / restaking
  * KYT / KYA / OFAC compliance
* `overlay/env.chainstream.template` — `AGENTFLOW_TWITTER_SEARCH_ENABLED`
  defaulted to `true` so the second recall layer fires out of the box.

### Operator note

55 KOLs is auto-curated, NOT hand-vetted. Some entries are protocol
official accounts which lean toward self-promotion; trim with
`weight: blocked` over time. The point is to seed a reasonable starting
pool that the v1.0.23 signal-domain filter + v1.0.25 blocklist can
sieve, not a perfect editorial list.

## [1.0.4] — 2026-05-04

* `overlay/sources.chainstream.seed.yaml` — three institutional crypto
  research RSS feeds added: Galaxy Research, Variant Fund, Paradigm.
  Each entry carries a `note:` reminding the operator to verify the
  URL post-install (feed paths shift); per-feed errors don't break
  the rest of the scan thanks to feedparser isolation.
* No env / overlay-script changes; pin to framework v1.0.25+ unchanged.

## [1.0.3] — 2026-05-04

* Pin bumped: framework v1.0.25+ required (introduces signal blocklist).
* Overlay env adds default `AGENTFLOW_SIGNAL_BLOCKLIST_TOKENS=` covering
  the entities that consistently squeaked past the v1.0.23 coverage
  filter on chainstream profile: `OpenAI` / `ChatGPT` / `Anthropic` /
  `Sam Altman` / `Greg Brockman` / `DeepSeek` / `Claude API` /
  `Vintage` / `Omega` / `Southwest Airlines` / `Stockholm`. Merged
  with chainstream's existing `avoid_terms` (general AI hype /
  consumer chatbot / celebrity crypto / macro politics) at runtime.
* Operator extends this list as new noise patterns appear from
  scheduled scans.

## [1.0.2] — 2026-05-04

* Pin bumped: framework v1.0.22+ required (introduces signal-level
  domain filter + KOL weight allowlist).
* New overlay file `overlay/sources.chainstream.seed.yaml` — ships at
  `~/.agentflow/sources.yaml` for fresh installs. Generalist Twitter
  accounts (`@sama` / `@paulg` / `@karpathy` / `@simonw` / `@patrickc` /
  `@dhh`) are present but marked `weight: blocked` so they don't pull
  signal by default. HN keywords swapped from `AI` / `Claude` / `LLM`
  (matches half of HN front page) to crypto-infra-specific terms
  (`MEV` / `rollup` / `DEX` / `mempool` / `OFAC` / `account abstraction`
  / `MCP` / `x402` / `on-chain`). RSS list pruned to crypto pubs only.
* `apply_overlay.sh` now also seeds sources.yaml when missing (idempotent
  rule preserved — never clobbers operator's existing config without
  `--force`). When existing config is present, prints a tip reminding
  the operator to mark generalist KOLs `weight: blocked`.
* Overlay env adds:
  * `AGENTFLOW_SIGNAL_DOMAIN_THRESHOLD=0.03` — pre-cluster signal
    filter (drops irrelevant tweets before clustering).
  * `AGENTFLOW_TWITTER_KOL_ONLY_HIGH=false` — defaults off so the
    seeded medium-weight crypto KOLs (`@balajis` etc.) still fire;
    operator can flip to `true` for max strictness.

## [1.0.1] — 2026-05-03

* Pin bumped: framework v1.0.21+ required (introduces
  `AGENTFLOW_TOPIC_FIT_HARD_THRESHOLD`).
* Overlay env adds `AGENTFLOW_TOPIC_FIT_HARD_THRESHOLD=0.05` so a
  fresh ChainStream install ships with the hard topic-fit gate ON.
  Prevents the v1.0.20-era "TCG customs article spun around
  ChainStream" forced-analogy failure mode out of the box.

## [1.0.0] — 2026-05-03

Initial split.

* Sibling repo carved out from the framework's deploy bundle.
* Pinned to `agentflow-article-publishing` v1.0.20+.
* Overlay env pre-fills `LARK_WEBHOOK_BRAND_PREFIX=[ChainStream]`,
  `AGENTFLOW_DEFAULT_TOPIC_PROFILE=chainstream`,
  `AGENTFLOW_HOTSPOTS_SCHEDULE=09:00,20:00`, and `MOCK_LLM=false`.
* Topic profile seed (chainstream) ships skeletal — operator runs
  `af topic-profile init -i --profile chainstream` post-install to
  fill real `product_facts` / `perspectives`.
* `apply_overlay.sh` is idempotent: never clobbers operator values
  (only fills empty keys / new keys; respects existing `.env` /
  `topic_profiles.yaml`). `--force` is available for re-pin scenarios.
