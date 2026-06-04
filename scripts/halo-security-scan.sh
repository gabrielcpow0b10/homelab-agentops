#!/usr/bin/env bash
set -euo pipefail

echo "== HomeLab AgentOps Security Scan =="

STATUS=0

echo ""
echo "Checking local .env safety..."

if [ -f ".env" ]; then
  if git check-ignore .env >/dev/null 2>&1; then
    echo "OK: local .env exists and is ignored by Git."
  else
    echo "ERROR: .env exists but is NOT ignored by Git."
    STATUS=1
  fi
else
  echo "OK: no local .env file found."
fi

echo ""
echo "Checking for suspicious secret patterns..."

if grep -RniE "BOT_TOKEN=|CHAT_ID=|PASSWORD=|TOKEN=|SECRET=|API_KEY=|OPENAI_API_KEY=|GITHUB_TOKEN=|ghp_[A-Za-z0-9_]+|sk-[A-Za-z0-9]|xoxb-|BEGIN .*PRIVATE|PRIVATE KEY|192\.168\.|100\.[0-9]+\." . \
  --exclude-dir=.git \
  --exclude='.env.example' \
  --exclude='.env' \
  --exclude='SECURITY.md' \
  --exclude='README.md' \
  --exclude='ARCHITECTURE.md' \
  --exclude='halo-security-scan.sh' \
  --exclude='halo-doctor.sh'; then
  echo "Potential sensitive pattern found. Review before publishing."
  STATUS=1
else
  echo "OK: no obvious secret patterns found."
fi

echo ""
echo "Checking for forbidden public file types..."

FORBIDDEN=$(
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

if [ -n "$FORBIDDEN" ]; then
  echo "$FORBIDDEN"
  echo "Forbidden file pattern found. Review before publishing."
  STATUS=1
else
  echo "OK: no forbidden public file patterns found."
fi

echo ""
if [ "$STATUS" -eq 0 ]; then
  echo "Security scan result: GREEN"
else
  echo "Security scan result: REVIEW REQUIRED"
fi

exit "$STATUS"
