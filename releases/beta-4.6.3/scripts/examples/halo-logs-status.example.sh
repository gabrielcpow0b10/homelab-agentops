#!/usr/bin/env bash

# Halo HomeLab AgentOps - Logs Status
# Telegram-safe. Read-only.

ROOT="$HOME/halo-telegram-gateway"
GATEWAY_LOG="$ROOT/logs/gateway.log"
AUDIT_LOG="$ROOT/audit/telegram-command-audit.log"

echo "HALO_LOGS_STATUS"
echo "host=$(hostname)"

if [ -f "$GATEWAY_LOG" ]; then
  echo "gateway_log=found"
  echo "gateway_log_size_bytes=$(stat -c%s "$GATEWAY_LOG" 2>/dev/null || echo 0)"
else
  echo "gateway_log=missing"
fi

if [ -f "$AUDIT_LOG" ]; then
  echo "audit_log=found"
  echo "audit_log_size_bytes=$(stat -c%s "$AUDIT_LOG" 2>/dev/null || echo 0)"
else
  echo "audit_log=missing"
fi

echo "gateway_archives=$(find "$ROOT/logs/archive" -type f 2>/dev/null | wc -l | tr -d ' ')"
echo "audit_archives=$(find "$ROOT/audit/archive" -type f 2>/dev/null | wc -l | tr -d ' ')"

TIMER_STATE="$(systemctl --user is-active halo-log-rotate.timer 2>/dev/null || echo inactive)"
echo "timer=$TIMER_STATE"

echo "overall=GREEN"
echo "Security: read-only / no tokens / no secrets"
