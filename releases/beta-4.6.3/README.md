# HomeLab AgentOps Beta 4.6.3 - Public Sanitized Draft

This is a sanitized public draft of a self-hosted HomeLab operations layer.

## Scope

This public draft documents the operational design of a private HomeLab AgentOps system.

Included:
- Local operational status command examples
- Telegram Gateway command structure
- Audit log design
- Cooldown/rate limit design
- Gateway error visibility model
- Log rotation timer design
- Restore-test documentation

Not included:
- Telegram bot token
- Private `.env` files
- Real chat IDs
- Private NAS credentials
- Private Tailscale identity details
- Personal private logs
- Raw production backups
- Private backup manifests
- Private screenshots

## Security Model

- Whitelisted Telegram commands only
- No arbitrary shell execution
- No `/shell`, `/exec`, or `/run`
- Telegram-safe summaries
- Local-only audit log
- Local-only cooldown state
- NAS-safe automated behavior
- Restore testing performed without overwriting production files

## Current Stable Status

Beta 4.6.3 Step 1:

STABLE CUMULATIVE BACKUP / RESTORE TEST / SHA256 VERIFIED / NO PRODUCTION OVERWRITE / GREEN.

## Public Release Rule

This folder is a draft. Before publishing, every script must be reviewed as an example file and every secret scan must pass.
