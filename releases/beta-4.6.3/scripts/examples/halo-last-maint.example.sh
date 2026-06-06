#!/usr/bin/env bash

# Halo HomeLab AgentOps - Latest Maintenance Report
# Default output is Telegram-safe.
# Full raw output is available only with --full.

MODE="${1:-safe}"
REPORT_DIR="$HOME/halo-maintenance-agent/reports"

if [ ! -d "$REPORT_DIR" ]; then
  echo "HALO_LAST_MAINT=ERROR | reports folder not found"
  exit 1
fi

LATEST="$(
  find "$REPORT_DIR" -maxdepth 1 -type f -name "maintenance_report*.txt" \
    -printf "%T@ %p\n" 2>/dev/null \
    | sort -nr \
    | head -1 \
    | cut -d" " -f2-
)"

if [ -z "$LATEST" ]; then
  echo "HALO_LAST_MAINT=WARNING | no maintenance report found"
  exit 0
fi

BASENAME="$(basename "$LATEST")"
MODIFIED="$(date -r "$LATEST" '+%Y-%m-%d %H:%M:%S')"
SIZE="$(du -h "$LATEST" | awk '{print $1}')"

if [ "$MODE" = "--full" ]; then
  echo "HALO LAST MAINTENANCE REPORT - FULL LOCAL VIEW"
  echo "File: $BASENAME"
  echo "Modified: $MODIFIED"
  echo "Size: $SIZE"
  echo
  tail -100 "$LATEST"
  exit 0
fi

HOST_LINE="$(grep -m1 '^Host:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
MODE_LINE="$(grep -m1 '^Mode:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
PROFILE_LINE="$(grep -m1 '^Profile:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
STATUS_LINE="$(grep -m1 -Ei '^(Overall|Status|Final status):' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
WARN_LINE="$(grep -m1 -Ei '^Warnings:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"
ERR_LINE="$(grep -m1 -Ei '^Errors:' "$LATEST" 2>/dev/null | sed 's/[[:space:]]*$//')"

echo "HALO_LAST_MAINT=OK"
echo "file=$BASENAME"
echo "modified=$MODIFIED"
echo "size=$SIZE"

[ -n "$HOST_LINE" ] && echo "$HOST_LINE"
[ -n "$MODE_LINE" ] && echo "$MODE_LINE"
[ -n "$PROFILE_LINE" ] && echo "$PROFILE_LINE"
[ -n "$STATUS_LINE" ] && echo "$STATUS_LINE"
[ -n "$WARN_LINE" ] && echo "$WARN_LINE"
[ -n "$ERR_LINE" ] && echo "$ERR_LINE"

echo "Safety: manual maintenance only"
echo "Clean-safe: safe-trash only"
echo "NAS/Docker/internal paths: hidden in Telegram-safe mode"
echo "Full local view: halo-last-maint --full"

exit 0
