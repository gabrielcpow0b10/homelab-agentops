# Changelog

All notable public/sanitized changes to this repository will be documented here.

This changelog only tracks the public GitHub version. It does not expose private operational logs, private reports, real backups, secrets, or internal production configuration.

---

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
