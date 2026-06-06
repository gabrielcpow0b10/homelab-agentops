#!/usr/bin/env bash

# Halo HomeLab AgentOps - Node Health
# Local-only. Does not touch NAS.

HOST="$(hostname)"
NOW="$(date)"
UPTIME="$(uptime -p 2>/dev/null || uptime)"
LOAD="$(uptime | awk -F'load average: ' '{print $2}')"
TEMP="N/A"
TEMP_NUM="0"
THROTTLE="N/A"

if command -v vcgencmd >/dev/null 2>&1; then
  TEMP="$(vcgencmd measure_temp 2>/dev/null | sed "s/temp=//")"
  TEMP_NUM="$(echo "$TEMP" | tr -d "'C")"
  THROTTLE="$(vcgencmd get_throttled 2>/dev/null | sed 's/throttled=//')"
elif [ -r /sys/class/thermal/thermal_zone0/temp ]; then
  TEMP_NUM="$(awk '{printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone0/temp)"
  TEMP="${TEMP_NUM}'C"
fi

RAM_LINE="$(free -h | awk '/^Mem:/ {print "ram_used="$3" ram_total="$2" ram_available="$7}')"
DISK_LINE="$(df -h / | awk 'NR==2 {print "root_used="$3" root_total="$2" root_percent="$5}')"
DISK_PERCENT="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"

OVERALL="GREEN"

if awk "BEGIN {exit !($TEMP_NUM >= 75)}"; then
  OVERALL="WARNING"
fi

if awk "BEGIN {exit !($TEMP_NUM >= 85)}"; then
  OVERALL="ERROR"
fi

if [ "${DISK_PERCENT:-0}" -ge 80 ] 2>/dev/null; then
  OVERALL="WARNING"
fi

if [ "${DISK_PERCENT:-0}" -ge 90 ] 2>/dev/null; then
  OVERALL="ERROR"
fi

if [ "$THROTTLE" != "N/A" ] && [ "$THROTTLE" != "0x0" ]; then
  OVERALL="WARNING"
fi

echo "HALO_NODE_STATUS"
echo "host=$HOST"
echo "time=$NOW"
echo "uptime=$UPTIME"
echo "temperature=$TEMP"
echo "throttling=$THROTTLE"
echo "load=$LOAD"
echo "$RAM_LINE"
echo "$DISK_LINE"
echo "overall=$OVERALL"
echo "NAS: not touched"
