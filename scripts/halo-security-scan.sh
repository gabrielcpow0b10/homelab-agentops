#!/usr/bin/env bash
set -euo pipefail

# HomeLab AgentOps - public repository safety scan
# Run this before every public commit/push.

echo "== HomeLab AgentOps Security Scan =="

STATUS=0

echo
 echo "Checking for suspicious secret patterns..."
if grep -RniE "BOT_TOKEN=|CHAT_ID=|PASSWORD=|TOKEN=|SECRET=|API_KEY=|OPENAI_API_KEY=|GITHUB_TOKEN=|ghp_|sk-|xoxb-|BEGIN .*PRIVATE|PRIVATE KEY|192\.168\.|100\.[0-9]+\." . \
  --exclude-dir=.git \
  --exclude='.env.example'; then
  echo "Potential sensitive pattern found. Review before publishing."
  STATUS=1
else
  echo "OK: no obvious secret patterns found."
fi

echo
 echo "Checking for forbidden public file types..."
FORBIDDEN=$(find . -type f \( \
  -name "*.env" -o \
  -name ".env" -o \
  -name "*.tar.gz" -o \
  -name "*.zip" -o \
  -name "*.log" -o \
  -name "*.key" -o \
  -name "*.pem" -o \
  -name "*.p12" \
\) 2>/dev/null | grep -v '^./.env.example$' || true)

if [ -n "$FORBIDDEN" ]; then
  echo "$FORBIDDEN"
  echo "Forbidden file pattern found. Review before publishing."
  STATUS=1
else
  echo "OK: no forbidden public file patterns found."
fi

echo
if [ "$STATUS" -eq 0 ]; then
  echo "Security scan result: GREEN"
else
  echo "Security scan result: REVIEW REQUIRED"
fi

exit "$STATUS"
