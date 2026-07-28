#!/usr/bin/env bash
set -u

REPORT_OUT=""

if [ "$#" -eq 0 ]; then
  :
elif [ "${1:-}" = "--report-out" ]; then
  if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
    echo "Error: --report-out requires a path." >&2
    exit 2
  fi

  if [ "$#" -gt 2 ]; then
    echo "Error: --report-out accepts exactly one path." >&2
    exit 2
  fi

  REPORT_OUT="$2"
else
  echo "Error: unsupported argument: ${1:-}" >&2
  exit 2
fi

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

generate_report() {
echo "HomeLab AgentOps Public Status"
echo "=============================="
echo "Time: $(date)"
echo "Repository: current checkout"
echo

echo "== System =="
echo "OS: $(uname -s 2>/dev/null || echo N/A)"
echo "Kernel: $(uname -r 2>/dev/null || echo N/A)"
echo "Architecture: $(uname -m 2>/dev/null || echo N/A)"
echo

echo "== Disk =="
if command -v df >/dev/null 2>&1; then
  disk_usage="$(df -P "$ROOT" 2>/dev/null | awk 'NR == 2 {print $5}')"
  if [ -n "$disk_usage" ]; then
    echo "Disk usage: $disk_usage"
    ok "Disk check completed"
  else
    warn "Disk usage could not be determined"
  fi
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
  system_state="$(systemctl is-system-running 2>/dev/null || true)"

  case "$system_state" in
    running)
      ok "systemd state: running"
      ;;
    degraded)
      warn "systemd state: degraded"
      ;;
    *)
      warn "systemd state: ${system_state:-unknown}"
      ;;
  esac
else
  echo "systemd: not available on this platform"
  echo "This is expected on macOS or non-systemd systems."
fi
echo

echo "== Tailscale Optional Check =="
if command -v tailscale >/dev/null 2>&1; then
  if tailscale ip -4 >/dev/null 2>&1; then
    ok "Tailscale IPv4 is available"
  else
    warn "Tailscale is installed but no IPv4 is available"
  fi
else
  echo "Tailscale binary: not found"
  echo "Tailscale is optional for this public toolkit."
fi
echo

echo "== NAS Optional Check =="
NAS_MOUNT="${HALO_NAS_MOUNT:-}"

if [ -n "$NAS_MOUNT" ]; then
  echo "HALO_NAS_MOUNT is set."
  if command -v mountpoint >/dev/null 2>&1; then
    if mountpoint -q "$NAS_MOUNT"; then
      ok "NAS path appears mounted"
    else
      warn "HALO_NAS_MOUNT set but not mounted"
    fi
  else
    echo "mountpoint command not available; skipping mount validation"
  fi
else
  echo "HALO_NAS_MOUNT not set"
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
  ok "No common credential-like files found"
fi
echo

echo "== Result =="
echo "Warnings: $warnings"
echo "HALO_PUBLIC_STATUS=$status"
}

if [ -z "$REPORT_OUT" ]; then
  generate_report
  exit 0
fi

case "$REPORT_OUT" in
  /*)
    ;;
  *)
    echo "Error: --report-out requires an absolute path." >&2
    exit 2
    ;;
esac

if [ -L "$REPORT_OUT" ]; then
  echo "Error: --report-out cannot write through a symbolic link." >&2
  exit 2
fi

report_dir="$(dirname "$REPORT_OUT")"

if [ ! -d "$report_dir" ]; then
  echo "Error: report destination directory does not exist." >&2
  exit 2
fi

if [ ! -w "$report_dir" ]; then
  echo "Error: report destination directory is not writable." >&2
  exit 2
fi

report_tmp="$(mktemp "$report_dir/.halo-status.XXXXXX")"

cleanup_report() {
  rm -f "$report_tmp"
}

trap cleanup_report EXIT INT TERM

generate_report >"$report_tmp"

report_bytes="$(wc -c <"$report_tmp" | tr -d ' ')"

if [ "$report_bytes" -ge 65536 ]; then
  echo "Error: generated runtime report exceeds the 64 KB limit." >&2
  exit 1
fi

blocked_report_markers="$(
  printf '%s' \
    '(/Users/|~/\.ssh|192\.168\.|10\.0\.|172\.16\.|100\.|localhost|0\.0\.0\.0|' \
    'pass''word|to''ken|sec''ret|api''_key|api''key|BEGIN PRIVATE'' KEY)'
)"

if grep -qiE "$blocked_report_markers" "$report_tmp"; then
  echo "Error: generated runtime report failed the public-safe marker check." >&2
  exit 1
fi

mv -f "$report_tmp" "$REPORT_OUT"
trap - EXIT INT TERM

echo "HALO_RUNTIME_REPORT_WRITTEN=OK"
