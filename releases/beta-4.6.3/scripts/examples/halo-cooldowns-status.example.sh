#!/usr/bin/env bash

# Halo HomeLab AgentOps - Cooldowns Status
# Telegram-safe. Shows active cooldown state without secrets.

STATE_DIR="$HOME/halo-telegram-gateway/state/cooldowns"
NOW="$(date +%s)"

echo "HALO_COOLDOWNS_STATUS"
echo "host=$(hostname)"
echo "state_dir=found"

if [ ! -d "$STATE_DIR" ]; then
  echo "cooldowns=none"
  echo "overall=GREEN"
  exit 0
fi

COUNT="$(find "$STATE_DIR" -type f -name "*.last" 2>/dev/null | wc -l | tr -d ' ')"
echo "tracked_commands=$COUNT"

if [ "$COUNT" -eq 0 ]; then
  echo "cooldowns=none"
  echo "overall=GREEN"
  exit 0
fi

echo
echo "Recent command cooldown stamps:"

find "$STATE_DIR" -type f -name "*.last" -printf "%T@ %p\n" 2>/dev/null \
  | sort -nr \
  | head -10 \
  | while read -r _ file; do
      name="$(basename "$file" .last)"
      last="$(cat "$file" 2>/dev/null || echo 0)"
      age=$((NOW - last))
      echo "- /$name: last_used=${age}s ago"
    done

echo
echo "overall=GREEN"
echo "Security: local cooldown state only / no secrets"
