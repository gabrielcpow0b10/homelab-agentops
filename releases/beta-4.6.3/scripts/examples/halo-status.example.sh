#!/usr/bin/env bash

# Halo HomeLab AgentOps - Local Status Layer v1.1
# NAS-safe by default: does not list/read NAS folders.

MODE="${1:-normal}"
COMPACT=0

if [ "$MODE" = "--compact" ]; then
  COMPACT=1
fi

OK_COUNT=0
WARN_COUNT=0
ERROR_COUNT=0

out() {
  if [ "$COMPACT" -eq 0 ]; then
    echo "$@"
  fi
}

ok() {
  out "OK      $1"
  OK_COUNT=$((OK_COUNT + 1))
}

warn() {
  out "WARNING $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

err() {
  out "ERROR   $1"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

info() {
  out "INFO    $1"
}

section() {
  out
  out "===== $1 ====="
}

get_temp() {
  if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd measure_temp 2>/dev/null | sed "s/temp=//" || true
  elif [ -r /sys/class/thermal/thermal_zone0/temp ]; then
    awk '{printf "%.1fC\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp
  else
    echo "N/A"
  fi
}

latest_halo_report() {
  if [ -d "$HOME/halo-agent/reports" ]; then
    find "$HOME/halo-agent/reports" -maxdepth 1 -type f \( -name "halo-report-*.txt" -o -name "halo-security-report-*.txt" \) \
      -printf "%T@ %TY-%Tm-%Td %TH:%TM %p\n" 2>/dev/null \
      | sort -nr \
      | head -1 \
      | awk '{$1=""; sub(/^ /,""); print}'
  else
    echo ""
  fi
}

latest_maint_report() {
  if [ -d "$HOME/halo-maintenance-agent/reports" ]; then
    find "$HOME/halo-maintenance-agent/reports" -maxdepth 1 -type f -name "maintenance_report*.txt" \
      -printf "%T@ %TY-%Tm-%Td %TH:%M %p\n" 2>/dev/null \
      | sort -nr \
      | head -1 \
      | awk '{$1=""; sub(/^ /,""); print}'
  else
    echo ""
  fi
}

HOST="$(hostname)"
NOW="$(date)"
TEMP="$(get_temp)"

DOCKER_STATE="$(systemctl is-active docker 2>/dev/null || echo unknown)"
FIRE_TIMER="$(systemctl --user is-active halo-fire-standby.timer 2>/dev/null || echo unknown)"
GATEWAY_STATE="$(systemctl --user is-active halo-telegram-gateway.service 2>/dev/null || echo unknown)"

if command -v docker >/dev/null 2>&1; then
  CONTAINER_COUNT="$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')"
  CONTAINERS="$(docker ps --format '{{.Names}}' 2>/dev/null | paste -sd ',' - | sed 's/,/, /g')"
else
  CONTAINER_COUNT="0"
  CONTAINERS="none"
fi

if mountpoint -q /path/to/homelab-projects; then
  NAS_MODE="MOUNTED"
else
  NAS_MODE="STANDBY-SAFE"
fi

HALO_LATEST="$(latest_halo_report)"
MAINT_LATEST="$(latest_maint_report)"

out "HALO HOMELAB STATUS"
out "Host: $HOST"
out "Time: $NOW"
out "Mode: NAS-SAFE"
out "Temp: $TEMP"

section "SYSTEM"
out "$(uptime)"
free -h | awk '/^Mem:/ {print "RAM:", $3 " used / " $2 " total / " $7 " available"}' | while read -r line; do out "$line"; done
df -h / | awk 'NR==2 {print "Root disk:", $3 " used / " $2 " total / " $5 " used"}' | while read -r line; do out "$line"; done

section "DOCKER"
if [ "$DOCKER_STATE" = "active" ]; then
  ok "Docker active"
else
  err "Docker is $DOCKER_STATE"
fi

out "Containers running: $CONTAINER_COUNT"
out "Containers: ${CONTAINERS:-none}"

if [ "${CONTAINER_COUNT:-0}" -ge 3 ]; then
  ok "Expected core containers are running"
else
  warn "Less than 3 containers running"
fi

section "HALO COMMAND LAYER"
for cmd in halo-fire halo-docs halo-maint halo-maint-dryrun halo-maint-clean-safe halo-maint-weekly halo-maint-process-weekly; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd found at $(command -v "$cmd")"
  else
    err "$cmd missing"
  fi
done

section "HALO SERVICES"
if [ "$FIRE_TIMER" = "active" ]; then
  ok "halo-fire-standby.timer active"
else
  err "halo-fire-standby.timer is $FIRE_TIMER"
fi

if [ "$GATEWAY_STATE" = "active" ]; then
  ok "halo-telegram-gateway.service active"
else
  err "halo-telegram-gateway.service is $GATEWAY_STATE"
fi

section "REPORTS"
if [ -n "$HALO_LATEST" ]; then
  ok "Latest Halo report: $HALO_LATEST"
else
  warn "No Halo report found"
fi

if [ -n "$MAINT_LATEST" ]; then
  ok "Latest Maintenance report: $MAINT_LATEST"
else
  warn "No Maintenance report found"
fi

section "NAS MODE"
if [ "$NAS_MODE" = "MOUNTED" ]; then
  ok "NAS mounted"
  out "NAS policy: OPTIONAL / MOUNTED / DO NOT SCAN IN AUTO MODE"
else
  ok "NAS standby-safe"
  out "NAS policy: OPTIONAL / STANDBY-SAFE"
fi

section "TELEGRAM GATEWAY LOG"
if [ -f "$HOME/halo-telegram-gateway/logs/gateway.log" ]; then
  LAST_ERROR="$(grep -i 'error' "$HOME/halo-telegram-gateway/logs/gateway.log" | tail -1 || true)"
  if [ -n "$LAST_ERROR" ]; then
    info "Last gateway error seen, non-fatal if service is active: $LAST_ERROR"
  else
    ok "No gateway error found in gateway.log"
  fi
else
  warn "Gateway log file not found"
fi

section "OVERALL"
if [ "$ERROR_COUNT" -gt 0 ]; then
  OVERALL="ERROR"
elif [ "$WARN_COUNT" -gt 0 ]; then
  OVERALL="WARNING"
else
  OVERALL="GREEN"
fi

out "Overall: $OVERALL"
out "OK: $OK_COUNT | WARNING: $WARN_COUNT | ERROR: $ERROR_COUNT"

if [ "$COMPACT" -eq 1 ]; then
  echo "HALO_STATUS=$OVERALL | host=$HOST | temp=$TEMP | docker=$DOCKER_STATE | containers=$CONTAINER_COUNT | fire=$FIRE_TIMER | gateway=$GATEWAY_STATE | nas=$NAS_MODE | warnings=$WARN_COUNT | errors=$ERROR_COUNT"
fi

exit 0
