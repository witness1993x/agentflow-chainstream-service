#!/usr/bin/env bash
# Build a self-contained ChainStream service bundle.
#
# Composition:
#   1. Build framework deploy bundle into a temp dir (via the
#      framework's own scripts/build_deploy_bundle.sh — never copy
#      framework files manually so we always pick up its latest
#      sanity guards / required-files checks).
#   2. Extract that tarball into a stage dir.
#   3. Layer the ChainStream overlay on top, plus a wrapper
#      apply_overlay.sh that the operator runs post-deploy.
#   4. Re-tar to ~/Desktop/agentflow-chainstream-deploy.tar.gz.
#
# Usage:
#   bash build_bundle.sh [output_path]

set -euo pipefail

OVERLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(cd "$OVERLAY_DIR/.." && pwd)/agentflow-article-publishing"
OUTPUT="${1:-$HOME/Desktop/agentflow-chainstream-deploy.tar.gz}"

[ -d "$FRAMEWORK_DIR" ] || {
  echo "FATAL: expected framework at $FRAMEWORK_DIR" >&2
  exit 1
}
[ -x "$FRAMEWORK_DIR/scripts/build_deploy_bundle.sh" ] || {
  echo "FATAL: framework build script missing or not executable" >&2
  exit 1
}

STAGE="$(mktemp -d -t chainstream-bundle-XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT

# ---- 1. Framework bundle ----
FRAMEWORK_TARBALL="$STAGE/framework.tar.gz"
echo "[1/4] building framework bundle..."
bash "$FRAMEWORK_DIR/scripts/build_deploy_bundle.sh" "$FRAMEWORK_TARBALL" >/dev/null

# ---- 2. Extract framework into stage ----
echo "[2/4] extracting framework..."
EXTRACT="$STAGE/extract"
mkdir -p "$EXTRACT"
tar -xzf "$FRAMEWORK_TARBALL" -C "$EXTRACT"
# Rename the top-level dir from agentflow-deploy → agentflow-chainstream-deploy
mv "$EXTRACT/agentflow-deploy" "$EXTRACT/agentflow-chainstream-deploy"
DEST="$EXTRACT/agentflow-chainstream-deploy"

# ---- 3. Layer overlay ----
echo "[3/4] layering ChainStream overlay..."
mkdir -p "$DEST/chainstream-overlay"
cp "$OVERLAY_DIR/overlay/env.chainstream.template"            "$DEST/chainstream-overlay/"
cp "$OVERLAY_DIR/overlay/topic_profile.chainstream.seed.yaml" "$DEST/chainstream-overlay/"
cp "$OVERLAY_DIR/overlay/apply_overlay.sh"                    "$DEST/chainstream-overlay/"
chmod +x "$DEST/chainstream-overlay/apply_overlay.sh"

# Top-level convenience symlink-equivalent: a wrapper at the bundle
# root so the operator can run it without remembering the subdir.
cat > "$DEST/apply_overlay.sh" <<'WRAPPER'
#!/usr/bin/env bash
exec sudo bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/chainstream-overlay/apply_overlay.sh" "$@"
WRAPPER
chmod +x "$DEST/apply_overlay.sh"

# Top-level install / changelog mirror so operators know what they got.
cp "$OVERLAY_DIR/INSTALL.md"   "$DEST/INSTALL_CHAINSTREAM.md"
cp "$OVERLAY_DIR/CHANGELOG.md" "$DEST/CHAINSTREAM_CHANGELOG.md"

# ---- 4. Sanity guards (chainstream-specific) ----
fail=0
for required in \
    "chainstream-overlay/env.chainstream.template" \
    "chainstream-overlay/topic_profile.chainstream.seed.yaml" \
    "chainstream-overlay/apply_overlay.sh" \
    "INSTALL_CHAINSTREAM.md" \
    "CHAINSTREAM_CHANGELOG.md" \
    "deploy.sh" \
    "agentflow-review.service" \
    "backend/pyproject.toml"; do
  if [ ! -e "$DEST/$required" ]; then
    echo "FATAL: missing required file in chainstream bundle: $required" >&2
    fail=1
  fi
done
# The overlay must NOT contain any baked-in secret. Flag if it sneaks
# a non-empty token / webhook URL pattern.
if grep -qE '^(TELEGRAM_BOT_TOKEN|MOONSHOT_API_KEY|JINA_API_KEY|ATLASCLOUD_API_KEY|GHOST_ADMIN_API_KEY|LINKEDIN_ACCESS_TOKEN|TWITTER_BEARER_TOKEN|LARK_WEBHOOK_URL|LARK_WEBHOOK_SECRET)=.+' "$DEST/chainstream-overlay/env.chainstream.template"; then
  echo "FATAL: overlay env template contains a non-empty secret line" >&2
  fail=1
fi
[ "$fail" -eq 0 ] || exit 1

# ---- 5. Tar it up ----
echo "[4/4] tarring..."
tar -C "$EXTRACT" -czf "$OUTPUT" agentflow-chainstream-deploy
size_kb=$(du -k "$OUTPUT" | cut -f1)
file_count=$(tar -tzf "$OUTPUT" | wc -l | tr -d ' ')
echo "✓ wrote $OUTPUT  (${size_kb} KB, ${file_count} entries)"
echo
echo "next:"
echo "  scp $OUTPUT user@vm:/tmp/"
echo "  ssh user@vm 'cd /opt && sudo tar xzf /tmp/$(basename "$OUTPUT")'"
echo "  ssh user@vm 'sudo bash /opt/agentflow-chainstream-deploy/deploy.sh'"
echo "  ssh user@vm 'sudo bash /opt/agentflow-chainstream-deploy/apply_overlay.sh'"
echo "  ssh user@vm 'systemctl restart agentflow-review'"
