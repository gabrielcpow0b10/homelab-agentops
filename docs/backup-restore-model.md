# Backup and Restore Model

This document describes the public/sanitized backup and restore model used by HomeLab AgentOps.

The private implementation contains real backup locations, real manifests, internal paths, and operational details. This public version explains the model without exposing private infrastructure.

---

## Backup philosophy

A backup is not complete just because files were copied.

A professional backup workflow should include:

1. clear backup scope,
2. safe destination,
3. inventory of what was backed up,
4. checksums or integrity checks,
5. restore test,
6. documentation,
7. and recovery instructions.

The key principle is:

> A backup is not trusted until restore has been tested.

---

## What should be backed up

For a HomeLab operations node, the backup scope may include:

| Area | Purpose |
|---|---|
| Agent scripts | Restore monitoring, documentation, and maintenance workflows. |
| Command wrappers | Restore short operational commands. |
| systemd user services/timers | Restore scheduled and background workflows. |
| Docker inventory | Understand which containers, images, networks, and volumes existed. |
| Important Docker volumes | Restore service state for key tools. |
| Recovery playbooks | Rebuild the system after failure. |
| Backup runbooks | Explain how the backup was created and verified. |

---

## What should not be public

Backup documentation can be public. Real backups should not be public.

Do not publish:

- real backup archives,
- `.tar.gz` volume archives,
- private logs,
- real `.env` files,
- Telegram tokens,
- private manifests containing secrets,
- private NAS paths,
- internal screenshots,
- or credentials.

---

## Public-safe backup workflow

```text
Select backup scope
        |
        v
Create backup destination
        |
        v
Copy scripts / configs / inventories
        |
        v
Export Docker inventory
        |
        v
Archive important volumes
        |
        v
Generate checksums
        |
        v
Verify archive readability
        |
        v
Perform local restore test
        |
        v
Write recovery notes
```

---

## Restore-test model

A restore test should not be skipped.

A public-safe restore test can be described like this:

```bash
# Example only. Do not use private paths in public repos.
RESTORE_TEST_DIR="/tmp/homelab-restore-test"
mkdir -p "$RESTORE_TEST_DIR"

# Example archive readability test
tar -tzf example-volume.tar.gz >/dev/null

# Example extraction test
tar -xzf example-volume.tar.gz -C "$RESTORE_TEST_DIR"

# Confirm files exist
find "$RESTORE_TEST_DIR" -maxdepth 2 -type f | head
```

If the restore test fails, the backup should not be treated as reliable.

---

## Docker volume backup concept

Docker volumes often contain the state of self-hosted services.

A safe public example:

```bash
VOLUME_NAME="example_volume"
BACKUP_FILE="${VOLUME_NAME}.tar.gz"

# Archive a Docker volume using a temporary container.
docker run --rm \
  -v "${VOLUME_NAME}:/data:ro" \
  -v "$(pwd):/backup" \
  alpine \
  sh -c "cd /data && tar -czf /backup/${BACKUP_FILE} ."

# Test archive readability.
tar -tzf "$BACKUP_FILE" >/dev/null
```

The private production workflow may be more complex and should remain private if it contains internal paths or sensitive details.

---

## Common problems

| Problem | Meaning | Safer response |
|---|---|---|
| Interrupted archive creation | Backup archive may be corrupt. | Delete the incomplete archive and recreate it. |
| Archive cannot be listed | Integrity issue or incomplete file. | Do not trust the backup. Re-run backup. |
| Restore fails on NAS mount | Filesystem may not support symlinks or Linux metadata. | Test restore on a Linux filesystem. |
| Backup contains `.env` | Secrets may be exposed. | Keep backup private; never publish. |
| No recovery document | Backup may be hard to use during failure. | Create a recovery playbook. |

---

## Recommended public repository content

Good public files:

- backup strategy,
- restore-test explanation,
- public-safe commands,
- example scripts,
- recovery checklist,
- security rules.

Bad public files:

- real backups,
- real archives,
- private manifests,
- secret-containing logs,
- production `.env` files.

---

## Recovery checklist

A useful recovery checklist should answer:

- What failed?
- Which node is being restored?
- Where is the backup?
- What services must be restored first?
- Which Docker volumes matter?
- Which systemd units must be restored?
- How do we verify the result?
- How do we document the recovery?

---

## Professional value

Backup and restore documentation turns a HomeLab from a hobby setup into a more serious operations project.

It demonstrates:

- planning,
- reliability thinking,
- recovery discipline,
- risk reduction,
- and operational maturity.
