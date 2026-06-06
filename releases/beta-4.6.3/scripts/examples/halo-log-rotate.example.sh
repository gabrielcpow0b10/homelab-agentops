#!/usr/bin/env bash

# Halo HomeLab AgentOps - Log Rotation
# Local-only. No secrets. No NAS. Archives Gateway and audit logs if they grow too much.

MODE="${1:-auto}"
MAX_BYTES="${HALO_LOG_MAX_BYTES:-262144}"   # 256 KB default

ROOT="$HOME/halo-telegram-gateway"
GATEWAY_LOG="$ROOT/logs/gateway.log"
AUDIT_LOG="$ROOT/audit/telegram-command-audit.log"

rotate_one() {
  local file="$1"
  local label="$2"
  local archive_dir="$3"

  mkdir -p "$archive_dir"
  chmod 700 "$archive_dir" 2>/dev/null || true

  if [ ! -f "$file" ]; then
    echo "$label=missing"
    return 0
  fi

  local size
  size="$(stat -c%s "$file" 2>/dev/null || echo 0)"

  echo "$label_size_bytes=$size"

  if [ "$MODE" = "--check" ]; then
    echo "$label_action=check_only"
    return 0
  fi

  if [ "$MODE" = "--force" ] || [ "$size" -ge "$MAX_BYTES" ]; then
    local stamp
    stamp="$(date +%Y%m%d_%H%M%S)"
    local base
    base="$(basename "$file")"
    local archived="$archive_dir/${base}.archive.$stamp"

    mv "$file" "$archived"
    touch "$file"
    chmod 600 "$file"

    if command -v gzip >/dev/null 2>&1; then
      gzip -f "$archived"
      echo "$label_action=rotated_to=${archived}.gz"
    else
      echo "$label_action=rotated_to=$archived"
    fi
  else
    echo "$label_action=skipped_below_threshold"
  fi
}

echo "HALO_LOG_ROTATE"
echo "host=$(hostname)"
echo "mode=$MODE"
echo "max_bytes=$MAX_BYTES"

rotate_one "$GATEWAY_LOG" "gateway_log" "$ROOT/logs/archive"
rotate_one "$AUDIT_LOG" "audit_log" "$ROOT/audit/archive"

echo "overall=GREEN"
echo "Security: local logs only / no tokens / no NAS / no deletion of archives"
