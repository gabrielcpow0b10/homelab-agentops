#!/usr/bin/env bash

# Halo HomeLab AgentOps - Overview
# Telegram-safe summary. NAS-safe.

echo "HALO_OVERVIEW"
echo "host=$(hostname)"
echo "time=$(date)"
echo

echo "===== STATUS ====="
/usr/local/bin/halo-status --compact 2>/dev/null

echo
echo "===== AGENTS ====="
/usr/local/bin/halo-agents --compact 2>/dev/null

echo
echo "===== NODE ====="
/usr/local/bin/halo-node 2>/dev/null | grep -E 'temperature=|throttling=|ram_used=|root_percent=|overall=|NAS:'

echo
echo "===== DOCKER ====="
/usr/local/bin/halo-docker 2>/dev/null | grep -E 'docker=|containers_running=|overall='

echo
echo "===== NAS ====="
/usr/local/bin/halo-nas 2>/dev/null | grep -E 'mount=|mode=|disk_scan=|folder_scan=|overall='

echo
echo "===== GATEWAY ====="
/usr/local/bin/halo-gateway-status 2>/dev/null | grep -E 'service=|enabled=|errors_seen=|overall='

echo
echo "Policy: Telegram-safe / NAS-safe / no shell / no secrets"
