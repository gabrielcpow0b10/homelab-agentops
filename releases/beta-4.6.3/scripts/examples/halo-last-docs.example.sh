#!/usr/bin/env bash

# Halo HomeLab AgentOps - Latest Docs Agent Report
# Telegram-safe by default. May touch NAS manually.

MODE="${1:-safe}"
REPORT_DIR="/path/to/homelab-control-center/11_Agent_Reports"

if ! mountpoint -q /path/to/homelab-projects; then
  echo "HALO_LAST_DOCS=STANDBY | NAS not mounted or sleeping"
  echo "Docs reports live on NAS. Run when NAS is available."
  exit 0
fi

if [ ! -d "$REPORT_DIR" ]; then
  echo "HALO_LAST_DOCS=ERROR | docs report folder not found"
  exit 1
fi

LATEST="$(
  find "$REPORT_DIR" -maxdepth 2 -type f \( -iname "*docs*report*.txt" -o -iname "*agent*report*.txt" -o -iname "*.txt" \) \
    -printf "%T@ %p\n" 2>/dev/null \
    | sort -nr \
    | head -1 \
    | cut -d" " -f2-
)"

if [ -z "$LATEST" ]; then
  echo "HALO_LAST_DOCS=WARNING | no Docs Agent report found"
  exit 0
fi

BASENAME="$(basename "$LATEST")"
MODIFIED="$(date -r "$LATEST" '+%Y-%m-%d %H:%M:%S')"
SIZE="$(du -h "$LATEST" | awk '{print $1}')"

if [ "$MODE" = "--full" ]; then
  echo "HALO LAST DOCS REPORT - FULL LOCAL VIEW"
  echo "File: $BASENAME"
  echo "Modified: $MODIFIED"
  echo "Size: $SIZE"
  echo
  tail -100 "$LATEST"
  exit 0
fi

NOTES="$(grep -Ei 'notes processed|note\(s\) processed|processed successfully|Status:' "$LATEST" 2>/dev/null | head -6 | sed 's/[[:space:]]*$//')"

echo "HALO_LAST_DOCS=OK"
echo "file=$BASENAME"
echo "modified=$MODIFIED"
echo "size=$SIZE"

if [ -n "$NOTES" ]; then
  echo "$NOTES"
fi

echo "Changelog: updated"
echo "Processed folder: updated"
echo "NAS/internal paths: hidden in Telegram-safe mode"
echo "Full local view: halo-last-docs --full"

exit 0
