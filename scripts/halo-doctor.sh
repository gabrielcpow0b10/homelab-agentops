#!/usr/bin/env bash
set -euo pipefail

OUTPUT_MODE="human"

if [ "$#" -eq 0 ]; then
  :
elif [ "$#" -eq 1 ] && [ "${1:-}" = "--json" ]; then
  OUTPUT_MODE="json"
else
  echo "Error: unsupported argument: ${1:-}" >&2
  exit 2
fi

PASS=0
WARN=0
FAIL=0
CURRENT_CHECK="general"

JSON_CHECK_NAMES=()
JSON_CHECK_STATUSES=()
JSON_CHECK_DETAILS=()

PUBLIC_VERSION="$(
  sed -n \
    's/^\*\*Current public release:\*\* \(v[0-9][0-9.]*\).*/\1/p' \
    README.md 2>/dev/null |
  head -1 ||
  true
)"

PUBLIC_VERSION="${PUBLIC_VERSION:-unknown}"

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

print_json() {
  local overall_status="$1"
  local total="${#JSON_CHECK_NAMES[@]}"
  local index
  local comma

  printf '{\n'
  printf '  "tool": "halo-doctor",\n'
  printf '  "version": "%s",\n' \
    "$(json_escape "$PUBLIC_VERSION")"
  printf '  "status": "%s",\n' \
    "$(json_escape "$overall_status")"
  printf '  "warnings": %d,\n' "$WARN"
  printf '  "checks": [\n'

  for index in "${!JSON_CHECK_NAMES[@]}"; do
    comma=","

    if [ "$index" -eq $((total - 1)) ]; then
      comma=""
    fi

    printf \
      '    {"name": "%s", "status": "%s", "detail": "%s"}%s\n' \
      "$(json_escape "${JSON_CHECK_NAMES[$index]}")" \
      "$(json_escape "${JSON_CHECK_STATUSES[$index]}")" \
      "$(json_escape "${JSON_CHECK_DETAILS[$index]}")" \
      "$comma"
  done

  printf '  ]\n'
  printf '}\n'
}

print_header() {
  if [ "$OUTPUT_MODE" != "human" ]; then
    return 0
  fi

  echo ""
  echo "========================================"
  echo " HomeLab AgentOps Doctor"
  echo "========================================"
}

section() {
  if [ "$OUTPUT_MODE" != "human" ]; then
    return 0
  fi

  echo ""
  echo "== $1 =="
}

info() {
  if [ "$OUTPUT_MODE" = "human" ]; then
    echo "[INFO] $1"
  fi
}

ok() {
  local message="$1"
  local name="${2:-$CURRENT_CHECK}"
  local detail="${3:-$message}"

  PASS=$((PASS + 1))

  if [ "$OUTPUT_MODE" = "human" ]; then
    echo "[OK] $message"
  fi

  record_check "$name" "ok" "$detail"
}

warn() {
  local message="$1"
  local name="${2:-$CURRENT_CHECK}"
  local detail="${3:-$message}"

  WARN=$((WARN + 1))

  if [ "$OUTPUT_MODE" = "human" ]; then
    echo "[WARN] $message"
  fi

  record_check "$name" "warn" "$detail"
}

fail() {
  local message="$1"
  local name="${2:-$CURRENT_CHECK}"
  local detail="${3:-$message}"

  FAIL=$((FAIL + 1))

  if [ "$OUTPUT_MODE" = "human" ]; then
    echo "[FAIL] $message"
  fi

  record_check "$name" "error" "$detail"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

load_env() {
  CURRENT_CHECK="environment"

  if [ -f ".env" ]; then
    set -a

    if [ "$OUTPUT_MODE" = "json" ]; then
      source ./.env >/dev/null 2>&1
    else
      source ./.env
    fi

    set +a

    ok \
      ".env file found locally" \
      "environment_file" \
      "present"

    if git check-ignore .env >/dev/null 2>&1; then
      ok \
        ".env is ignored by Git" \
        "environment_ignore" \
        "ignored"
    else
      fail \
        ".env exists but is NOT ignored by Git" \
        "environment_ignore" \
        "not ignored"
    fi
  else
    info ".env file not found; using public defaults"

    record_check \
      "environment_file" \
      "ok" \
      "absent"
  fi
}

check_os() {
  CURRENT_CHECK="system"
  section "System"

  if [ -f /etc/os-release ]; then
    . /etc/os-release

    ok \
      "OS detected: ${PRETTY_NAME:-unknown}" \
      "os" \
      "detected"
  else
    warn \
      "Could not detect OS from /etc/os-release" \
      "os" \
      "unavailable"
  fi

  ok \
    "Hostname: $(hostname 2>/dev/null || echo unknown)" \
    "hostname" \
    "detected"

  ok \
    "Kernel: $(uname -sr 2>/dev/null || echo unknown)" \
    "kernel" \
    "detected"
}

check_resources() {
  CURRENT_CHECK="resources"
  section "Resources"

  if command_exists free; then
    if [ "$OUTPUT_MODE" = "human" ]; then
      free -h |
        awk \
          'NR==2 {print "[INFO] Memory: used " $3 " / total " $2}'
    fi

    ok \
      "Memory information available" \
      "memory" \
      "available"
  else
    warn \
      "free command not available" \
      "memory" \
      "command unavailable"
  fi

  if command_exists df; then
    if [ "$OUTPUT_MODE" = "human" ]; then
      df -h / |
        awk \
          'NR==2 {print "[INFO] Root disk: used " $3 " / total " $2 " (" $5 ")"}'
    fi

    ok \
      "Disk information available" \
      "disk" \
      "available"
  else
    warn \
      "df command not available" \
      "disk" \
      "command unavailable"
  fi
}

check_docker() {
  CURRENT_CHECK="docker"
  section "Docker"

  if ! command_exists docker; then
    warn \
      "Docker command not found" \
      "docker_command" \
      "unavailable"
    return
  fi

  ok \
    "Docker command found" \
    "docker_command" \
    "available"

  if docker info >/dev/null 2>&1; then
    local count

    ok \
      "Docker daemon reachable" \
      "docker_daemon" \
      "reachable"

    count="$(
      docker ps -q 2>/dev/null |
        wc -l |
        tr -d ' '
    )"

    ok \
      "Running containers: ${count}" \
      "containers" \
      "$count"
  else
    warn \
      "Docker command exists, but daemon is not reachable" \
      "docker_daemon" \
      "unreachable"
  fi
}

check_systemd() {
  CURRENT_CHECK="systemd"
  section "systemd"

  if command_exists systemctl; then
    ok \
      "systemctl available" \
      "systemd" \
      "available"
  else
    warn \
      "systemctl not available" \
      "systemd" \
      "unavailable"
  fi
}

check_tailscale() {
  CURRENT_CHECK="tailscale"
  section "Private access tooling"

  if command_exists tailscale; then
    ok \
      "Tailscale command found" \
      "tailscale_command" \
      "available"

    if tailscale status >/dev/null 2>&1; then
      ok \
        "Tailscale status command works" \
        "tailscale_status" \
        "available"
    else
      warn \
        "Tailscale exists but status command failed" \
        "tailscale_status" \
        "unavailable"
    fi
  else
    warn \
      "Tailscale not found; private remote access not detected" \
      "tailscale_command" \
      "unavailable"
  fi
}

check_nas_safe() {
  CURRENT_CHECK="nas"
  section "NAS-safe mode"

  local nas_enabled="${HALO_NAS_ENABLED:-false}"
  local nas_mount="${HALO_NAS_MOUNT:-/mnt/example-nas}"

  if [ "$nas_enabled" != "true" ]; then
    ok \
      "NAS checks disabled; NAS-safe mode respected" \
      "nas" \
      "disabled"
    return
  fi

  if command_exists mountpoint &&
     mountpoint -q "$nas_mount"; then
    ok \
      "NAS mountpoint appears mounted: $nas_mount" \
      "nas" \
      "mounted"
  else
    warn \
      "NAS enabled but mountpoint is not mounted: $nas_mount" \
      "nas" \
      "configured but not mounted"
  fi
}

check_public_safety() {
  CURRENT_CHECK="public_security"
  section "Repository safety"

  if [ -f scripts/halo-security-scan.sh ]; then
    if bash scripts/halo-security-scan.sh \
      --strict \
      >/tmp/halo-doctor-security-scan.txt 2>&1; then
      ok \
        "Public security scan passed" \
        "public_security" \
        "passed"
    else
      warn \
        "Public security scan requires review. See /tmp/halo-doctor-security-scan.txt" \
        "public_security" \
        "review required"
    fi
  else
    warn \
      "Public security scan script not found" \
      "public_security" \
      "script unavailable"
  fi
}

print_summary() {
  local overall_status="GREEN"
  local result_code=0

  if [ "$FAIL" -gt 0 ]; then
    overall_status="ERROR"
    result_code=2
  elif [ "$WARN" -gt 0 ]; then
    overall_status="WARNING"
    result_code=1
  fi

  if [ "$OUTPUT_MODE" = "json" ]; then
    print_json "$overall_status"
    exit "$result_code"
  fi

  section "Summary"

  echo "Passed:  $PASS"
  echo "Warnings: $WARN"
  echo "Failed:  $FAIL"
  echo "Result: $overall_status"

  exit "$result_code"
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
print_summary
