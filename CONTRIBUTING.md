# Contributing to HomeLab AgentOps

Thank you for your interest in HomeLab AgentOps.

This repository is a public-safe HomeLab operations toolkit focused on monitoring, backup discipline, recovery documentation, security checks, and future local AI agent readiness.

## Project Scope

This public repository may include:

- Public-safe documentation
- Sanitized examples
- Security-first scripts
- Recovery and backup runbooks
- HomeLab operational patterns
- Local AI readiness notes

This repository must not include private infrastructure details.

## Public-Safe Rule

Do not commit or publish:

- Real `.env` files
- Telegram bot tokens
- Chat IDs
- NAS credentials
- Private IP maps
- SSH keys
- API keys
- Internal logs
- Real backup archives
- Private screenshots
- Production-only scripts with secrets

Use `.env.example`, sanitized outputs, and placeholder values instead.

## Before Opening a Pull Request

Run the local checks:

```bash
bash scripts/halo-security-scan.sh --strict
bash scripts/halo-doctor.sh
find scripts -type f -name "*.sh" -print0 | xargs -0 -n1 bash -n
