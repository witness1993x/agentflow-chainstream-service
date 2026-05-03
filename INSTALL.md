# ChainStream Service — Install Guide

Self-contained tarball that bundles the brand-neutral framework
(`agentflow-article-publishing`) + the ChainStream overlay. One scp,
two scripts.

## Prerequisites

* Linux host with Python 3.11+, systemd, sudo
* Outbound HTTPS to: api.telegram.org, api.moonshot.cn, api.jina.ai,
  api.atlascloud.ai, your Ghost domain (optional), open.larksuite.com
  (optional, only if Lark webhook is used)

## Install

```bash
# 1. Push the bundle
scp ~/Desktop/agentflow-chainstream-deploy.tar.gz <host>:/tmp/

# 2. On <host>:
ssh <host>
sudo mkdir -p /opt
cd /opt
sudo tar xzf /tmp/agentflow-chainstream-deploy.tar.gz
ls -d /opt/agentflow-chainstream-deploy   # sanity

# 3. Standard framework install (creates /opt/agentflow/, systemd unit, venv).
sudo bash /opt/agentflow-chainstream-deploy/deploy.sh

# 4. Apply ChainStream overlay (env defaults + topic_profile seed).
sudo bash /opt/agentflow-chainstream-deploy/apply_overlay.sh

# 5. Fill in operator-owned secrets in /opt/agentflow/backend/.env.
#    The overlay pre-pins brand prefix and default profile but never
#    pre-fills tokens. Edit:
sudo nano /opt/agentflow/backend/.env
#    Required: TELEGRAM_BOT_TOKEN, MOONSHOT_API_KEY (or ANTHROPIC_API_KEY),
#              JINA_API_KEY, ATLASCLOUD_API_KEY
#    Optional: GHOST_*, LARK_WEBHOOK_*

# 6. Restart and verify.
sudo systemctl restart agentflow-review
sudo systemctl status  agentflow-review
sudo /opt/agentflow/backend/.venv/bin/af doctor
sudo /opt/agentflow/backend/.venv/bin/af review-schedule-status
```

## After install

1. In Telegram, find your bot (whatever username corresponds to
   `TELEGRAM_BOT_TOKEN`) and send `/start`. The daemon auto-captures
   the chat_id; the seeded chainstream profile makes
   `_detect_next_step` skip past `missing_profile` so you go straight
   to **incomplete_profile** instead.
2. Run `af topic-profile init -i --profile chainstream` and fill in
   the three real `product_facts` placeholders + any perspectives
   refinements. This is the single most important step for output
   quality (anchors drafts to real ChainStream specifics — see
   v1.0.18 specificity_lint).
3. Send `/start` again on TG. The detector should now report `ready`.
4. (Optional) Configure the Lark group bot:
   * Add a custom bot to the group, copy webhook URL → `LARK_WEBHOOK_URL`
   * Set 签名校验 → copy secret to `LARK_WEBHOOK_SECRET`
   * Set 自定义关键词 → list "AgentFlow" → already in overlay
   * Restart daemon. Next 09:00 / 20:00 scan will produce a Lark
     digest card with `[ChainStream]` prefix and a "📝 去 TG 选题"
     button.

## Update path

When the framework ships a new version (e.g. v1.0.21):

```bash
cd <wherever you keep the chainstream-service repo>
bash build_bundle.sh   # picks up the latest framework tag
scp ~/Desktop/agentflow-chainstream-deploy.tar.gz <host>:/tmp/
ssh <host>
sudo tar xzf /tmp/agentflow-chainstream-deploy.tar.gz -C /opt --overwrite
sudo bash /opt/agentflow-chainstream-deploy/deploy.sh   # idempotent
# apply_overlay.sh is idempotent and never clobbers operator values
sudo systemctl restart agentflow-review
```
