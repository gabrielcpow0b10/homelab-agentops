# Telegram Gateway Model

This document describes the public/sanitized Telegram command gateway model used by HomeLab AgentOps.

The goal is to allow controlled operational commands from a phone without exposing public administrative ports or allowing arbitrary shell execution.

---

## Design goals

- Use private outbound polling instead of public webhooks.
- Accept commands only from an authorized chat.
- Run only a strict whitelist of safe commands.
- Avoid arbitrary shell execution.
- Keep full command output in local logs.
- Send compact responses back to Telegram.
- Keep tokens and environment files out of GitHub.

---

## High-level flow

```text
Telegram message
      |
      v
Telegram Gateway
      |
      |-- validate authorized chat
      |-- validate command whitelist
      |-- reject unknown commands
      |
      v
Local wrapper command
      |
      v
Monitoring / Docs / Maintenance workflow
      |
      v
Compact Telegram confirmation
```

---

## Example command map

| Telegram command | Local action concept | Notes |
|---|---|---|
| `/status` | Show gateway status | Read-only |
| `/fire` | Run lightweight monitoring | NAS-safe mode preferred |
| `/docs` | Process documentation notes | May touch NAS intentionally |
| `/maint` | Run manual maintenance scan | Manual only |
| `/maint_dryrun` | Simulate cleanup | No destructive action |
| `/maint_clean_safe` | Clean safe-trash only | Restricted deletion scope |
| `/help` | Show allowed commands | Read-only |

---

## What must never be added

Do not add commands like:

```text
/shell
/run
/exec
/bash
/cmd
```

A Telegram bot should not become a remote unrestricted shell. Every command should be explicit, reviewed, and mapped to a safe local wrapper.

---

## Public-safe pseudocode

```python
ALLOWED_CHAT_ID = "REPLACE_WITH_AUTHORIZED_CHAT_ID"

COMMANDS = {
    "/status": ["./scripts/status.sh"],
    "/fire": ["./scripts/monitoring.sh", "--nas-safe"],
    "/maint_dryrun": ["./scripts/maintenance.sh", "--dry-run"],
}

def handle_message(chat_id, text):
    if str(chat_id) != ALLOWED_CHAT_ID:
        return "Unauthorized"

    if text not in COMMANDS:
        return "Unknown or blocked command"

    command = COMMANDS[text]
    # Run command safely without shell=True.
    # Capture logs locally. Return compact status.
    return "Command accepted and executed"
```

---

## Security principles

- Store tokens outside the repository.
- Use `.env.example` only for placeholders.
- Use file permissions appropriate for secrets.
- Avoid `shell=True` where possible.
- Do not forward raw logs or secret-containing output to Telegram.
- Prefer compact responses with a local log path.
- Rate-limit or cooldown heavier commands in future versions.

---

## Why this matters

The Telegram gateway is useful because it turns a phone into a controlled operations console. The important part is control: the gateway should trigger known workflows, not provide unrestricted access to the system.
