# NAS-Safe Monitoring Model

This document explains the public/sanitized monitoring principle used in HomeLab AgentOps: scheduled monitoring should not unnecessarily wake NAS storage.

---

## Problem

A NAS can enter standby when it is not actively being used. Some monitoring scripts accidentally prevent standby by repeatedly touching mounted NAS paths.

Common actions that may wake storage include:

- listing NAS directories,
- running disk usage checks on NAS mounts,
- reading files from mounted shares,
- scanning report folders,
- checking backup directories too frequently.

For a HomeLab, this can create unnecessary disk activity, noise, wear, and power usage.

---

## Design decision

The automatic monitoring layer should be NAS-safe.

That means scheduled lightweight checks should avoid touching NAS paths unless the user intentionally runs a deeper manual maintenance workflow.

---

## Monitoring modes

| Mode | Purpose | NAS behavior |
|---|---|---|
| Lightweight scheduled monitoring | Frequent status checks and compact reporting | Avoids NAS reads/writes |
| Manual maintenance scan | Deeper inspection when the user intentionally runs it | May inspect NAS |
| Documentation processing | Processes update notes and changelog entries | May touch NAS intentionally |
| Backup workflow | Creates and verifies backups | Touches NAS intentionally |

---

## Public-safe pseudocode

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-nas-safe}"

check_system() {
  hostname
  uptime
  free -h
}

check_docker() {
  systemctl is-active docker || true
  docker ps --format '{{.Names}}' 2>/dev/null || true
}

check_nas_safe() {
  # Do not run ls, du, find, cat, or df against NAS paths here.
  echo "NAS check skipped in scheduled NAS-safe mode"
}

check_nas_manual() {
  # Manual mode only. Use intentionally.
  echo "Manual NAS inspection would run here"
}

check_system
check_docker

case "$MODE" in
  nas-safe)
    check_nas_safe
    ;;
  manual)
    check_nas_manual
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
esac
```

---

## Practical rule

Automatic monitoring should answer:

> Is the HomeLab generally healthy?

Manual maintenance should answer:

> What exactly is happening across the full system, including NAS, reports, backups, and storage?

Keeping those two questions separate makes the system safer and more predictable.

---

## Why this matters

This is a small example of real operational thinking:

- monitoring should be useful,
- but monitoring should not create unnecessary side effects,
- storage standby should be respected,
- and deeper checks should be intentional.
