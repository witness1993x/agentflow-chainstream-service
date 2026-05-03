# ChainStream Service Overlay

ChainStream-flavored deployment of `agentflow-article-publishing`.

## Why this exists

The framework (`../agentflow-article-publishing/`) is **brand-neutral by
design** — it ships with no `chainstream` references in code, so other
tenants / brands can deploy the same binary with their own
`~/.agentflow/topic_profiles.yaml` and `.env`.

This sibling repo is the **ChainStream-specific deployment overlay**. It
takes the neutral framework tarball and adds:

1. A pre-flavored `.env.chainstream.template` that pre-fills the brand
   knobs (`LARK_WEBHOOK_BRAND_PREFIX=[ChainStream]`,
   `AGENTFLOW_DEFAULT_TOPIC_PROFILE=chainstream`) but leaves all
   secrets empty for the operator.
2. A `topic_profile.chainstream.seed.yaml` starter that the operator
   tailors after install (not committed with real product facts —
   those are operator-private data).
3. `apply_overlay.sh` which the operator runs **after** the framework's
   `deploy.sh` to drop these files into `/opt/agentflow/` /
   `~/.agentflow/`.

## Layout

```
chainstream-service/
├── README.md                 # this file
├── INSTALL.md                # deploy guide
├── CHANGELOG.md              # overlay-version-only history
├── overlay/
│   ├── env.chainstream.template
│   ├── topic_profile.chainstream.seed.yaml
│   └── apply_overlay.sh
└── build_bundle.sh           # produces ~/Desktop/agentflow-chainstream-deploy.tar.gz
```

## Versioning

The overlay version is independent from the framework version. Pinning
relationship:

| chainstream-service | framework (agentflow-article-publishing) |
|---------------------|------------------------------------------|
| 1.0.0               | 1.0.20+                                  |

When the framework ships a new version with breaking env changes, bump
the overlay's pin and update the templates accordingly.

## Build

```bash
cd chainstream-service
bash build_bundle.sh
# → ~/Desktop/agentflow-chainstream-deploy.tar.gz
```

The bundle is fully self-contained — framework + overlay in one
tarball, nothing to scp twice.

## Deploy

```bash
scp ~/Desktop/agentflow-chainstream-deploy.tar.gz <host>:/tmp/
ssh <host> 'cd /opt && tar xzf /tmp/agentflow-chainstream-deploy.tar.gz'
ssh <host> 'sudo bash /opt/agentflow-chainstream-deploy/deploy.sh'
ssh <host> 'sudo bash /opt/agentflow-chainstream-deploy/apply_overlay.sh'
ssh <host> 'systemctl restart agentflow-review'
```

After this the operator edits `/opt/agentflow/backend/.env` to fill in
secrets (TG token, LLM keys, Lark webhook URL, etc.) — those never
ship in the bundle.
