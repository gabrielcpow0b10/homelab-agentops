#!/usr/bin/env bash
set -euo pipefail

# HomeLab AgentOps - public/sanitized status example
# This script is intentionally generic. It does not include private IPs,
# private paths, real credentials, or production-only logic.

print_section() {
  echo
  echo "== $1 =="
}

status_of_service() {
  local service="$1"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active "$service" 2>/dev/null || echo "unknown"
  else
    echo "systemctl-not-found"
  fi
}

print_section "Host"
hostname || true
uptime || true

print_section "Memory"
free -h || true

print_section "Disk"
df -h / || true

print_section "Docker"
if command -v docker >/dev/null 2>&1; then
  echo "Docker service: $(status_of_service docker)"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
else
  echo "Docker not installed on this system."
fi

print_section "NAS-safe monitoring note"
echo "Scheduled monitoring should avoid touching NAS paths unless intentionally running manual maintenance."

print_section "Result"
echo "Public example status check completed."
