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

Run the focused Bats regression suite:

```bash
bats --tap tests/public-safety.bats
```

Run the blocking public quality gate:

```bash
bash scripts/halo-quality-gate.sh
```

The gate validates required public files, shell syntax, ShellCheck, Git whitespace, README script coverage, the environment-variable contract, current-version consistency, the canonical public tree, the strict security scan, the backup dry-run, the public-safety Bats suite, and the sanitized demo-output contract.

GitHub Actions installs ShellCheck and Bats and runs this same canonical gate through `.github/workflows/quality-gate.yml`, avoiding duplicated validation workflows.

Host diagnostics are optional and non-blocking:

```bash
bash scripts/halo-doctor.sh
bash scripts/halo-status.sh
```
