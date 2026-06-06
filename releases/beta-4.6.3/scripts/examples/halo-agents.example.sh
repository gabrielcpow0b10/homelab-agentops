#!/usr/bin/env bash

MODE="${1:-normal}"
COMPACT=0
[ "$MODE" = "--compact" ] && COMPACT=1

OK=0
WARN=0
ERR=0

say() {
  [ "$COMPACT" -eq 0 ] && echo "$@"
}

ok() {
  say "OK      $1"
  OK=$((OK + 1))
}

warn() {
  say "WARNING $1"
  WARN=$((WARN + 1))
}

err() {
  say "ERROR   $1"
  ERR=$((ERR + 1))
}

section() {
  say
  say "===== $1 ====="
}

HOST="$(hostname)"
NOW="$(date)"

FIRE_TIMER="$(systemctl --user is-active halo-fire-standby.timer 2>/dev/null || echo unknown)"
GATEWAY_STATE="$(systemctl --user is-active halo-telegram-gateway.service 2>/dev/null || echo unknown)"
DOCKER_STATE="$(systemctl is-active docker 2>/dev/null || echo unknown)"
CONTAINER_COUNT="$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')"

if mountpoint -q /path/to/homelab-projects; then
  NAS_MODE="MOUNTED"
else
  NAS_MODE="STANDBY-SAFE"
fi

say "HALO AGENTS STATUS"
say "Host: $HOST"
say "Time: $NOW"
say "Mode: READ-ONLY / NAS-SAFE"

section "COMMAND LAYER"

for cmd in halo-status halo-fire halo-docs halo-maint halo-maint-dryrun halo-maint-clean-safe halo-maint-weekly halo-maint-process-weekly; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd available"
  else
    err "$cmd missing"
  fi
done

section "SERVICES AND TIMERS"

[ "$FIRE_TIMER" = "active" ] && ok "Halo FIRE standby timer active" || err "Halo FIRE standby timer is $FIRE_TIMER"
[ "$GATEWAY_STATE" = "active" ] && ok "Halo Telegram Gateway active" || err "Halo Telegram Gateway is $GATEWAY_STATE"

section "AGENT ROLES"

command -v halo-fire >/dev/null 2>&1 && ok "FIRE agent ready" || err "FIRE agent missing"
command -v halo-docs >/dev/null 2>&1 && ok "Docs Agent ready" || err "Docs Agent missing"
command -v halo-maint >/dev/null 2>&1 && ok "Maintenance Agent ready" || err "Maintenance Agent missing"
command -v halo-maint-clean-safe >/dev/null 2>&1 && ok "Maintenance clean-safe ready" || warn "Maintenance clean-safe missing"

section "DOCKER NODE"

[ "$DOCKER_STATE" = "active" ] && ok "Docker active" || err "Docker is $DOCKER_STATE"

if [ "${CONTAINER_COUNT:-0}" -ge 3 ]; then
  ok "Core Docker services running"
else
  warn "Less than 3 Docker containers running"
fi

section "NAS POLICY"

if [ "$NAS_MODE" = "MOUNTED" ]; then
  ok "NAS mount detected"
else
  ok "NAS standby-safe"
fi

section "OVERALL"

if [ "$ERR" -gt 0 ]; then
  OVERALL="ERROR"
elif [ "$WARN" -gt 0 ]; then
  OVERALL="WARNING"
else
  OVERALL="GREEN"
fi

if [ "$COMPACT" -eq 1 ]; then
  echo "HALO_AGENTS=$OVERALL | host=$HOST | fire=$FIRE_TIMER | gateway=$GATEWAY_STATE | docker=$DOCKER_STATE | containers=$CONTAINER_COUNT | nas=$NAS_MODE | warnings=$WARN | errors=$ERR"
else
  echo "Overall: $OVERALL"
  echo "OK: $OK | WARNING: $WARN | ERROR: $ERR"
fi

exit 0
