# HomeLab AgentOps

**Version:** v0.3 Public Toolkit Preview  
**Status:** Functional public starter kit for HomeLab diagnostics and safety checks  
**Focus:** Monitoring, backup, recovery, automation, secure remote operations, and future local AI agents  
**Author:** Gabriel Cruz

HomeLab AgentOps is a self-hosted infrastructure and operations project built to practice real-world Linux administration, Docker services, NAS-backed documentation, monitoring, backup/recovery workflows, safe automation, and private remote access.

This repository is the **public and sanitized** version of a working private HomeLab. It documents the architecture, operational model, security posture, backup strategy, recovery strategy, and example workflows without exposing private credentials, real tokens, internal logs, real backup archives, or sensitive configuration files.

---

## New in v0.3

v0.3 moves the repository from documentation-only toward a functional public toolkit.

You can now run public-safe helper scripts:

```bash
git clone https://github.com/gabrielcpow0b10/homelab-agentops.git
cd homelab-agentops
bash scripts/halo-doctor.sh
bash scripts/halo-security-scan.sh
```

Optional local install:

```bash
bash install.sh
halo-doctor
halo-security-scan
halo-status-example
halo-backup-example
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

## Functional public scripts

| Script | Purpose |
|---|---|
| `scripts/halo-doctor.sh` | Runs a public-safe local diagnostic check for system, Docker, systemd, Tailscale, NAS-safe mode, and repo safety. |
| `scripts/halo-security-scan.sh` | Scans the public repo for common secret patterns and forbidden file types before publishing. |
| `scripts/examples/halo-status.example.sh` | Simple sanitized status example. |
| `scripts/examples/halo-backup.example.sh` | Backup workflow concept example. |
| `install.sh` | Adds helper commands to `~/.local/bin`. |

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

### Next improvements

- Add `halo-status.sh` as a stronger public status command
- Add `halo-backup-dryrun.sh`
- Add a local dashboard preview
- Add GitHub Actions for automated security scan
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
├── README.md
├── ARCHITECTURE.md
├── BACKUP_RUNBOOK_PUBLIC.md
├── RECOVERY_PUBLIC.md
├── ROADMAP.md
├── SECURITY.md
├── CHANGELOG.md
├── .env.example
├── install.sh
├── docs/
│   ├── project-overview.md
│   ├── nas-safe-monitoring.md
│   ├── telegram-gateway-model.md
│   ├── backup-restore-model.md
│   └── rack-command-center.md
└── scripts/
    ├── halo-doctor.sh
    ├── halo-security-scan.sh
    └── examples/
        ├── halo-backup.example.sh
        └── halo-status.example.sh
```

---

## Current status

HomeLab AgentOps is active and evolving. v0.3 is the first public toolkit preview: it keeps the project sanitized while adding functional scripts that other users can run safely on their own machines.

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
