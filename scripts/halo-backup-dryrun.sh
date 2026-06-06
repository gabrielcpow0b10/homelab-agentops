#!/usr/bin/env bash
set -u

repo_root() {
  if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
  else
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
  fi
}

ROOT="$(repo_root)"
SOURCE="${HALO_BACKUP_SOURCE:-$ROOT}"
TARGET="${HALO_BACKUP_TARGET:-./backup-output-example}"

display_path() {
  case "$1" in
    "$ROOT")
      basename "$ROOT"
      ;;
    "$ROOT"/*)
      printf '%s\n' "${1#$ROOT/}"
      ;;
    *)
      echo "outside-repository"
      ;;
  esac
}

echo "HomeLab AgentOps Backup Dry-Run"
echo "==============================="
echo "Mode: dry-run only"
echo "No files will be copied."
echo "No private paths will be touched."
echo "No secrets will be read."
echo

echo "== Repository Root =="
display_path "$ROOT"
echo

echo "== Requested Source =="
display_path "$SOURCE"
echo

case "$SOURCE" in
  "$ROOT"|"$ROOT"/*)
    echo "Source safety: inside repository"
    ;;
  *)
    echo "Source safety: outside repository"
    echo "Refusing to preview files outside the repository by default."
    echo "Set HALO_BACKUP_ALLOW_OUTSIDE_REPO=1 only in a controlled private environment."
    echo
    echo "== Result =="
    echo "HALO_BACKUP_DRYRUN=REFUSED_OUTSIDE_REPO"
    echo "No files copied."
    exit 0
    ;;
esac

echo
echo "== Example Target =="
echo "$TARGET"
echo

echo "== What would be included =="
echo "- Public documentation"
echo "- Public scripts"
echo "- Sanitized examples"
echo "- Public runbooks"
echo "- Public configuration templates"
echo

echo "== What must be excluded =="
echo "- .env files"
echo "- telegram.env"
echo "- bot tokens"
echo "- chat IDs"
echo "- SSH keys"
echo "- NAS credentials"
echo "- private screenshots"
echo "- production logs"
echo "- real backup archives"
echo "- private infrastructure maps"
echo

echo "== Public-Safe Repository Preview =="
if command -v find >/dev/null 2>&1; then
  find "$SOURCE" \
    -path "$SOURCE/.git" -prune -o \
    -type f \
    ! -name ".env" \
    ! -name ".env.*" \
    ! -name "telegram.env" \
    ! -name "*.pem" \
    ! -name "*.key" \
    ! -name "id_rsa" \
    ! -name "id_ed25519" \
    ! -name "*.tar" \
    ! -name "*.tar.gz" \
    ! -name "*.zip" \
    ! -name "*.log" \
    -print 2>/dev/null | sed "s|^$ROOT/||" | sort | head -80
else
  echo "find command not available"
fi
echo

echo "== Result =="
echo "HALO_BACKUP_DRYRUN=OK"
echo "No files copied."
echo "Dry-run completed safely."
