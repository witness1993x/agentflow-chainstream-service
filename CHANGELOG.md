# Changelog — chainstream-service overlay

## [1.0.8] — 2026-04-30

* Pin bumped: framework v1.0.28+ required (introduces signal-quality
  short-reply filter). The two changes below address the **two noise
  hotspots** observed in the v1.0.7 + framework v1.0.27 verification
  run with Twitter funded:
  * **Joseph (Hindi-mixed @-replies) → "Joseph 回归家庭" hotspot.**
    Two layers of root cause:
    * Layer 1 — short @-reply chatter slipped past the 0.03 domain
      gate by being too short to fail it. Fixed in framework v1.0.28
      with `_apply_signal_quality_filter` (drops Twitter @-replies
      under 60 chars). This overlay turns it on by default:
      `AGENTFLOW_DROP_SHORT_REPLIES=true` /
      `AGENTFLOW_MIN_REPLY_LEN=60`.
    * Layer 2 — the v1.0.5 compliance search query
      `(KYT OR KYA OR OFAC) (crypto OR onchain OR wallet)` was
      pulling Hindi tweets en masse because **"kya"** is
      Hindi for "what?" and Twitter's tokenizer is
      case-insensitive — every Hindi @-reply containing "kya"
      ALSO containing the word "crypto" (a common loanword in
      Indian crypto Twitter) matched the query. Even after the
      60-char filter, longer Hindi @-replies (~120 chars) still
      formed a 2-signal Joseph cluster. **Query rewritten** to use
      the spelled-out forms: `("Know Your Transaction" OR "Know
      Your Address" OR OFAC OR "crypto compliance") (crypto OR
      onchain OR wallet)`. OFAC kept as-is — it's a unique
      English acronym with no foreign-language collision risk.
    * Layer 3 — same class of failure surfaced once more on the
      MEV beat: the v1.0.5 query
      `MEV OR "smart wallet" OR rollup OR "account abstraction"`
      pulled Arabic coupon-spam tweets containing the string
      `MEv` (random 3-letter sequence in shopping-promo content).
      **Query rewritten** to require co-occurrence with an
      unambiguous crypto-context token:
      `("MEV" OR "Maximal Extractable Value" OR "MEV bot" OR
      "smart wallet" OR rollup OR "account abstraction")
      (crypto OR onchain OR ethereum OR solana OR wallet OR
      blockchain)`. Pattern: any 3-letter crypto acronym that
      could collide with a non-English token MUST be paired with
      a unique-English crypto co-occurrence token in v2 search.
  * **"Karpathy's Loop / CPU auto-architecture" hotspot.** Came from
    the v1.0.7 search query `(MCP OR x402) (crypto OR onchain OR
    wallet)` collecting Anthropic-MCP / Model-Context-Protocol
    chatter (which Twitter's relevance ranker happily threw at the
    bare token "MCP" and which @karpathy posts about regularly).
    The overlay's "MCP" was supposed to mean **Multi-Chain Protocol**,
    not Anthropic's protocol. Fixes:
    * `overlay/sources.chainstream.seed.yaml` — search query rewritten
      to `("Multi-Chain Protocol" OR x402 OR "agent payments")
      (crypto OR onchain OR wallet)`.
    * `overlay/sources.chainstream.seed.yaml` — HN keyword "MCP"
      replaced with "Multi-Chain Protocol" / "crypto agent" /
      "onchain agent". HN's broad post titles otherwise match
      Anthropic-MCP discussion threads.
    * `overlay/topic_profile.chainstream.seed.yaml` — `keyword_groups`
      bare "MCP" replaced with "Multi-Chain Protocol" / "x402" /
      "crypto agent". `search_queries` "MCP crypto" replaced with
      "Multi-Chain Protocol crypto wallet".
    * `overlay/topic_profile.chainstream.seed.yaml` — `avoid_terms`
      added: Anthropic, Model Context Protocol, Karpathy, OpenAI,
      ChatGPT. Belt-and-suspenders for any signal that survives
      upstream filtering — D2's spine_lint will reject articles
      anchored on these.
    * `overlay/env.chainstream.template` — `AGENTFLOW_SIGNAL_BLOCKLIST_TOKENS`
      extended with "Model Context Protocol" and "Karpathy". This
      drops the signal at the framework's blocklist stage before
      it ever reaches clustering.
* No other changes. KOL list, RSS list, and weight tiers are
  unchanged from 1.0.7.

## [1.0.7] — 2026-05-04

* Replace v1.0.4's three guessed RSS URLs (Galaxy / Variant / Paradigm)
  with **four verified-live** crypto-infra RSS feeds. Each URL was
  probed with `curl -A "feedparser/6.0"` and confirmed HTTP 200 with
  valid RSS/Atom XML body before commit:
  * **Variant Fund** — `https://variant.fund/feed/` (small but live;
    survived from v1.0.4 since the URL was correct)
  * **Bankless** — `https://www.bankless.com/rss/feed` (canonical
    after 302 from `/feed`)
  * **The Defiant** — `https://thedefiant.io/api/feed` (canonical
    after 301 from `/feed`)
  * **Ethereum Foundation Blog** — `https://blog.ethereum.org/en/feed.xml`
    (canonical after 301 from `/feed.xml`)
* Dropped:
  * **Galaxy Research** — `/research/feed/` 301-redirects to an HTML
    insights page; no public RSS endpoint at any obvious path.
  * **Paradigm** — every `feed.xml` / `rss.xml` / `writing/feed.xml`
    variant returns 404; main page HTML carries no `<link rel=alternate>`
    pointing at a feed. They appear to not publish RSS publicly.
* Total RSS list now 7 (3 original + 4 new), all live.

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
