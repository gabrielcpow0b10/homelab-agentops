# Architecture

This document describes the public/sanitized architecture of HomeLab AgentOps.

The private implementation uses specific IPs, hostnames, internal paths, mounted shares, tokens, logs, and operational files. Those details are intentionally excluded from this public repository.

---

## Architecture goals

HomeLab AgentOps is designed around a simple idea: every device and workflow should have a clear role.

The architecture focuses on:

- private local infrastructure,
- role separation,
- lightweight service hosting,
- NAS-backed persistence,
- monitored operations,
- controlled automation,
- recovery planning,
- and future local AI integration.

---

## High-level topology

```text
Internet / Existing Wi-Fi
        |
        v
Internal HomeLab Router
        |
        v
Gigabit Ethernet Switch
   |-------------------|--------------------|-------------------|
   v                   v                    v                   v
Service Node        Rack Display Node       NAS            Future AI Node
Docker              Dashboard / Kiosk       Storage        Local models
Monitoring          Status UI               Reports        AI agents
Automation          Visual operations       Backups        Heavy workloads
Telegram gateway    Command center          Recovery       Simulations
```

---

## Core components

| Component | Responsibility | Design reason |
|---|---|---|
| Internal router | Creates the private HomeLab network from the available internet connection. | Keeps the lab organized under its own network boundary. |
| Switch | Distributes wired connectivity across the rack. | Simple, reliable, and avoids unnecessary wireless dependency for fixed devices. |
| Service node | Runs Docker, monitoring, automation, command wrappers, and operational scripts. | Keeps services centralized on the node designed for always-on workloads. |
| Rack display node | Runs the physical dashboard / command center screen. | Keeps visualization separate from service workloads. |
| NAS | Stores reports, documentation, changelogs, backups, and recovery material. | Provides persistent project memory outside the service node. |
| Admin workstation | Used for SSH, browser administration, documentation, GitHub updates, and review. | Keeps human administration flexible and separate from the nodes. |
| Mobile device | Used for private access and controlled Telegram operations. | Enables operational checks without exposing public admin services. |
| Future AI node | Planned machine for local models, local AI agents, and heavier automation. | Keeps AI workloads off lightweight Raspberry Pi nodes. |

---

## Logical layers

```text
Layer 1 - Physical / Network
Router, switch, Raspberry Pi nodes, NAS, workstation, mobile device, future AI node

Layer 2 - Services
Docker, monitoring tools, status dashboards, metrics, private remote access

Layer 3 - Operations
Monitoring workflows, documentation workflows, maintenance workflows, backup/recovery workflows

Layer 4 - Control
Local command wrappers, SSH usage, Telegram gateway with whitelisted commands

Layer 5 - Persistence
NAS-backed documentation, reports, changelogs, backup indexes, recovery playbooks

Layer 6 - Future AI
Local models, AI-assisted log analysis, documentation-aware agents, simulation workflows
```

---

## Service node role

The service node is the operational core of the HomeLab.

It is responsible for:

- Docker services,
- uptime monitoring,
- metrics collection,
- operational scripts,
- scheduled lightweight checks,
- command wrappers,
- Telegram gateway behavior,
- and interaction with the NAS when explicitly needed.

The service node should remain lightweight and stable. It is not intended for heavy AI model workloads.

---

## Rack display role

The rack display node provides the physical visual layer of the HomeLab.

It is responsible for:

- displaying a local status dashboard,
- showing the current HomeLab state,
- keeping the visual interface separate from the main service node,
- and supporting a kiosk-style view.

This separation matters because the display node can be restarted, adjusted, or simplified without interrupting the core service node.

---

## NAS role

The NAS is treated as the persistent memory of the project.

It stores:

- documentation,
- reports,
- backup indexes,
- recovery playbooks,
- processed notes,
- project history,
- and operational records.

The monitoring layer is designed to be NAS-safe whenever possible. Scheduled lightweight checks should not repeatedly touch NAS paths if that prevents storage standby.

---

## Telegram gateway role

The Telegram gateway is not a general-purpose remote shell. It is a controlled command gateway.

It should:

- accept only authorized chats,
- accept only whitelisted commands,
- avoid arbitrary shell execution,
- return compact responses,
- and keep detailed output in local logs.

This makes mobile operations useful without turning the phone into an unsafe unrestricted terminal.

---

## Data and documentation flow

```text
Operational event or manual note
        |
        v
Documentation workflow
        |
        |-- update changelog
        |-- create report
        |-- store result on NAS
        |-- keep public/private boundary
        v
Recoverable project history
```

This flow is important because the project is not only running services. It is building operational memory.

---

## Backup and recovery flow

```text
Service node configuration
Docker inventory
Important volumes
Agent scripts
systemd user services
        |
        v
NAS-backed backup location
        |
        v
Checksum verification
        |
        v
Local restore test
        |
        v
Recovery playbook update
```

A backup is not considered fully trusted until a restore test has been performed.

---

## Design principles

- Keep roles separated.
- Keep administrative access private.
- Avoid public exposure of admin panels.
- Keep monitoring lightweight.
- Avoid waking NAS storage unnecessarily.
- Make backups verifiable.
- Make recovery documented.
- Keep destructive automation manual and intentional.
- Keep public GitHub documentation sanitized.
- Reserve heavy AI workloads for the future AI node.

---

## Future architecture direction

The future AI node is expected to add:

- local language models,
- Open WebUI-style interaction,
- AI-assisted documentation review,
- log analysis,
- operational recommendations,
- local agent workflows,
- and scientific computing experiments.

The Raspberry Pi nodes will remain focused on lightweight services, monitoring, display, and operational control.
