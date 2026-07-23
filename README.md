# HomeLab AgentOps

![Security Scan](https://github.com/gabrielcpow0b10/homelab-agentops/actions/workflows/security-scan.yml/badge.svg)
![Status](https://img.shields.io/badge/status-public%20toolkit%20preview-blue)
![Security](https://img.shields.io/badge/security-sanitized-green)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Raspberry%20Pi-lightgrey)

**Current public release:** v0.5.2 - Public Quality Gate
**Status:** Functional public toolkit for diagnostics, public-safe status reporting, backup dry runs, and safety validation
**Focus:** Monitoring, backup, recovery, automation, secure remote operations, and future local AI agents
**Author:** Gabriel Cruz

HomeLab AgentOps is a self-hosted infrastructure and operations project built to practice real-world Linux administration, Docker services, NAS-backed documentation, monitoring, backup/recovery workflows, safe automation, and private remote access.

This repository is the **public and sanitized** version of a working private HomeLab. It documents the architecture, operational model, security posture, backup strategy, recovery strategy, and example workflows without exposing private credentials, real tokens, internal logs, real backup archives, or sensitive configuration files.

## Portfolio Snapshot

HomeLab AgentOps is a local-first operations toolkit built from a real Raspberry Pi 8GB HomeLab environment. It demonstrates public-safe infrastructure documentation, diagnostics, backup dry-run workflows, shell validation, repository safety checks, and clear public/private separation.

The public repository is designed to be reproducible without requiring access to the private HomeLab, NAS, Tailscale network, secrets, logs, or production configuration.

---

## Current public release - v0.5.2

v0.5.2 is the current public patch release. It adds a canonical blocking quality gate, GitHub Actions integration, portable installer wrappers, and aligned public documentation while preserving the public/private boundary.

You can now run public-safe helper scripts:

```bash
git clone https://github.com/gabrielcpow0b10/homelab-agentops.git
cd homelab-agentops
bash scripts/halo-doctor.sh
bash scripts/halo-status.sh
bash scripts/halo-backup-dryrun.sh
bash scripts/halo-security-scan.sh --strict
```

For the fastest setup, see [QUICKSTART.md](QUICKSTART.md). For sanitized example output, see [docs/demo-output.md](docs/demo-output.md).

Optional local install:

```bash
bash install.sh
halo-doctor
halo-security-scan
halo-status
halo-backup-dryrun
```

---

## Why this project exists

The goal is not only to run a few self-hosted tools. The goal is to build a small but realistic operations layer that behaves like a private infrastructure lab:

- services are monitored,
- changes are documented,
- backups are verified,
- recovery is planned,
- automation is controlled,
- remote access stays private,
- and future local AI agents can reason over logs, documentation, and system state.

This project connects infrastructure, automation, documentation, and AI-readiness into one practical HomeLab platform.

---

## Architecture at a glance

```text
Internet / Existing Wi-Fi
        |
        v
Internal HomeLab Router
        |
        v
Gigabit Switch
   |---------------|----------------|----------------|
   v               v                v                v
Service Node    Rack Display       NAS          Future AI Node
Raspberry Pi    Raspberry Pi       Storage      Mac mini
Docker          Dashboard          Backups      Local AI
Monitoring      Status UI          Reports      Agents
Agents          Kiosk View         Recovery     Ollama/Open WebUI
```

### Core roles

| Component | Public role description |
|---|---|
| Service node | Runs Docker services, monitoring tools, operational scripts, and agent workflows. |
| Rack display node | Shows a local dashboard / command-center style status view for the HomeLab. |
| NAS | Stores documentation, reports, backups, changelogs, and recovery materials. |
| Admin workstation | Used for SSH, browser-based administration, documentation, and GitHub workflow. |
| Mobile control | Used for private access and controlled Telegram commands. |
| Future local AI node | Planned dedicated system for local models, AI agents, and heavier workloads. |

---

## What this project demonstrates

- Linux administration on Raspberry Pi / Debian-based systems
- Docker-based self-hosting
- Service monitoring with status dashboards
- NAS-backed documentation and backup workflows
- Backup verification and restore-test thinking
- Private remote access using a VPN-style model
- systemd services and timers
- Telegram command gateway design with strict whitelisting
- Safe maintenance automation using scan, dry-run, and safe-cleanup concepts
- NAS-safe monitoring behavior to avoid waking storage unnecessarily
- Public/private documentation separation
- Preparation for local agents and AI-assisted operations

---

## Current capabilities

- Run public-safe HomeLab diagnostics with `halo-doctor`.
- Run repository safety checks with `halo-security-scan`.
- Install helper commands locally with `install.sh`.
- Run the canonical blocking repository validation with `halo-quality-gate`.
- Validate public safety automatically through GitHub Actions.
- Document NAS-safe monitoring, backup/recovery, Telegram gateway design, and rack dashboard concepts.
- Keep a clear boundary between private HomeLab operations and public portfolio-safe documentation.

---

## Functional public scripts

| Script | Purpose |
|---|---|
| `scripts/halo-quality-gate.sh` | Canonical blocking validation: required files, shell syntax, whitespace, version consistency, repository safety, and backup dry-run behavior. |
| `scripts/halo-doctor.sh` | Public-safe local diagnostic for system, Docker, systemd, Tailscale, NAS-safe mode, and repository safety. |
| `scripts/halo-status.sh` | Public-safe host status report emitting `HALO_PUBLIC_STATUS=GREEN|WARN`. |
| `scripts/halo-security-scan.sh` | Scans the repository for secret patterns, private networks, private paths, and forbidden file types. |
| `scripts/halo-backup-dryrun.sh` | Non-destructive backup preview emitting `HALO_BACKUP_DRYRUN=OK`. Copies nothing. |
| `scripts/examples/halo-status.example.sh` | Sanitized status example. |
| `scripts/examples/halo-backup.example.sh` | Backup workflow concept example. |
| `install.sh` | Installs portable wrapper commands into `~/.local/bin`. |

---

## Current public scope

This public repository includes:

- sanitized architecture documentation,
- backup and recovery strategy,
- security model,
- roadmap,
- public-safe scripts,
- and workflow notes that explain how the private system is operated.

This public repository does **not** include:

- real `.env` files,
- Telegram bot tokens,
- private keys,
- private logs,
- real backup archives,
- production secrets,
- sensitive screenshots,
- or private operational configuration.

---

## Operational modules

### Monitoring layer

A lightweight monitoring workflow checks basic service health and reports system state. The automatic monitoring mode is designed to be **NAS-safe**, meaning it avoids touching NAS paths during scheduled checks so storage can remain in standby when not needed.

### Documentation layer

A documentation workflow processes structured update notes, appends them to a project changelog, stores reports, and creates operational memory for the HomeLab.

### Maintenance layer

The maintenance workflow is intentionally manual. It is designed around:

- scan first,
- dry-run before cleanup,
- safe-trash-only deletion,
- no automatic destructive operations,
- and no blind cleanup of Docker, NAS, secrets, or backups.

### Telegram control layer

The Telegram gateway model is designed as a controlled command layer:

- private polling model,
- authorized chat only,
- whitelist of allowed commands,
- no arbitrary shell execution,
- compact responses,
- full logs kept locally.

---

## Core services

| Service / tool | Purpose |
|---|---|
| Docker | Container runtime for HomeLab services. |
| Portainer | Visual Docker administration. |
| Uptime Kuma | Service uptime/status monitoring. |
| Netdata | Real-time system metrics. |
| Tailscale | Private remote access model. |
| Synology NAS | Persistent storage, reports, backups, and recovery material. |
| systemd | Services and timers for automation. |
| Telegram Bot API | Controlled operational notifications and commands. |
| Bash / Python | Automation, reporting, and glue scripts. |

---

## Public vs private boundary

| Public in this repo | Kept private |
|---|---|
| Sanitized architecture | Real credentials |
| Public runbooks | Telegram tokens |
| Example scripts | Production `.env` files |
| Recovery strategy | Real backup archives |
| Security model | Private logs |
| Roadmap | Private screenshots |
| Placeholder paths | Internal secrets |

---

## Safety model

This project follows a conservative HomeLab security posture:

- no public administrative ports,
- private access only,
- no secrets in GitHub,
- no arbitrary Telegram shell execution,
- whitelisted operational commands only,
- backups are verified before being trusted,
- destructive actions require dry-run and manual intent,
- NAS standby is treated as normal, not automatically as a failure.

See [SECURITY.md](SECURITY.md) for the public security model.

---

## Roadmap

### Completed / current foundation

- Public sanitized GitHub repository
- High-level architecture documentation
- Public backup and recovery runbooks
- Security model
- Example backup workflow
- Functional `halo-doctor` diagnostic script
- Functional public security scan script
- Public `.env.example`
- Basic installer for helper commands
- GitHub Actions workflow for automated security scan

### Next improvements

- Add a local dashboard preview
- Add cross-platform notes for macOS and Linux
- Add local AI / MCP readiness documentation

### Future direction

- Mac mini as local AI node
- Ollama / Open WebUI experimentation
- Local AI agents for logs and documentation
- AI-assisted operational recommendations
- Scientific computing and simulation workflows

---

## Repository structure

```text
.
  ARCHITECTURE.md
  BACKUP_RUNBOOK_PUBLIC.md
  CHANGELOG.md
  CONTRIBUTING.md
  docs
    backup-restore-model.md
    demo-output.md
    nas-safe-monitoring.md
    project-overview.md
    public-security-hardening.md
    rack-command-center.md
    security
      public-release-checklist.md
    telegram-gateway-model.md
    v0.5-public-toolkit-foundation.md
  .env.example
  .github
    workflows
      quality-gate.yml
      security-scan.yml
      shell-validation.yml
  .gitignore
  install.sh
  LICENSE
  QUICKSTART.md
  README.md
  RECOVERY_PUBLIC.md
  ROADMAP.md
  scripts
    examples
      halo-backup.example.sh
      halo-status.example.sh
    halo-backup-dryrun.sh
    halo-doctor.sh
    halo-quality-gate.sh
    halo-security-scan.sh
    halo-status.sh
  SECURITY.md
  VERSIONING.md
```

---

## Current status

HomeLab AgentOps is active and evolving. v0.5.2 is the current public release: it adds a canonical public quality gate, portable installed commands, repository safety checks, shell validation, contribution guidance, and automated GitHub Actions quality gates.

---

## Main learning outcomes

This project demonstrates how a small HomeLab can grow into a serious infrastructure learning platform when it is:

- documented,
- monitored,
- backed up,
- recoverable,
- secured,
- automated carefully,
- and designed with future AI agents in mind.

---

## Author

**Gabriel Cruz**
Physics graduate, Computer Science student, and HomeLab / local AI systems builder.

## Who is this for?

HomeLab AgentOps is designed for:

- self-hosters building small private infrastructure
- students learning Linux, DevOps, automation, and secure operations
- Raspberry Pi users running monitoring or dashboard nodes
- HomeLab builders who want safer backup and recovery habits
- developers preparing for local AI infrastructure
- people interested in public-safe automation patterns

The public repository is intentionally sanitized. It demonstrates operational structure, diagnostics, security checks, and recovery discipline without exposing private infrastructure.

## Public Toolkit Commands

The public toolkit includes safe commands that can be tested without private HomeLab access.

    bash scripts/halo-quality-gate.sh
    bash scripts/halo-status.sh
    bash scripts/halo-backup-dryrun.sh
    bash scripts/halo-security-scan.sh --strict
    bash scripts/halo-doctor.sh

The status and backup dry-run scripts are public-safe by design:

- no real NAS paths required
- no Telegram tokens required
- no private IPs required
- no `.env` files required
- no production backup is created
- no destructive action is performed

Status command result:

- `HALO_PUBLIC_STATUS=GREEN` means no local warnings were detected.
- `HALO_PUBLIC_STATUS=WARN` means a local condition requires review.

Other expected public-safe results:

    HALO_BACKUP_DRYRUN=OK
    Security scan result: GREEN

## Public / Private Boundary

This repository must not include private operational data.

Keep private:

- real `.env` files
- Telegram bot tokens
- chat IDs
- NAS credentials
- private IP maps
- SSH keys
- production logs
- real backup archives
- private screenshots
- internal-only runbooks

Use public-safe examples and placeholders instead.
