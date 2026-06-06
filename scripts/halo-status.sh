#!/usr/bin/env bash
set -u

status="GREEN"
warnings=0

ok() {
  echo "[OK] $1"
}

warn() {
  echo "[WARN] $1"
  status="WARN"
  warnings=$((warnings + 1))
}

repo_root() {
  if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
  else
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
  fi
}

ROOT="$(repo_root)"

echo "HomeLab AgentOps Public Status"
echo "=============================="
echo "Time: $(date)"
echo "Repository: $(basename "$ROOT")"
echo

echo "== System =="
echo "OS: $(uname -s 2>/dev/null || echo N/A)"
echo "Kernel: $(uname -r 2>/dev/null || echo N/A)"
echo "Architecture: $(uname -m 2>/dev/null || echo N/A)"
echo

echo "== Disk =="
if command -v df >/dev/null 2>&1; then
  df -h "$ROOT" | tail -n 1
  ok "Disk check completed"
else
  warn "df command not available"
fi
echo

echo "== Memory =="
if command -v free >/dev/null 2>&1; then
  free -h | grep -E "Mem:|Swap:" || true
  ok "Linux memory check completed"
elif command -v vm_stat >/dev/null 2>&1; then
  vm_stat | head -8
  ok "macOS memory check completed"
else
  echo "Memory check skipped: no supported command found"
fi
echo

echo "== Docker =="
if command -v docker >/dev/null 2>&1; then
  echo "Docker binary: found"
  if docker info >/dev/null 2>&1; then
    ok "Docker daemon reachable"
  else
    echo "Docker daemon not reachable. This is acceptable for a public toolkit test."
  fi
else
  echo "Docker binary: not found"
  echo "Docker is optional for this public toolkit."
fi
echo

echo "== systemd =="
if command -v systemctl >/dev/null 2>&1; then
  echo "systemd: available"
  systemctl is-system-running 2>/dev/null || true
else
  echo "systemd: not available on this platform"
  echo "This is expected on macOS or non-systemd systems."
fi
echo

echo "== Tailscale Optional Check =="
if command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale binary: found"
  tailscale ip -4 2>/dev/null || echo "Tailscale installed but no IPv4 returned."
else
  echo "Tailscale binary: not found"
  echo "Tailscale is optional for this public toolkit."
fi
echo

echo "== NAS Optional Check =="
if [ -n "${HALO_NAS_PATH:-}" ]; then
  echo "HALO_NAS_PATH is set."
  if command -v mountpoint >/dev/null 2>&1; then
    if mountpoint -q "$HALO_NAS_PATH"; then
      ok "NAS path appears mounted"
    else
      warn "HALO_NAS_PATH set but not mounted"
    fi
  else
    echo "mountpoint command not available; skipping mount validation"
  fi
else
  echo "HALO_NAS_PATH not set"
  echo "NAS checks are disabled by default in the public toolkit."
fi
echo

echo "== Repository Safety =="
if [ -f "$ROOT/.env" ]; then
  warn ".env file found in repository root"
else
  ok "No .env file found in repository root"
fi

sensitive_matches="$(find "$ROOT" \
  -path "$ROOT/.git" -prune -o \
  -type f \( \
    -name "telegram.env" -o \
    -name "*.pem" -o \
    -name "id_rsa" -o \
    -name "id_ed25519" -o \
    -name "*.key" \
  \) -print 2>/dev/null || true)"

if [ -n "$sensitive_matches" ]; then
  warn "Potential credential-like files found"
else
  ok "No common private key/token files found"
fi
echo

echo "== Result =="
echo "Warnings: $warnings"
echo "HALO_PUBLIC_STATUS=$status"
