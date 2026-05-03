# Changelog — chainstream-service overlay

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
