# Public Security Hardening

This repository is a sanitized public export of a private HomeLab AgentOps system.

## Public Safety Goals

The public repository must remain safe for portfolio and review use.

It must not expose:

- Real environment files
- Telegram bot tokens
- Real chat IDs
- Private keys
- NAS credentials
- Raw logs
- Backup archives
- Private screenshots
- Private IP or Tailscale details
- Internal filesystem paths

## Security Controls

The public model documents the following controls:

- Whitelisted Telegram commands only
- No arbitrary shell execution
- No `/shell`, `/exec`, or `/run`
- Telegram-safe summaries
- Local-only audit log
- Local-only cooldown state
- NAS-safe automated behavior
- Restore testing without production overwrite
- Public/private separation

## CI Security Scan

The repository runs a security scan through GitHub Actions on:

- Push to `main`
- Pull requests targeting `main`

The scan should support normal and strict modes:

```bash
bash scripts/halo-security-scan.sh
bash scripts/halo-security-scan.sh --strict
```

## Public Release Rule

Before publishing or merging a public update:

- Security scan: GREEN
- Strict scan: GREEN
- No forbidden runtime files
- No private paths
- No real secrets
- No private network details
