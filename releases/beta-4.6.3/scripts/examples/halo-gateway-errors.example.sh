#!/usr/bin/env bash

# Halo HomeLab AgentOps - Gateway Errors Summary v1.2
# Telegram-safe. Strict mode: only real Gateway error lines.

LOG="$HOME/halo-telegram-gateway/logs/gateway.log"

echo "HALO_GATEWAY_ERRORS"
echo "host=$(hostname)"

if [ ! -f "$LOG" ]; then
  echo "log=missing"
  echo "real_errors_seen=unknown"
  echo "overall=WARNING"
  exit 0
fi

REAL_ERRORS="$(
  grep -E 'Gateway error:|Traceback|Exception|timed out after|Error running|failed:' "$LOG" 2>/dev/null \
    | grep -Ev 'HALO_STATUS|HALO_AGENTS|HALO_AUDIT|HALO_COOLDOWN|HALO_DOCKER|HALO_NODE|HALO_NAS|HALO_OVERVIEW|errors=0|warnings=0|status=received|audit_log|cooldown|completed' \
    || true
)"

COUNT="$(printf "%s\n" "$REAL_ERRORS" | sed '/^$/d' | wc -l | tr -d ' ')"

echo "log=found"
echo "real_errors_seen=$COUNT"

if [ "$COUNT" -eq 0 ]; then
  echo "recent_real_errors=none"
else
  echo
  echo "last_real_error:"
  printf "%s\n" "$REAL_ERRORS" | sed '/^$/d' | tail -1 | cut -c1-420

  echo
  echo "recent_real_errors:"
  printf "%s\n" "$REAL_ERRORS" | sed '/^$/d' | tail -3 | cut -c1-420
fi

if systemctl --user is-active halo-telegram-gateway.service >/dev/null 2>&1; then
  echo
  echo "gateway_service=active"
  echo "overall=GREEN"
else
  echo
  echo "gateway_service=not_active"
  echo "overall=ERROR"
fi

echo "Security: no tokens / no env / no secrets"
