# Rack Command Center

This document describes the public/sanitized concept of the HomeLab rack display and command center.

The private implementation contains specific hostnames, IPs, service paths, display scripts, and internal dashboard files. This public document explains the design pattern without exposing private operational details.

---

## Purpose

The rack command center is the physical visual layer of the HomeLab.

Its goal is to provide a quick local view of:

- overall HomeLab status,
- service node state,
- rack display node state,
- Docker/service summary,
- NAS mode,
- latest monitoring summary,
- and future AI-node readiness.

It is not intended to replace detailed admin tools. It is a front-panel operational view.

---

## Design decision

The display node should host the dashboard locally.

This keeps the visual layer independent from the service node. The service node can provide data, but the display node owns the screen, kiosk browser, and local dashboard service.

```text
Service node
  -> provides monitoring data
  -> runs Docker and agents

Rack display node
  -> hosts local dashboard
  -> renders kiosk browser
  -> controls screen sleep
  -> shows command center view
```

---

## Why avoid direct admin pages on the rack screen?

Opening NAS login pages, Docker admin panels, or monitoring admin pages directly on the kiosk screen can create problems:

- the screen can get stuck outside the dashboard,
- login pages can appear on the rack screen,
- touch input can accidentally navigate away,
- and the display becomes less predictable.

A dedicated local dashboard avoids those issues.

---

## Recommended dashboard behavior

The dashboard should:

- open automatically after boot,
- run in kiosk mode,
- avoid external navigation buttons,
- show summarized status instead of admin panels,
- refresh data in the background,
- keep running while the screen sleeps,
- recover with a simple restart command,
- and avoid exposing credentials or login screens.

---

## Screen sleep model

The screen should turn off after inactivity while the dashboard continues running.

This means:

- the browser remains open,
- the local web service remains active,
- data refresh continues,
- the screen goes dark,
- and input wakes the display.

---

## Public-safe workflow

```text
Boot display node
        |
        v
Start local dashboard service
        |
        v
Generate status data periodically
        |
        v
Open browser in kiosk mode
        |
        v
Show HomeLab command center
        |
        v
Turn screen off after inactivity
```

---

## Example status categories

| Category | Example public-safe status |
|---|---|
| Global status | GREEN / WARNING / ERROR |
| Service node | reachable / unreachable |
| Docker | active / inactive |
| Containers | count only, no private names required |
| NAS mode | available / standby / skipped |
| Monitoring summary | latest public-safe status |
| Display node | temperature / memory / uptime |

---

## Recovery command concept

The private system uses a simple command to restart the visual dashboard without rebooting the whole device.

A public-safe equivalent would be:

```bash
restart-dashboard
```

The command should close the old browser process, make sure the local dashboard is reachable, reopen the kiosk view, and write troubleshooting logs.

---

## Troubleshooting model

| Symptom | Likely layer to check |
|---|---|
| Browser is blank | Kiosk browser or local dashboard service |
| Dashboard service is down | Local web service |
| Data is stale | Status refresh job or data collection |
| Service node shows unavailable | Network, SSH, private access, service node state |
| Screen does not turn off | Display power tool or idle service |
| Screen opens external page | Remove external links and use widgets instead |

---

## Professional value

The rack command center demonstrates that the project includes a physical operations interface, clear role separation, and practical system design.
