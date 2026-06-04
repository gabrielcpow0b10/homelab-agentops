# Backup Runbook - Public Sanitized Version

This document describes the public backup strategy without exposing private files or secrets.

## Backup Scope

The real backup workflow includes:

- agent folders
- user systemd services
- system inventory
- Docker inventory
- Docker container inspect files
- important Docker volume archives
- checksums
- local restore test
- final status manifest

## Backup Safety

The backup command is manual-only.

It does not run on a timer.

It requires user confirmation before touching Docker or backup storage.

## Verification

The workflow creates checksums and performs a local restore test to confirm that archives can be extracted correctly.

## Public Note

Real backup files are not included in this repository.
