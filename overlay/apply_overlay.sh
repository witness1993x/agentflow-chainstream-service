#!/usr/bin/env bash
# Apply the ChainStream service overlay on top of a framework install.
#
# Run AFTER the framework's deploy.sh has placed /opt/agentflow/.
#
#   sudo bash /opt/agentflow-chainstream-deploy/apply_overlay.sh
#
# Idempotent: refuses to clobber an operator's existing .env or
# topic_profiles.yaml. To force, pass --force.

set -euo pipefail

PREFIX="${PREFIX:-/opt/agentflow}"
USER_NAME="${AGENTFLOW_USER:-agentflow}"

OVERLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log()  { printf '\033[1;34m[chainstream]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[chainstream]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m[chainstream]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "must run as root (sudo bash $0)"
[ -d "$PREFIX/backend" ] || fail "framework not installed at $PREFIX/backend; run deploy.sh first"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

# 1. Merge env overlay into /opt/agentflow/backend/.env.
#    Only adds keys that aren't already set; never overwrites operator values.
ENV_TARGET="$PREFIX/backend/.env"
ENV_OVERLAY="$OVERLAY_DIR/env.chainstream.template"
[ -f "$ENV_OVERLAY" ] || fail "missing $ENV_OVERLAY"

if [ ! -f "$ENV_TARGET" ]; then
  log "no .env yet, seeding from framework template + chainstream overlay"
  cp "$PREFIX/.env.template" "$ENV_TARGET"
  chmod 600 "$ENV_TARGET"
  chown "$USER_NAME:$USER_NAME" "$ENV_TARGET"
fi

while IFS= read -r line; do
  case "$line" in
    ""|\#*) continue ;;
  esac
  key="${line%%=*}"
  if grep -qE "^${key}=" "$ENV_TARGET" 2>/dev/null; then
    existing=$(grep -E "^${key}=" "$ENV_TARGET" | head -n1)
    if [ "$FORCE" -eq 1 ]; then
      log "FORCE override $key in $ENV_TARGET"
      sed -i.bak -e "s|^${key}=.*|${line}|" "$ENV_TARGET"
    elif [ "${existing#*=}" = "" ]; then
      # key present but empty → fill from overlay
      sed -i.bak -e "s|^${key}=.*|${line}|" "$ENV_TARGET"
      log "filled empty $key"
    else
      log "skip $key (operator value present)"
    fi
  else
    echo "$line" >> "$ENV_TARGET"
    log "appended $key"
  fi
done < "$ENV_OVERLAY"
rm -f "$ENV_TARGET.bak" 2>/dev/null || true

# 2. Seed ~/.agentflow/topic_profiles.yaml only if missing.
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
[ -n "$USER_HOME" ] || fail "could not resolve home for $USER_NAME"
PROFILE_DIR="$USER_HOME/.agentflow"
PROFILE_FILE="$PROFILE_DIR/topic_profiles.yaml"
PROFILE_SEED="$OVERLAY_DIR/topic_profile.chainstream.seed.yaml"

mkdir -p "$PROFILE_DIR"
chown "$USER_NAME:$USER_NAME" "$PROFILE_DIR"

if [ ! -f "$PROFILE_FILE" ] || [ "$FORCE" -eq 1 ]; then
  cp "$PROFILE_SEED" "$PROFILE_FILE"
  chown "$USER_NAME:$USER_NAME" "$PROFILE_FILE"
  log "seeded $PROFILE_FILE"
  warn "next: have the operator run 'af topic-profile init -i --profile chainstream' to fill product_facts / perspectives"
else
  log "topic_profiles.yaml already exists; skipping (use --force to overwrite)"
fi

# 3. Seed ~/.agentflow/sources.yaml only if missing (v1.0.2 — D1 recall fix).
SOURCES_FILE="$PROFILE_DIR/sources.yaml"
SOURCES_SEED="$OVERLAY_DIR/sources.chainstream.seed.yaml"

if [ ! -f "$SOURCES_FILE" ] || [ "$FORCE" -eq 1 ]; then
  if [ -f "$SOURCES_SEED" ]; then
    cp "$SOURCES_SEED" "$SOURCES_FILE"
    chown "$USER_NAME:$USER_NAME" "$SOURCES_FILE"
    log "seeded $SOURCES_FILE (chainstream-flavored — generalist KOLs blocked)"
  else
    warn "sources.chainstream.seed.yaml missing from overlay; skipping sources seed"
  fi
else
  log "sources.yaml already exists; skipping (use --force to overwrite)"
  warn "tip: existing sources.yaml may still have @sama/@paulg/etc set to weight=high;"
  warn "     either re-run with --force or manually mark them weight=blocked to stop"
  warn "     general-tech KOLs from polluting D1 recall."
fi

echo
log "ChainStream overlay applied. Restart daemon:"
log "  systemctl restart agentflow-review"
log "Check status:"
log "  /opt/agentflow/backend/.venv/bin/af doctor"
log "  /opt/agentflow/backend/.venv/bin/af review-schedule-status"
