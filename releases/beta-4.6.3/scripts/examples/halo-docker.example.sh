#!/usr/bin/env bash

# Halo HomeLab AgentOps - Docker Summary
# Telegram-safe. Hides ports and internal details.

DOCKER_STATE="$(systemctl is-active docker 2>/dev/null || echo unknown)"

echo "HALO_DOCKER_STATUS"
echo "host=$(hostname)"
echo "docker=$DOCKER_STATE"

if [ "$DOCKER_STATE" != "active" ]; then
  echo "overall=ERROR"
  exit 0
fi

COUNT="$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')"
echo "containers_running=$COUNT"

docker ps --format '{{.Names}}|{{.Status}}' 2>/dev/null | while IFS='|' read -r name status; do
  echo "- $name: $status"
done

if [ "${COUNT:-0}" -ge 3 ]; then
  echo "overall=GREEN"
else
  echo "overall=WARNING"
fi

echo "Ports/internal Docker details: hidden in Telegram-safe mode"
