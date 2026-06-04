#!/usr/bin/env bash
set -euo pipefail

# HomeLab AgentOps - halo-doctor
# Public/sanitized diagnostic script.
# It allows a local .env for private testing, but .env must remain ignored by Git.

PASS=0
WARN=0
FAIL=0

SECRET_PATTERN="BOT_TOKEN=|CHAT_ID=|PASSWORD=|TOKEN=|SECRET=|API_KEY=|OPENAI_API_KEY=|GITHUB_TOKEN=|ghp_[A-Za-z0-9_]+|sk-[A-Za-z0-9]|xoxb-|BEGIN .*PRIVATE|PRIVATE KEY|192\.168\.|100\.[0-9]+\."

print_header() {
  echo ""
  echo "========================================"
  echo " HomeLab AgentOps Doctor"
  echo "========================================"
}

section() {
  echo ""
  echo "== $1 =="
}

ok() {
  PASS=$((PASS + 1))
  echo "[OK] $1"
}

warn() {
  WARN=$((WARN + 1))
  echo "[WARN] $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "[FAIL] $1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

load_env() {
  if [ -f ".env" ]; then
    set -a
    # shellcheck disable=SC1091
    source ./.env
    set +a
    ok ".env file found locally"

    if git check-ignore .env >/dev/null 2>&1; then
      ok ".env is ignored by Git"
    else
      fail ".env exists but is NOT ignored by Git"
    fi
  else
    warn ".env file not found; using defaults"
  fi
}

check_os() {
  section "System"

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    ok "OS detected: ${PRETTY_NAME:-unknown}"
  else
    warn "Could not detect OS from /etc/os-release"
  fi

  ok "Hostname: $(hostname 2>/dev/null || echo unknown)"
  ok "Kernel: $(uname -sr 2>/dev/null || echo unknown)"
}

check_resources() {
  section "Resources"

  if command_exists free; then
    free -h | awk 'NR==2 {print "[INFO] Memory: used " $3 " / total " $2}'
    ok "Memory information available"
  else
    warn "free command not available"
  fi

  if command_exists df; then
    df -h / | awk 'NR==2 {print "[INFO] Root disk: used " $3 " / total " $2 " (" $5 ")"}'
    ok "Disk information available"
  else
    warn "df command not available"
  fi
}

check_docker() {
  section "Docker"

  if ! command_exists docker; then
    warn "Docker command not found"
    return
  fi

  ok "Docker command found"

  if docker info >/dev/null 2>&1; then
    ok "Docker daemon reachable"
    local count
    count=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    ok "Running containers: ${count}"
  else
    warn "Docker command exists, but daemon is not reachable"
  fi
}

check_systemd() {
  section "systemd"

  if command_exists systemctl; then
    ok "systemctl available"
  else
    warn "systemctl not available"
  fi
}

check_tailscale() {
  section "Private access tooling"

  if command_exists tailscale; then
    ok "Tailscale command found"

    if tailscale status >/dev/null 2>&1; then
      ok "Tailscale status command works"
    else
      warn "Tailscale exists but status command failed"
    fi
  else
    warn "Tailscale not found; private remote access not detected"
  fi
}

check_nas_safe() {
  section "NAS-safe mode"

  local nas_enabled="${HALO_NAS_ENABLED:-false}"
  local nas_mount="${HALO_NAS_MOUNT:-/mnt/example-nas}"

  if [ "$nas_enabled" != "true" ]; then
    ok "NAS checks disabled; NAS-safe mode respected"
    return
  fi

  if command_exists mountpoint && mountpoint -q "$nas_mount"; then
    ok "NAS mountpoint appears mounted: $nas_mount"
  else
    warn "NAS enabled but mountpoint is not mounted: $nas_mount"
  fi
}

check_public_safety() {
  section "Repository safety"

  local found_forbidden=false

  while IFS= read -r path; do
    found_forbidden=true
    echo "[WARN] Forbidden public file pattern found: $path"
  done < <(
    find . -type f \( \
      -name "*.env" -o \
      -name ".env" -o \
      -name "*.tar.gz" -o \
      -name "*.zip" -o \
      -name "*.log" -o \
      -name "*.key" -o \
      -name "*.pem" -o \
      -name "*.p12" \
    \) 2>/dev/null \
      | grep -v '^./.env.example$' \
      | grep -v '^./.env$' || true
  )

  if [ "$found_forbidden" = true ]; then
    warn "Review forbidden file patterns before publishing"
  else
    ok "No forbidden public file patterns found"
  fi

  if grep -RniE "$SECRET_PATTERN" . \
    --exclude-dir=.git \
    --exclude='.env.example' \
    --exclude='.env' \
    --exclude='SECURITY.md' \
    --exclude='README.md' \
    --exclude='ARCHITECTURE.md' \
    --exclude='halo-security-scan.sh' \
    --exclude='halo-doctor.sh' \
    >/tmp/halo-doctor-secret-scan.txt 2>/dev/null; then
    warn "Potential sensitive pattern found. Review /tmp/halo-doctor-secret-scan.txt"
  else
    ok "No obvious secret patterns found"
  fi
}

summary() {
  section "Summary"

  echo "Passed:  $PASS"
  echo "Warnings: $WARN"
  echo "Failed:  $FAIL"

  if [ "$FAIL" -gt 0 ]; then
    echo "Result: ERROR"
    exit 2
  elif [ "$WARN" -gt 0 ]; then
    echo "Result: WARNING"
    exit 1
  else
    echo "Result: GREEN"
  fi
}

print_header
load_env
check_os
check_resources
check_docker
check_systemd
check_tailscale
check_nas_safe
check_public_safety
summary
