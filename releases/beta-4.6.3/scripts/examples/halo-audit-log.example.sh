#!/usr/bin/env bash

# Halo HomeLab AgentOps - Telegram Gateway Audit Logger
# Local-only. No secrets. Append-only audit log.

AUDIT_DIR="$HOME/halo-telegram-gateway/audit"
AUDIT_LOG="$AUDIT_DIR/telegram-command-audit.log"

mkdir -p "$AUDIT_DIR"
chmod 700 "$AUDIT_DIR"

COMMAND="${1:-unknown}"
STATUS="${2:-received}"
NOTE="${3:-none}"

TS="$(date '+%Y-%m-%d %H:%M:%S %Z')"
HOST="$(hostname)"

# Sanitize newlines and separators
COMMAND="$(echo "$COMMAND" | tr '\n\r|' '   ')"
STATUS="$(echo "$STATUS" | tr '\n\r|' '   ')"
NOTE="$(echo "$NOTE" | tr '\n\r|' '   ')"

echo "$TS | host=$HOST | command=$COMMAND | status=$STATUS | note=$NOTE" >> "$AUDIT_LOG"

chmod 600 "$AUDIT_LOG"

echo "HALO_AUDIT_LOG=OK | file=$AUDIT_LOG"
