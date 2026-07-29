#!/usr/bin/env bash
set -u

SCRIPT_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
  pwd
)"

read_public_version() {
  local version

  version="$(
    sed -n \
      's/^\*\*Current public release:\*\* \(v[0-9][0-9.]*\).*/\1/p' \
      "$SCRIPT_ROOT/README.md" 2>/dev/null |
    head -1 ||
    true
  )"

  printf '%s\n' "${version:-unknown}"
}

usage() {
  cat <<'EOF'
Usage: halo-status [--json | --report-out ABSOLUTE_PATH | --help | --version]

Options:
  --json                       Print public-safe JSON output.
  --report-out ABSOLUTE_PATH   Write a public-safe runtime report.
  -h, --help                   Show this help message.
  --version                    Show the public release version.
EOF
}

print_version() {
  printf 'halo-status %s\n' "$(read_public_version)"
}

OUTPUT_MODE="human"
REPORT_OUT=""

if [ "$#" -eq 0 ]; then
  :
elif [ "$#" -eq 1 ]; then
  case "${1:-}" in
    --json)
      OUTPUT_MODE="json"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --version)
      print_version
      exit 0
      ;;
    --report-out)
      echo "Error: --report-out requires a path." >&2
      exit 2
      ;;
    *)
      echo "Error: unsupported argument: ${1:-}" >&2
      usage >&2
      exit 2
      ;;
  esac
elif [ "${1:-}" = "--report-out" ]; then
  if [ -z "${2:-}" ]; then
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
  usage >&2
  exit 2
fi

status="GREEN"
warnings=0
CURRENT_CHECK="general"

JSON_CHECK_NAMES=()
JSON_CHECK_STATUSES=()
JSON_CHECK_DETAILS=()

record_check() {
  local name="$1"
  local check_status="$2"
  local detail="$3"

  if [ "$OUTPUT_MODE" != "json" ]; then
    return 0
  fi

  JSON_CHECK_NAMES+=("$name")
  JSON_CHECK_STATUSES+=("$check_status")
  JSON_CHECK_DETAILS+=("$detail")
}

json_escape() {
  local value="${1:-}"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"

  printf '%s' "$value"
}

ok() {
  local message="$1"
  local name="${2:-$CURRENT_CHECK}"
  local detail="${3:-$message}"

  echo "[OK] $message"
  record_check "$name" "ok" "$detail"
}

warn() {
  local message="$1"
  local name="${2:-$CURRENT_CHECK}"
  local detail="${3:-$message}"

  echo "[WARN] $message"
  status="WARN"
  warnings=$((warnings + 1))
  record_check "$name" "warn" "$detail"
}

print_json() {
  local json_status="$status"
  local total="${#JSON_CHECK_NAMES[@]}"
  local index
  local comma

  if [ "$json_status" = "WARN" ]; then
    json_status="WARNING"
  fi

  printf '{\n'
  printf '  "tool": "halo-status",\n'
  printf '  "version": "%s",\n' "$(json_escape "$PUBLIC_VERSION")"
  printf '  "status": "%s",\n' "$(json_escape "$json_status")"
  printf '  "warnings": %d,\n' "$warnings"
  printf '  "checks": [\n'

  for index in "${!JSON_CHECK_NAMES[@]}"; do
    comma=","

    if [ "$index" -eq $((total - 1)) ]; then
      comma=""
    fi

    printf       '    {"name": "%s", "status": "%s", "detail": "%s"}%s\n'       "$(json_escape "${JSON_CHECK_NAMES[$index]}")"       "$(json_escape "${JSON_CHECK_STATUSES[$index]}")"       "$(json_escape "${JSON_CHECK_DETAILS[$index]}")"       "$comma"
  done

  printf '  ]\n'
  printf '}\n'
}

repo_root() {
  if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
  else
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
  fi
}

ROOT="$(repo_root)"

PUBLIC_VERSION="$(
  sed -n     's/^\*\*Current public release:\*\* \(v[0-9][0-9.]*\).*/\1/p'     "$ROOT/README.md" |
  head -1
)"

PUBLIC_VERSION="${PUBLIC_VERSION:-unknown}"

generate_report() {
echo "HomeLab AgentOps Public Status"
echo "=============================="
echo "Time: $(date)"
echo "Repository: current checkout"
echo

CURRENT_CHECK="system"
echo "== System =="
echo "OS: $(uname -s 2>/dev/null || echo N/A)"
echo "Kernel: $(uname -r 2>/dev/null || echo N/A)"
echo "Architecture: $(uname -m 2>/dev/null || echo N/A)"
record_check "system" "ok" "platform detected"
echo

CURRENT_CHECK="disk"
echo "== Disk =="
if command -v df >/dev/null 2>&1; then
  disk_usage="$(df -P "$ROOT" 2>/dev/null | awk 'NR == 2 {print $5}')"
  if [ -n "$disk_usage" ]; then
    echo "Disk usage: $disk_usage"
    ok "Disk check completed" "disk" "$disk_usage"
  else
    warn "Disk usage could not be determined" "disk" "unavailable"
  fi
else
  warn "df command not available" "disk" "command unavailable"
fi
echo

CURRENT_CHECK="memory"
echo "== Memory =="
if command -v free >/dev/null 2>&1; then
  free -h | grep -E "Mem:|Swap:" || true
  ok "Linux memory check completed" "memory" "available"
elif command -v vm_stat >/dev/null 2>&1; then
  vm_stat | head -8
  ok "macOS memory check completed" "memory" "available"
else
  echo "Memory check skipped: no supported command found"
  record_check "memory" "ok" "unsupported on this platform"
fi
echo

CURRENT_CHECK="docker"
echo "== Docker =="
if command -v docker >/dev/null 2>&1; then
  echo "Docker binary: found"
  if docker info >/dev/null 2>&1; then
    ok "Docker daemon reachable" "docker" "daemon reachable"
  else
    echo "Docker daemon not reachable. This is acceptable for a public toolkit test."
    record_check "docker" "ok" "optional daemon unavailable"
  fi
else
  echo "Docker binary: not found"
  echo "Docker is optional for this public toolkit."
  record_check "docker" "ok" "optional binary unavailable"
fi
echo

CURRENT_CHECK="systemd"
echo "== systemd =="
if command -v systemctl >/dev/null 2>&1; then
  system_state="$(systemctl is-system-running 2>/dev/null || true)"

  case "$system_state" in
    running)
      ok "systemd state: running" "systemd" "running"
      ;;
    degraded)
      warn "systemd state: degraded" "systemd" "degraded"
      ;;
    *)
      warn "systemd state: ${system_state:-unknown}" "systemd" "${system_state:-unknown}"
      ;;
  esac
else
  echo "systemd: not available on this platform"
  echo "This is expected on macOS or non-systemd systems."
  record_check "systemd" "ok" "not available on this platform"
fi
echo

CURRENT_CHECK="tailscale"
echo "== Tailscale Optional Check =="
if command -v tailscale >/dev/null 2>&1; then
  if tailscale ip -4 >/dev/null 2>&1; then
    ok "Tailscale IPv4 is available" "tailscale" "available"
  else
    warn "Tailscale is installed but no IPv4 is available" "tailscale" "IPv4 unavailable"
  fi
else
  echo "Tailscale binary: not found"
  echo "Tailscale is optional for this public toolkit."
  record_check "tailscale" "ok" "optional binary unavailable"
fi
echo

CURRENT_CHECK="nas"
echo "== NAS Optional Check =="
NAS_MOUNT="${HALO_NAS_MOUNT:-}"

if [ -n "$NAS_MOUNT" ]; then
  echo "HALO_NAS_MOUNT is set."
  if command -v mountpoint >/dev/null 2>&1; then
    if mountpoint -q "$NAS_MOUNT"; then
      ok "NAS path appears mounted" "nas" "mounted"
    else
      warn "HALO_NAS_MOUNT set but not mounted" "nas" "configured but not mounted"
    fi
  else
    echo "mountpoint command not available; skipping mount validation"
    record_check "nas" "ok" "validation command unavailable"
  fi
else
  echo "HALO_NAS_MOUNT not set"
  echo "NAS checks are disabled by default in the public toolkit."
  record_check "nas" "ok" "disabled"
fi
echo

CURRENT_CHECK="repository_safety"
echo "== Repository Safety =="
if [ -f "$ROOT/.env" ]; then
  warn ".env file found in repository root" "environment_file" "present"
else
  ok "No .env file found in repository root" "environment_file" "absent"
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
  warn "Potential credential-like files found" "credential_files" "review required"
else
  ok "No common credential-like files found" "credential_files" "none detected"
fi
echo

echo "== Result =="
echo "Warnings: $warnings"
echo "HALO_PUBLIC_STATUS=$status"
}

if [ "$OUTPUT_MODE" = "json" ]; then
  generate_report >/dev/null
  print_json
  exit 0
fi

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
