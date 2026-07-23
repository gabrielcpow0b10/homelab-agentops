# Changelog

All notable public and sanitized repository changes are documented here.

This changelog tracks the public GitHub `v0.x` release line. Private operational milestones, logs, credentials, reports, backups, and runtime details remain outside this repository.

---

## Unreleased

---

## v0.5.2 - Public Quality Gate

### Added

- Added `scripts/halo-quality-gate.sh` as the canonical blocking repository validation command.
- Added `.github/workflows/quality-gate.yml` to run the public quality gate on pull requests, pushes to `main`, and manual workflow runs.

### Changed

- Replaced installer symlinks with portable local wrappers that invoke repository scripts through Bash and work from any current directory.
- Added `halo-quality-gate` to the public installer commands.

- Removed the legacy `releases/beta-4.6.3/` archive from the canonical `main` tree to preserve one clear public `v0.x` release line.
- Updated current-public-release references to `v0.5.2`.
- Preserved historical sanitized-export traceability in Git history and the `beta-4-6-3-public-sanitized` archival branch.

---

## v0.5.1 - Public Toolkit Alignment

### Changed

- Aligned public documentation and runtime behavior with the v0.5 Public Toolkit Foundation.
- Updated `install.sh` to install the canonical public commands:
  - `halo-doctor`
  - `halo-security-scan`
  - `halo-status`
  - `halo-backup-dryrun`
- Clarified that internal milestone labels and historical sanitized exports do not define public GitHub release versions.
- Sanitized `halo-status.sh` runtime output to avoid private network, mount, path, and local checkout-name details.
- Updated `halo-status.sh` to report a warning when local systemd health is degraded instead of returning a false GREEN status.

---

## v0.5 - Public Toolkit Foundation

### Added

- Added `halo-status.sh` for public-safe status reporting.
- Added `halo-backup-dryrun.sh` for a non-destructive backup workflow check.
- Added GitHub Actions shell syntax validation.
- Added `CONTRIBUTING.md`.
- Expanded sanitized demo output documentation.
- Added public toolkit foundation documentation.

### Status

- Released and tagged as `v0.5`.

---

## v0.4.2 Doctor Output Consistency

### Fixed

- Aligned `halo-doctor.sh` with the strict public security scan.
- Removed false-positive documentation warnings from the doctor result.
- Updated expected public output to use `Result: GREEN`.

### Verified

- `halo-doctor.sh`: GREEN
- Normal security scan: GREEN
- Strict security scan: GREEN



## v0.4 Security Hardening

### Added

- Added `halo-doctor.sh` as a public-safe HomeLab diagnostic script.
- Added `halo-security-scan.sh` for pre-publish repository safety checks.
- Added `.env.example` for safe local configuration examples.
- Added `install.sh` to install local helper commands into `~/.local/bin`.
- Added GitHub Actions workflow to run the public security scan on push and pull request.
- Added stronger public documentation for NAS-safe monitoring, Telegram gateway design, backup/restore model, and rack command center concepts.

### Security

- Strengthened `.gitignore` to block real `.env` files, credentials, private keys, logs, backups, archives, local state, and private reports.
- Improved the public/private boundary so the GitHub repository remains sanitized.
- Kept real tokens, private logs, internal paths, operational backups, and production configuration out of the public repository.

### Status

- Public toolkit is now functional, sanitized, and automatically checked through GitHub Actions.

---

## v0.2 Public / Sanitized

### Added

- Improved the main `README.md` with a stronger professional structure.
- Added clearer architecture-at-a-glance documentation.
- Added public/private boundary explanation.
- Added operational module descriptions for monitoring, documentation, maintenance, and Telegram control.
- Added repository structure section.
- Added stronger safety model language.
- Added future roadmap toward local AI agents.

### Security

- Reconfirmed that the public repository is documentation-first and sanitized.
- Reconfirmed that production secrets, `.env` files, tokens, logs, private screenshots, and real backup archives must remain private.

---

## v0.1 Public / Sanitized

### Added

- Initial public repository foundation.
- Public sanitized `README.md`.
- Public architecture documentation.
- Public backup runbook.
- Public recovery runbook.
- Public roadmap.
- Public security model.
- Sanitized backup example script.

### Status

- Repository created and pushed to GitHub as the first public HomeLab AgentOps milestone.

## Historical Archive: Beta 4.6.3 - Public Sanitized Export

Originally added a GitHub-ready sanitized public export under `releases/beta-4.6.3/`.

Historical note: this archive was later removed from the canonical `main` tree to preserve a single public `v0.x` release line. Its original content remains available in Git history and the `beta-4-6-3-public-sanitized` archival branch.

This export documents:
- Agent Layer upgrade
- Telegram Gateway hardening
- Automatic log rotation
- Stable backup and restore verification
- Public sanitization checks

Public safety checks completed:
- No real secrets
- No private IP/Tailscale details
- No private paths/usernames
- No forbidden runtime files
- Shell examples syntax checked
- Telegram Gateway Python example compile checked

## v0.4.1 - Public Security Polish

Improved the public repository polish after the historical Beta 4.6.3 sanitized export.

### Added

- Expanded `QUICKSTART.md`
- Added `VERSIONING.md`
- Added `docs/public-security-hardening.md`
- Improved `docs/demo-output.md`
- Added strict mode to `scripts/halo-security-scan.sh`

### Security

- Added normal and strict public security scan modes.
- Hardened GitHub Actions with read-only repository permissions.
- Confirmed public/private versioning separation.
- Kept the repository focused on sanitized documentation and examples only.
