#!/usr/bin/env bash

# HomeLab AgentOps - Public Repository Security Scan
# Safe for public CI. Scans for real secret leaks, private paths,
# private network details, and forbidden runtime files.

set -euo pipefail

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
Usage: halo-security-scan [--strict | --help | --version]

Options:
  --strict     Run the extended strict public-security scan.
  -h, --help   Show this help message.
  --version    Show the public release version.
EOF
}

print_version() {
  printf 'halo-security-scan %s\n' "$(read_public_version)"
}

MODE="normal"
STRICT=0

if [ "$#" -eq 0 ]; then
  :
elif [ "$#" -eq 1 ]; then
  case "${1:-}" in
    --strict|strict)
      STRICT=1
      MODE="strict"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --version)
      print_version
      exit 0
      ;;
    *)
      echo "Error: unsupported argument: ${1:-}" >&2
      usage >&2
      exit 2
      ;;
  esac
else
  echo "Error: halo-security-scan accepts at most one option." >&2
  usage >&2
  exit 2
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

FAIL=0

echo "HomeLab AgentOps Public Security Scan"
echo "Mode: $MODE"
echo

mark_fail() {
  FAIL=1
}

COMMON_GREP_EXCLUDES=(
  --exclude-dir=.git
  --exclude-dir=__pycache__
  --exclude-dir=.venv
  --exclude-dir=venv
  --exclude-dir=node_modules
  --exclude='*.pyc'
  --exclude='halo-security-scan.sh'
)

PLACEHOLDER_FILTER='replace_me|replace_with|placeholder|example|dummy|changeme|your_|disabled|false|null|none|sample|public-safe'

SECRET_REGEX='(BOT_TOKEN|TELEGRAM_BOT_TOKEN|TELEGRAM_TOKEN|ALLOWED_CHAT_ID|CHAT_ID|PASSWORD|PASSWD|SECRET|API_KEY|OPENAI_API_KEY|GITHUB_TOKEN)[[:space:]]*=[[:space:]]*[^|[:space:]#]{8,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|xoxb-[A-Za-z0-9-]{20,}|BEGIN[[:space:]]+(RSA |OPENSSH |EC |DSA )?PRIVATE KEY'

PRIVATE_NET_REGEX='(^|[^0-9])(10\.[0-9]{1,3}\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|100\.[0-9]{1,3}\.)'

PRIVATE_PATH_REGEX='/home/[A-Za-z0-9._-]+|/Users/[A-Za-z0-9._-]+|/mnt/homelab|HomeLab_Control_Center'

# Keep matching content inside the filter. The public CI log only needs the
# repository-relative filename and line number to locate a finding.
scan_text() {
  local label="$1" pattern="$2" ignore_pattern="${3:-}"
  local locations

  echo "===== $label ====="
  if ! locations="$(
    { grep -rnHIE --null "${COMMON_GREP_EXCLUDES[@]}" "$pattern" . 2>/dev/null || [ "$?" -eq 1 ]; } |
      (
        shopt -s nocasematch
        while IFS= read -r -d '' file && IFS= read -r match; do
          if [[ -n "$ignore_pattern" && "${match#*:}" =~ $ignore_pattern ]]; then
            continue
          fi
          printf '%q:%s\n' "$file" "${match%%:*}"
        done
      )
  )"; then
    echo "$label: scan incomplete"
    mark_fail
  elif [ -n "$locations" ]; then
    printf '%s\n' "$locations"
    echo "$label: REVIEW REQUIRED"
    mark_fail
  else
    echo "$label: OK"
  fi
  echo
}

scan_text "Secret assignment scan" "$SECRET_REGEX" "$PLACEHOLDER_FILTER"
scan_text "Private network scan" "$PRIVATE_NET_REGEX"
scan_text "Private path scan" "$PRIVATE_PATH_REGEX"

echo "===== Forbidden runtime file scan ====="
FORBIDDEN_FILES="$(
  find . -path ./.git -prune -o -type f \( \
    -name ".env" -o \
    -name "*.env" -o \
    -name "telegram.env" -o \
    -name "*.log" -o \
    -name "*.key" -o \
    -name "*.pem" -o \
    -name "*.p12" -o \
    -name "*.tar.gz" -o \
    -name "*.zip" -o \
    -name "*.bak" -o \
    -name "*.db" -o \
    -name "*.sqlite" -o \
    -name "*.pyc" \
  \) ! -name ".env.example" ! -name "*.example.env" -print
)"

if [ -n "$FORBIDDEN_FILES" ]; then
  echo "$FORBIDDEN_FILES"
  echo "Forbidden runtime file scan: REVIEW REQUIRED"
  mark_fail
else
  echo "Forbidden runtime file scan: OK"
fi

if [ "$STRICT" -eq 1 ]; then
  echo
  echo "===== Strict mode note ====="
  echo "Strict mode scanned repository text for real-looking secrets, private paths, private network details, and forbidden runtime files."
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "Security scan result: GREEN"
  exit 0
else
  echo "Security scan result: REVIEW REQUIRED"
  exit 1
fi
