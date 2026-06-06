#!/usr/bin/env bash

# Halo HomeLab AgentOps - Reports Summary
# Combines latest FIRE, Maintenance and Docs reports.
# /last_docs may touch NAS if NAS is mounted.

echo "HALO_REPORTS_SUMMARY"
echo "Host: $(hostname)"
echo "Time: $(date)"
echo

echo "===== FIRE ====="
/usr/local/bin/halo-last-fire 2>/dev/null | head -12

echo
echo "===== MAINTENANCE ====="
/usr/local/bin/halo-last-maint 2>/dev/null | head -12

echo
echo "===== DOCS ====="
/usr/local/bin/halo-last-docs 2>/dev/null | head -14

echo
echo "Policy: Telegram-safe summary. Full reports remain local."
