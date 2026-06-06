#!/usr/bin/env bash

# Halo HomeLab AgentOps - Telegram Gateway Status v1.1
# Read-only. Does not expose token/env content.
# Counts only real gateway errors.

SERVICE="halo-telegram-gateway.service"
LOG="$HOME/halo-telegram-gateway/logs/gateway.log"

STATE="$(systemctl --user is-active "$SERVICE" 2>/dev/null || echo unknown)"
ENABLED="$(systemctl --user is-enabled "$SERVICE" 2>/dev/null || echo unknown)"
MAINPID="$(systemctl --user show "$SERVICE" -p MainPID --value 2>/dev/null || echo N/A)"
START_TIME="$(systemctl --user show "$SERVICE" -p ExecMainStartTimestamp --value 2>/dev/null || echo N/A)"

echo "HALO_GATEWAY_STATUS"
echo "host=$(hostname)"
echo "service=$STATE"
echo "enabled=$ENABLED"
echo "pid=$MAINPID"
echo "started=$START_TIME"

if [ -f "$LOG" ]; then
  REAL_ERRORS="$(
    grep -E 'Gateway error:|Traceback|Exception|timed out after|Error running|failed:' "$LOG" 2>/dev/null \
      | grep -Ev 'HALO_STATUS|HALO_AGENTS|HALO_AUDIT|HALO_COOLDOWN|HALO_DOCKER|HALO_NODE|HALO_NAS|HALO_OVERVIEW|errors=0|warnings=0|status=received|audit_log|cooldown|completed' \
      || true
  )"

  COUNT="$(printf "%s\n" "$REAL_ERRORS" | sed '/^$/d' | wc -l | tr -d ' ')"
  LAST="$(printf "%s\n" "$REAL_ERRORS" | sed '/^$/d' | tail -1 | cut -c1-300)"

  echo "log=found"
  echo "real_errors_seen=$COUNT"

  if [ "$COUNT" -gt 0 ]; then
    echo "last_real_error=$LAST"
  else
    echo "last_real_error=none"
  fi
else
  echo "log=missing"
  echo "real_errors_seen=unknown"
fi

if [ "$STATE" = "active" ]; then
  echo "overall=GREEN"
else
  echo "overall=ERROR"
fi

echo "Security: whitelist only / no shell / no token output"
