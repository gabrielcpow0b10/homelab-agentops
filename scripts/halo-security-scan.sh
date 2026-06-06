#!/usr/bin/env bash

# HomeLab AgentOps - Public Repository Security Scan
# Safe for public CI. Scans for real secret leaks, private paths,
# private network details, and forbidden runtime files.

set -u

MODE="${1:-normal}"
STRICT=0

if [ "$MODE" = "--strict" ] || [ "$MODE" = "strict" ]; then
  STRICT=1
  MODE="strict"
else
  MODE="normal"
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

echo "===== Secret assignment scan ====="
SECRET_HITS="$(
  grep -RInIE "${COMMON_GREP_EXCLUDES[@]}" "$SECRET_REGEX" . 2>/dev/null \
    | grep -Evi "$PLACEHOLDER_FILTER" || true
)"

if [ -n "$SECRET_HITS" ]; then
  echo "$SECRET_HITS"
  echo "Secret assignment scan: REVIEW REQUIRED"
  mark_fail
else
  echo "Secret assignment scan: OK"
fi

echo
echo "===== Private network scan ====="
PRIVATE_NET_HITS="$(
  grep -RInIE "${COMMON_GREP_EXCLUDES[@]}" "$PRIVATE_NET_REGEX" . 2>/dev/null || true
)"

if [ -n "$PRIVATE_NET_HITS" ]; then
  echo "$PRIVATE_NET_HITS"
  echo "Private network scan: REVIEW REQUIRED"
  mark_fail
else
  echo "Private network scan: OK"
fi

echo
echo "===== Private path scan ====="
PRIVATE_PATH_HITS="$(
  grep -RInIE "${COMMON_GREP_EXCLUDES[@]}" "$PRIVATE_PATH_REGEX" . 2>/dev/null || true
)"

if [ -n "$PRIVATE_PATH_HITS" ]; then
  echo "$PRIVATE_PATH_HITS"
  echo "Private path scan: REVIEW REQUIRED"
  mark_fail
else
  echo "Private path scan: OK"
fi

echo
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
