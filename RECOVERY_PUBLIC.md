# Recovery Playbook - Public Sanitized Version

This document describes the public recovery strategy without exposing private paths, credentials, or internal secrets.

## Recovery Goals

- Rebuild the services node after system failure.
- Restore agent folders.
- Restore user systemd services.
- Restore Docker volumes.
- Recreate Docker containers.
- Verify monitoring services.
- Verify private access.
- Confirm backup integrity.

## Recovery Strategy

1. Reinstall the operating system.
2. Configure SSH and hostname.
3. Install Tailscale or private access method.
4. Install Docker.
5. Mount NAS or backup storage.
6. Restore agent folders from backup.
7. Restore user systemd services.
8. Restore Docker volume archives.
9. Recreate containers.
10. Verify services and logs.

## Important Note

The internal version contains exact paths and operational details. This public version is sanitized.
