# Quickstart

This repository is a public, sanitized HomeLab AgentOps toolkit.

It demonstrates the operational model, safety controls, and public examples of a private self-hosted HomeLab system without exposing runtime secrets or private infrastructure details.

## 1. Clone the repository

    git clone https://github.com/gabrielcpow0b10/homelab-agentops.git
    cd homelab-agentops

## 2. Review the public safety boundary

This repository should not contain:

- Real environment files
- Telegram bot tokens
- Real chat IDs
- Private keys
- NAS credentials
- Raw logs
- Backup archives
- Private IP or Tailscale details
- Private screenshots

Review:

    cat SECURITY.md
    cat docs/public-security-hardening.md

## 3. Run the public security scan

Normal mode:

    bash scripts/halo-security-scan.sh

Strict mode:

    bash scripts/halo-security-scan.sh --strict

Expected result:

    Security scan result: GREEN

## 4. Run the public quality gate

    bash scripts/halo-quality-gate.sh

Expected result:

    HALO_QUALITY_GATE=GREEN

The quality gate validates required public files, shell syntax, Git whitespace, current-version consistency, the canonical public tree, the strict security scan, and the backup dry-run.

## 5. Run optional host diagnostics

    bash scripts/halo-doctor.sh
    bash scripts/halo-status.sh

Host diagnostics are intentionally non-blocking because local system conditions can produce a safe warning without indicating a repository failure.

## 6. Optional local install

Only run the installer after reviewing the scripts:

    bash install.sh

After install, helper commands may be available directly:

    halo-doctor
    halo-security-scan
    halo-status
    halo-backup-dryrun
    halo-quality-gate

## 7. Review public examples

Canonical public scripts and sanitized examples are stored under:

    scripts/
    scripts/examples/

These files are examples only. They do not expose private production runtime configuration.

## Expected Public Result

    Repository: public sanitized
    Quality gate: GREEN
    Security scan: GREEN
    Doctor check: GREEN
    No real secrets: OK
    No private runtime files: OK
