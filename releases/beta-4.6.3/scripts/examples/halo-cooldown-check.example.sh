#!/usr/bin/env bash

# Halo HomeLab AgentOps - Telegram Command Cooldown Check
# Local-only. No secrets. Protects Gateway from spam/repeated commands.

COMMAND="${1:-unknown}"
STATE_DIR="$HOME/halo-telegram-gateway/state/cooldowns"

mkdir -p "$STATE_DIR"
chmod 700 "$HOME/halo-telegram-gateway/state" 2>/dev/null || true
chmod 700 "$STATE_DIR"

# Default cooldown in seconds
COOLDOWN=10

case "$COMMAND" in
  "/help"|"/start"|"/status")
    COOLDOWN=0
    ;;
  "/audit"|"/gateway"|"/docker"|"/nas"|"/node")
    COOLDOWN=10
    ;;
  "/halo_status"|"/agents"|"/overview")
    COOLDOWN=20
    ;;
  "/last_fire"|"/last_maint"|"/last_docs"|"/reports")
    COOLDOWN=30
    ;;
  "/fire")
    COOLDOWN=120
    ;;
  "/docs")
    COOLDOWN=180
    ;;
  "/maint"|"/maint_dryrun"|"/maint_clean_safe"|"/maint_deep")
    COOLDOWN=300
    ;;
  *)
    COOLDOWN=15
    ;;
esac

SAFE_NAME="$(echo "$COMMAND" | tr -cd 'A-Za-z0-9_-' | sed 's/^$/unknown/')"
STAMP_FILE="$STATE_DIR/${SAFE_NAME}.last"
NOW="$(date +%s)"

if [ "$COOLDOWN" -eq 0 ]; then
  echo "HALO_COOLDOWN=OK | command=$COMMAND | cooldown=0"
  exit 0
fi

if [ -f "$STAMP_FILE" ]; then
  LAST="$(cat "$STAMP_FILE" 2>/dev/null || echo 0)"
else
  LAST=0
fi

ELAPSED=$((NOW - LAST))
REMAINING=$((COOLDOWN - ELAPSED))

if [ "$ELAPSED" -lt "$COOLDOWN" ]; then
  echo "HALO_COOLDOWN=ACTIVE"
  echo "command=$COMMAND"
  echo "cooldown=${COOLDOWN}s"
  echo "remaining=${REMAINING}s"
  echo "Try again after cooldown."
  exit 2
fi

echo "$NOW" > "$STAMP_FILE"
chmod 600 "$STAMP_FILE"

echo "HALO_COOLDOWN=OK | command=$COMMAND | cooldown=${COOLDOWN}s"
exit 0
