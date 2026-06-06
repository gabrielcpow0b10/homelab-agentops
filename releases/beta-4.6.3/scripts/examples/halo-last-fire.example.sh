#!/usr/bin/env bash

# Halo HomeLab AgentOps - Latest FIRE Report
# Default output is Telegram-safe.
# Full raw output is available only with --full.

MODE="${1:-safe}"
REPORT_DIR="$HOME/halo-agent/reports"

if [ ! -d "$REPORT_DIR" ]; then
  echo "HALO_LAST_FIRE=ERROR | reports folder not found"
  exit 1
fi

LATEST="$(
  find "$REPORT_DIR" -maxdepth 1 -type f \( -name "halo-report-*.txt" -o -name "halo-security-report-*.txt" \) \
    -printf "%T@ %p\n" 2>/dev/null \
    | sort -nr \
    | head -1 \
    | cut -d" " -f2-
)"

if [ -z "$LATEST" ]; then
  echo "HALO_LAST_FIRE=WARNING | no Halo FIRE report found"
  exit 0
fi

BASENAME="$(basename "$LATEST")"
MODIFIED="$(date -r "$LATEST" '+%Y-%m-%d %H:%M:%S')"
SIZE="$(du -h "$LATEST" | awk '{print $1}')"

if [ "$MODE" = "--full" ]; then
  echo "HALO LAST FIRE REPORT - FULL LOCAL VIEW"
  echo "File: $BASENAME"
  echo "Modified: $MODIFIED"
  echo "Size: $SIZE"
  echo
  tail -80 "$LATEST"
  exit 0
fi

HOST_LINE="$(grep -m1 '^Host:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
UPTIME_LINE="$(grep -m1 '^Uptime:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
TEMP_LINE="$(grep -m1 '^Temperature:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
THROTTLE_LINE="$(grep -m1 '^Throttling:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
DOCKER_LINE="$(grep -m1 '^Docker service:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
TAILSCALE_LINE="$(grep -m1 '^Tailscale:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
WARN_LINE="$(grep -m1 '^Warnings:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
FINAL_LINE="$(grep -m1 'FINAL STATUS\|Final status\|STATUS:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"

echo "HALO_LAST_FIRE=OK"
echo "file=$BASENAME"
echo "modified=$MODIFIED"
echo "size=$SIZE"

[ -n "$HOST_LINE" ] && echo "$HOST_LINE"
[ -n "$UPTIME_LINE" ] && echo "$UPTIME_LINE"
[ -n "$TEMP_LINE" ] && echo "$TEMP_LINE"
[ -n "$THROTTLE_LINE" ] && echo "$THROTTLE_LINE"
[ -n "$DOCKER_LINE" ] && echo "$DOCKER_LINE"
[ -n "$TAILSCALE_LINE" ] && echo "$TAILSCALE_LINE"
[ -n "$WARN_LINE" ] && echo "$WARN_LINE"
[ -n "$FINAL_LINE" ] && echo "$FINAL_LINE"

echo "Ports/IP details: hidden in Telegram-safe mode"
echo "Full local view: halo-last-fire --full"

exit 0
