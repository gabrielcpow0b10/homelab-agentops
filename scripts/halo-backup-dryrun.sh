#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT="$(
  CDPATH='' cd -P -- "$(dirname "${BASH_SOURCE[0]}")/.." &&
  pwd -P
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
Usage: halo-backup-dryrun [--help | --version]

Options:
  -h, --help   Show this help message.
  --version    Show the public release version.
EOF
}

print_version() {
  printf 'halo-backup-dryrun %s\n' "$(read_public_version)"
}

if [ "$#" -eq 0 ]; then
  :
elif [ "$#" -eq 1 ]; then
  case "${1:-}" in
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
  echo "Error: halo-backup-dryrun accepts at most one option." >&2
  usage >&2
  exit 2
fi

ROOT="$SCRIPT_ROOT"
SOURCE="${HALO_BACKUP_SOURCE:-.}"
TARGET="${HALO_BACKUP_TARGET:-./backup-output-example}"

echo "HomeLab AgentOps Backup Dry-Run"
echo "==============================="
echo "Mode: dry-run only"
echo "No files will be copied."
echo "Only repository files are listed."
echo "No secrets will be read."
echo

echo "== Repository Root =="
basename "$ROOT"
echo

echo "== Requested Source =="
case "$SOURCE" in
  /*) ;;
  *) SOURCE="$ROOT/$SOURCE" ;;
esac

if ! command -v realpath >/dev/null 2>&1; then
  echo "Source validation requires realpath." >&2
  exit 1
fi

if ! SOURCE="$(realpath "$SOURCE" 2>/dev/null)"; then
  echo "Source is unavailable." >&2
  exit 1
fi

case "$SOURCE/" in
  "$ROOT/"*)
    preview_path=".${SOURCE#"$ROOT"}"
    ;;
  *)
    echo "Source safety: outside repository"
    echo "Refusing to preview files outside the repository."
    echo "HALO_BACKUP_DRYRUN=REFUSED_OUTSIDE_REPO"
    echo "No files copied."
    exit 0
    ;;
esac

case "$preview_path/" in
  */.git/*)
    echo "Repository metadata is excluded from the preview."
    echo "HALO_BACKUP_DRYRUN=REFUSED_REPO_METADATA"
    exit 0
    ;;
esac

if [ ! -d "$SOURCE" ] && [ ! -f "$SOURCE" ]; then
  echo "Source is unavailable." >&2
  exit 1
fi

printf '%s\n' "$preview_path"
echo "Source safety: inside repository"
echo
echo "== Example Target =="
if [ "$TARGET" = "./backup-output-example" ]; then
  echo "./backup-output-example"
else
  echo "Custom destination configured (path hidden)"
fi
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
cd -- "$ROOT"
find "$preview_path" \
    -name ".git" -prune -o \
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
    -print | cut -c 3- | sort | sed -n '1,80p'
echo

echo "== Result =="
echo "HALO_BACKUP_DRYRUN=OK"
echo "No files copied."
echo "Dry-run completed safely."
