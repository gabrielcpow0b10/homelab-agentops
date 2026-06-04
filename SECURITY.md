# Security Notes

This public repository does not include secrets.

Do not commit:

- .env files
- telegram.env
- passwords
- API tokens
- private keys
- NAS credentials
- SMB credentials
- real backup archives
- private logs
- screenshots containing sensitive information

## Operational Safety

The real HomeLab uses a whitelist-based command approach for Telegram control.

Dangerous patterns are intentionally avoided:

- no arbitrary shell command execution
- no public admin ports
- no automatic destructive cleanup
- no automatic backup timer that stops Docker unexpectedly

Backups are manual-only and require user confirmation.
