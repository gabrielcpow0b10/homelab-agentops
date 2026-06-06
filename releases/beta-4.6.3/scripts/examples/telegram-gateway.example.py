#!/usr/bin/env python3

import os
import time
import json
import subprocess
import urllib.parse
import urllib.request
from pathlib import Path

HOME = Path.home()
ENV_FILE = HOME / "halo-agent" / "bot.env.example"
BASE_DIR = HOME / "halo-telegram-gateway"
STATE_DIR = BASE_DIR / "state"
LOG_DIR = BASE_DIR / "logs"
OFFSET_FILE = STATE_DIR / "telegram-offset.txt"
LOG_FILE = LOG_DIR / "gateway.log"

STATE_DIR.mkdir(parents=True, exist_ok=True)
LOG_DIR.mkdir(parents=True, exist_ok=True)

def log(msg):
    line = f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}"
    print(line, flush=True)
    with LOG_FILE.open("a") as f:
        f.write(line + "\n")

def load_env(path):
    env = {}
    if not path.exists():
        raise FileNotFoundError(f"Missing env file: {path}")

    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        value = value.strip().strip('"').strip("'")
        env[key.strip()] = value

    return env

env = load_env(ENV_FILE)

TOKEN = (
    env.get("TELEGRAM_BOT_TOKEN")
    or env.get("BOT_TOKEN")
    or env.get("TELEGRAM_TOKEN")
)

ALLOWED_CHAT_ID = (
    env.get("TELEGRAM_CHAT_ID")
    or env.get("CHAT_ID")
)

if not TOKEN or not ALLOWED_CHAT_ID:
    raise RuntimeError("Telegram token or chat id missing in bot.env.example")

API = f"https://api.telegram.org/bot{TOKEN}"

COMMANDS = {
    "/fire": ["/usr/local/bin/halo-fire"],
    "/docs": ["/usr/local/bin/halo-docs"],
    "/maint": ["/usr/local/bin/halo-maint-tg"],
    "/maint_dryrun": ["/usr/local/bin/halo-maint-dryrun-tg"],
    "/maint_clean_safe": ["/usr/local/bin/halo-maint-clean-safe-tg"],
    "/maint_deep": ["/usr/local/bin/halo-maint-deep-tg"],

}

HELP_TEXT = """🔥 HALO TELEGRAM GATEWAY

Available commands:

/fire
Run Halo Agent FIRE.

/docs
Run Halo Docs Agent.

/maint
Run Halo Maintenance Agent scan.

/maint_dryrun
Run Maintenance dry-run simulation.

/maint_clean_safe
Run safe cleanup only inside safe-trash.

/halo_status
Show compact HomeLab status.

/agents
Show agents layer status.

/last_fire
Show latest Halo FIRE report.

/last_maint
Show latest Maintenance report.

/last_docs
Show latest Docs Agent report.

/reports
Show FIRE, Maintenance and Docs report summary.

/gateway
Show Telegram Gateway health.

/gateway_errors
Show recent Telegram Gateway errors.

/logs
Show Gateway and audit log rotation status.

/audit
Show Telegram command audit status.

/cooldowns
Show Telegram command cooldown state.

/docker
Show Docker container summary.

/nas
Show NAS mount status without scanning NAS.

/node
Show Raspberry Pi node health.

/overview
Show full HomeLab operational overview.

/status
Show gateway status.

/help
Show this help.

Security:
Only the authorized Telegram chat can execute commands.
"""

def api_call(method, params=None):
    params = params or {}
    data = urllib.parse.urlencode(params).encode()
    req = urllib.request.Request(f"{API}/{method}", data=data)
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.loads(response.read().decode())

def send_message(text):
    max_len = 3900
    chunks = [text[i:i + max_len] for i in range(0, len(text), max_len)]

    for chunk in chunks:
        api_call("sendMessage", {
            "chat_id": ALLOWED_CHAT_ID,
            "text": chunk
        })

def audit_event(command, status, note="none"):
    try:
        subprocess.run(
            ["/usr/local/bin/halo-audit-log", str(command), str(status), str(note)],
            capture_output=True,
            text=True,
            timeout=5
        )
    except Exception as e:
        log(f"Audit log failed: {e}")

def get_offset():
    if OFFSET_FILE.exists():
        try:
            return int(OFFSET_FILE.read_text().strip())
        except Exception:
            return None
    return None

def save_offset(offset):
    OFFSET_FILE.write_text(str(offset))

def run_command(command, label):
    send_message(f"⏳ Running {label}...")

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=240
        )

        output = ((result.stdout or "") + "\n" + (result.stderr or "")).strip()

        # Save full terminal output only to local gateway log.
        if output:
            log(f"{label} output: {output[-2000:]}")

        if result.returncode == 0:
            send_message(f"✅ {label} completed.\n\nThe agent report was sent separately by the agent.")
            audit_event(label, "completed", f"returncode={result.returncode}")
        else:
            clean_output = output[-1200:] if output else "No output captured."
            send_message(f"⚠️ {label} finished with error code {result.returncode}.\n\nLast output:\n{clean_output}")
            audit_event(label, "error", f"returncode={result.returncode}")

        log(f"{label} executed with return code {result.returncode}")

    except subprocess.TimeoutExpired:
        send_message(f"⏱️ {label} timed out after 240 seconds.")
        audit_event(label, "timeout", "timeout=240")
        log(f"{label} timed out")

    except Exception as e:
        send_message(f"❌ Error running {label}:\n{e}")
        audit_event(label, "exception", str(e)[:120])
        log(f"Error running {label}: {e}")

def process_update(update):
    update_id = update.get("update_id")
    message = update.get("message") or update.get("edited_message") or {}
    chat = message.get("chat", {})
    chat_id = str(chat.get("id", ""))
    text = (message.get("text") or "").strip()

    if not text:
        return update_id

    if chat_id != str(ALLOWED_CHAT_ID):
        log(f"Blocked unauthorized chat id: {chat_id}")
        audit_event("unauthorized", "blocked", "chat_not_allowed")
        return update_id

    command = text.split()[0]
    audit_event(command, "received", "authorized")

    cooldown = subprocess.run(
        ["/usr/local/bin/halo-cooldown-check", command],
        capture_output=True,
        text=True,
        timeout=5
    )

    if cooldown.returncode == 2:
        output = (cooldown.stdout or cooldown.stderr or "Cooldown active.").strip()
        send_message(output[:1200])
        audit_event(command, "cooldown", "blocked")
        return update_id
    elif cooldown.returncode != 0:
        log(f"Cooldown check warning for {command}: {cooldown.returncode}")

    if command == "/start" or command == "/help":
        send_message(HELP_TEXT)

    elif command == "/status":
        send_message(
            "🟢 HALO TELEGRAM GATEWAY STATUS\n\n"
            "Gateway: running\n"
            "Host: " + os.uname().nodename + "\n"
            "Mode: private polling\n"
            "Authorized chat: OK\n"
            "Commands: /fire /docs /maint /maint_deep /maint_dryrun /maint_clean_safe"
        )

    elif command == "/cooldowns":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-cooldowns-status"],
                capture_output=True,
                text=True,
                timeout=20
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_COOLDOWNS_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_COOLDOWNS_STATUS failed: {e}")

    elif command == "/audit":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-audit-status"],
                capture_output=True,
                text=True,
                timeout=20
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_AUDIT_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_AUDIT_STATUS failed: {e}")

    elif command == "/overview":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-overview"],
                capture_output=True,
                text=True,
                timeout=45
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_OVERVIEW completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_OVERVIEW failed: {e}")

    elif command == "/node":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-node"],
                capture_output=True,
                text=True,
                timeout=20
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_NODE_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_NODE_STATUS failed: {e}")

    elif command == "/nas":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-nas"],
                capture_output=True,
                text=True,
                timeout=20
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_NAS_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_NAS_STATUS failed: {e}")

    elif command == "/docker":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-docker"],
                capture_output=True,
                text=True,
                timeout=30
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_DOCKER_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_DOCKER_STATUS failed: {e}")

    elif command == "/logs":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-logs-status"],
                capture_output=True,
                text=True,
                timeout=20
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_LOGS_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_LOGS_STATUS failed: {e}")

    elif command == "/gateway_errors":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-gateway-errors"],
                capture_output=True,
                text=True,
                timeout=20
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_GATEWAY_ERRORS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_GATEWAY_ERRORS failed: {e}")

    elif command == "/gateway":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-gateway-status"],
                capture_output=True,
                text=True,
                timeout=30
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_GATEWAY_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_GATEWAY_STATUS failed: {e}")

    elif command == "/reports":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-reports"],
                capture_output=True,
                text=True,
                timeout=45
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_REPORTS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_REPORTS failed: {e}")

    elif command == "/last_docs":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-last-docs"],
                capture_output=True,
                text=True,
                timeout=30
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_LAST_DOCS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_LAST_DOCS failed: {e}")

    elif command == "/last_maint":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-last-maint"],
                capture_output=True,
                text=True,
                timeout=30
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_LAST_MAINT completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_LAST_MAINT failed: {e}")

    elif command == "/last_fire":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-last-fire"],
                capture_output=True,
                text=True,
                timeout=30
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_LAST_FIRE completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_LAST_FIRE failed: {e}")

    elif command == "/agents":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-agents", "--compact"],
                capture_output=True,
                text=True,
                timeout=30
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_AGENTS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_AGENTS failed: {e}")

    elif command == "/halo_status":
        try:
            result = subprocess.run(
                ["/usr/local/bin/halo-status", "--compact"],
                capture_output=True,
                text=True,
                timeout=30
            )
            output = (result.stdout or result.stderr or "").strip()
            if output:
                send_message(output[:3500])
            else:
                send_message("HALO_STATUS completed, but no output was returned.")
        except Exception as e:
            send_message(f"HALO_STATUS failed: {e}")

    elif command in COMMANDS:
        label = command.replace("/", "Halo command ")
        run_command(COMMANDS[command], label)

    else:
        send_message("Unknown command. Send /help to see available commands.")

    return update_id

def main():
    log("Halo Telegram Gateway started")
    send_message("🟢 Halo Telegram Gateway is now online. Send /help.")

    while True:
        try:
            offset = get_offset()
            params = {
                "timeout": 25,
                "allowed_updates": json.dumps(["message", "edited_message"])
            }

            if offset is not None:
                params["offset"] = offset

            response = api_call("getUpdates", params)

            if response.get("ok"):
                for update in response.get("result", []):
                    update_id = process_update(update)
                    if update_id is not None:
                        save_offset(update_id + 1)

        except Exception as e:
            log(f"Gateway error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
