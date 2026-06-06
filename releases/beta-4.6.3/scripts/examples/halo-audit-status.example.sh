#!/usr/bin/env bash

# Halo HomeLab AgentOps - Audit Status
# Telegram-safe summary of audit log.

AUDIT_LOG="$HOME/halo-telegram-gateway/audit/telegram-command-audit.log"

echo "HALO_AUDIT_STATUS"
echo "host=$(hostname)"

if [ ! -f "$AUDIT_LOG" ]; then
  echo "audit_log=missing"
  echo "overall=WARNING"
  exit 0
fi

LINES="$(wc -l < "$AUDIT_LOG" | tr -d ' ')"
LAST="$(tail -1 "$AUDIT_LOG" 2>/dev/null)"

echo "audit_log=found"
echo "entries=$LINES"
echo "last_entry=$LAST"
echo "overall=GREEN"
echo "Security: no tokens / no secrets / local audit only"
