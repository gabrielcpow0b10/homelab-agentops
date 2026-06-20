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

## 4. Run the doctor check

    bash scripts/halo-doctor.sh

Expected result:

    Result: GREEN

## 5. Optional local install

Only run the installer after reviewing the scripts:

    bash install.sh

After install, helper commands may be available directly:

    halo-doctor
    halo-security-scan
    halo-status
    halo-backup-dryrun

## 6. Review public examples

Canonical public scripts and sanitized examples are stored under:

    scripts/
    scripts/examples/

These files are examples only. They do not expose private production runtime configuration.

## Expected Public Result

    Repository: public sanitized
    Security scan: GREEN
    Doctor check: OK
    No real secrets: OK
    No private runtime files: OK
