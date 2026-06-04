# Architecture

## Public Architecture Summary

The HomeLab is organized into clear roles:

- Services node: runs Docker, monitoring tools, agents, and command workflows.
- Rack display node: shows a local dashboard for HomeLab status.
- NAS: stores documentation, backup indexes, recovery playbooks, and reports.
- Admin workstation: used for SSH, browser access, documentation, and GitHub work.
- Future AI node: planned Mac mini for local AI workloads.

## Design Principles

- Keep monitoring lightweight.
- Avoid exposing admin services publicly.
- Use private networking for remote access.
- Keep NAS standby-friendly when possible.
- Separate internal/private documentation from public sanitized documentation.
- Make recovery possible through tested backups and playbooks.

## High-Level Flow

Internet/Wi-Fi  
→ private HomeLab network  
→ services node  
→ Docker services and agents  
→ NAS documentation and backups  
→ rack display dashboard  
→ future local AI node
