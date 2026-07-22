#!/usr/bin/env bash
set -euo pipefail

# HomeLab AgentOps - public/sanitized installer
# Installs local wrapper commands only.
# It does not install or manage private production services.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

install_wrapper() {
  local command_name="$1"
  local relative_script="$2"
  local source_script="$REPO_DIR/$relative_script"
  local target_command="$BIN_DIR/$command_name"
  local temporary_file

  if [ ! -f "$source_script" ]; then
    echo "ERROR: required script not found: $relative_script" >&2
    return 1
  fi

  temporary_file="$(mktemp "$BIN_DIR/.${command_name}.XXXXXX")"

  printf '#!/usr/bin/env bash\ncd %q || exit 1\nexec bash %q "$@"\n' \
    "$REPO_DIR" "$source_script" >"$temporary_file"

  chmod 0755 "$temporary_file"

  # Replace an older symlink or wrapper without modifying its target.
  rm -f -- "$target_command"
  mv -- "$temporary_file" "$target_command"

  echo "Installed: $command_name"
}

install_wrapper \
  "halo-doctor" \
  "scripts/halo-doctor.sh"

install_wrapper \
  "halo-security-scan" \
  "scripts/halo-security-scan.sh"

install_wrapper \
  "halo-status" \
  "scripts/halo-status.sh"

install_wrapper \
  "halo-backup-dryrun" \
  "scripts/halo-backup-dryrun.sh"

install_wrapper \
  "halo-quality-gate" \
  "scripts/halo-quality-gate.sh"

echo
echo "HomeLab AgentOps public toolkit installed."
echo
echo "Commands added to: $BIN_DIR"
echo
echo "Try:"
echo "  halo-doctor"
echo "  halo-security-scan --strict"
echo "  halo-status"
echo "  halo-backup-dryrun"
echo "  halo-quality-gate"
echo
echo "If commands are not found, add this to your shell profile:"
echo "  export PATH=\"$HOME/.local/bin:\$PATH\""
