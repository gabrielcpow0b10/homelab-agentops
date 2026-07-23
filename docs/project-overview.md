# Project Overview

HomeLab AgentOps is a public, sanitized documentation repository for a private self-hosted HomeLab operations project.

The private system combines Raspberry Pi nodes, Docker services, a NAS-backed documentation and backup layer, monitoring tools, private remote access, controlled Telegram operations, and a future roadmap toward local AI agents.

This public repository is designed to show the architecture and engineering thinking without exposing private infrastructure details.

---

## Core idea

A HomeLab becomes more valuable when it is not only functional, but also:

- observable,
- documented,
- recoverable,
- secure,
- automation-ready,
- and safe to operate remotely.

HomeLab AgentOps focuses on that operational layer.

---

## Main objectives

1. Build a private local infrastructure lab.
2. Practice Linux, networking, Docker, NAS, monitoring, backup, and recovery.
3. Keep administrative access private.
4. Document system changes and operational decisions.
5. Create safe maintenance workflows.
6. Prepare the foundation for future local AI agents.

---

## System roles

| Role | Description |
|---|---|
| Service node | Runs Docker services, monitoring, scripts, timers, and operational workflows. |
| Rack display node | Displays the HomeLab status/dashboard in a physical rack screen. |
| NAS | Stores documentation, reports, changelogs, backups, and recovery materials. |
| Admin workstation | Used to manage the HomeLab through SSH, browser tools, and GitHub. |
| Mobile control | Used for private remote access and controlled Telegram operations. |
| Future AI node | Planned machine for local models, AI agents, log analysis, and automation support. |

---

## Operational philosophy

The project follows a conservative operations model:

- monitor first,
- document changes,
- back up before risky work,
- test restoration before trusting backups,
- never publish secrets,
- avoid public administrative exposure,
- and keep destructive automation manual and controlled.

---

## Public repository purpose

This repository exists to demonstrate the project safely. It is not a direct dump of the private HomeLab.

It includes public-safe explanations, sanitized workflows, example scripts, and high-level architecture. Real secrets, operational logs, private backups, production `.env` files, and sensitive screenshots remain private.

---

## Current public milestone

The current public milestone is v0.5.2 Public Quality Gate. The focus is to provide canonical blocking repository validation, portable public toolkit wrappers, automated GitHub Actions checks, and clear public-safe operational documentation without exposing private HomeLab details.
