#!/usr/bin/env bash

# Halo HomeLab AgentOps - NAS Status
# NAS-safe: does not scan, list, read or calculate disk usage on NAS paths.

MOUNT="/path/to/homelab-projects"

echo "HALO_NAS_STATUS"
echo "host=$(hostname)"
echo "mount_path=$MOUNT"

if findmnt -rn "$MOUNT" >/dev/null 2>&1; then
  echo "mount=MOUNTED"
  echo "mode=OPTIONAL / MOUNTED"
  echo "policy=DO NOT SCAN IN AUTO MODE"
  echo "disk_scan=SKIPPED"
  echo "folder_scan=SKIPPED"
  echo "overall=GREEN"
else
  echo "mount=NOT_MOUNTED"
  echo "mode=OPTIONAL / STANDBY-SAFE"
  echo "policy=NAS can sleep"
  echo "disk_scan=SKIPPED"
  echo "folder_scan=SKIPPED"
  echo "overall=GREEN"
fi

echo "Safety: mount table only / no NAS folder read"
