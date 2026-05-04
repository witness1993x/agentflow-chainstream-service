# Changelog — chainstream-service overlay

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
