# HomeLab AgentOps

**Version:** 0.1 Public / Sanitized  
**Status:** Foundation layer for self-hosted monitoring, automation, recovery, and future local AI agents.

## Overview

HomeLab AgentOps is a personal self-hosted infrastructure project built to practice and demonstrate Linux administration, Docker services, NAS-backed documentation, monitoring, automation, recovery planning, and secure private access.

The project currently runs on Raspberry Pi nodes and a Synology NAS, with a future roadmap to add a Mac mini as a local AI node.

## What This Project Demonstrates

- Linux system administration
- Docker-based self-hosted services
- Monitoring with status dashboards
- NAS-backed documentation and backup workflows
- Tailscale-based private access
- systemd services and timers
- Telegram command gateway with a whitelist approach
- Manual backup and restore verification
- Recovery playbook design
- NAS-safe monitoring behavior
- Preparation for future local AI agents

## Current Public Scope

This public version does not include private credentials, tokens, real backups, private logs, or sensitive configuration files.

It documents the architecture, workflows, recovery strategy, backup strategy, and sanitized examples.

## Core Services

- Docker host
- Portainer
- Uptime Kuma
- Netdata
- Telegram Gateway
- Halo monitoring scripts
- Manual backup command concept
- Recovery documentation

## Security Model

The system is designed around private access and controlled automation:

- No public administrative ports
- Private access through Tailscale
- Telegram command whitelist
- No arbitrary shell execution through Telegram
- Manual-only backup command
- Sensitive files excluded from public documentation

## Roadmap

Phase 1: Raspberry Pi HomeLab foundation  
Phase 2: Recovery, backup, and documentation layer  
Phase 3: Public sanitized GitHub portfolio version  
Phase 4: Mac mini local AI node  
Phase 5: Local AI agents for logs, documentation, and operational recommendations

## Repository Status

This repository is a sanitized public documentation version. It is intended for learning, portfolio review, and future expansion.
