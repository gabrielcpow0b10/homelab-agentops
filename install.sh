#!/usr/bin/env bash
set -euo pipefail

# HomeLab AgentOps - public/sanitized installer
# This installer does not install private production services.
# It prepares local helper commands for the public toolkit.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

ln -sf "$REPO_DIR/scripts/halo-doctor.sh" "$BIN_DIR/halo-doctor"
ln -sf "$REPO_DIR/scripts/halo-security-scan.sh" "$BIN_DIR/halo-security-scan"
ln -sf "$REPO_DIR/scripts/halo-status.sh" "$BIN_DIR/halo-status"
ln -sf "$REPO_DIR/scripts/halo-backup-dryrun.sh" "$BIN_DIR/halo-backup-dryrun"

chmod +x "$REPO_DIR/scripts/halo-doctor.sh"
chmod +x "$REPO_DIR/scripts/halo-security-scan.sh"
chmod +x "$REPO_DIR/scripts/halo-status.sh"
chmod +x "$REPO_DIR/scripts/halo-backup-dryrun.sh"

echo "HomeLab AgentOps public toolkit installed."
echo ""
echo "Commands added to: $BIN_DIR"
echo ""
echo "Try:"
echo "  halo-doctor"
echo "  halo-security-scan"
echo "  halo-status"
echo "  halo-backup-dryrun"
echo ""
echo "If commands are not found, add this to your shell profile:"
echo "  export PATH=\"$HOME/.local/bin:\$PATH\""
