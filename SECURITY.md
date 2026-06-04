# Security Model

This repository is the public/sanitized version of a private HomeLab AgentOps project.

The private system contains real operational configuration, environment files, logs, reports, backup paths, and internal details. Those private materials must not be published here.

---

## Public repository security scope

This repository is safe for public review because it is documentation-first and sanitized.

It may include:

- public architecture explanations,
- sanitized runbooks,
- example scripts,
- placeholder paths,
- general security principles,
- public-safe roadmap items,
- and non-sensitive workflow descriptions.

It must not include:

- real credentials,
- real `.env` files,
- Telegram bot tokens,
- API keys,
- private keys,
- NAS or SMB credentials,
- real backup archives,
- private logs,
- screenshots with sensitive information,
- internal production configuration,
- or unrestricted remote execution scripts.

---

## Do not commit

Never commit the following:

```text
.env
*.env
telegram.env
*.key
*.pem
*.p12
*.log
*.tar.gz
*.zip
private backups
private screenshots
real tokens
real passwords
real NAS credentials
real SMB credentials
real SSH private keys
```

---

## Recommended pre-push checks

Before pushing to GitHub, run checks similar to these from the repository root:

```bash
grep -RniE "BOT_TOKEN=|CHAT_ID=|PASSWORD=|TOKEN=|SECRET=|API_KEY=|OPENAI_API_KEY=|GITHUB_TOKEN=|ghp_|sk-|xoxb-|BEGIN .*PRIVATE|PRIVATE KEY|192\.168\.|100\.[0-9]+\." . || echo "SAFE: no real secret patterns found."

find . -type f \( \
  -name "*.env" -o \
  -name ".env" -o \
  -name "*.tar.gz" -o \
  -name "*.zip" -o \
  -name "*.log" -o \
  -name "*.key" -o \
  -name "*.pem" -o \
  -name "*.p12" \
\)
```

If either command prints something suspicious, stop and review before committing.

---

## Operational safety model

The private HomeLab follows a conservative operations model:

- no public administrative ports,
- private access only,
- no arbitrary Telegram shell execution,
- whitelisted Telegram commands only,
- manual maintenance workflows,
- dry-run before cleanup,
- safe-trash-only deletion,
- backup verification before trust,
- and public/private documentation separation.

---

## Telegram gateway safety

The Telegram gateway model is designed for controlled operations, not unrestricted remote administration.

Required principles:

- use an authorized chat check,
- map commands to a whitelist,
- avoid `/shell`, `/run`, `/exec`, `/bash`, or equivalent commands,
- avoid accepting free-text shell input,
- keep full logs local,
- send compact responses to Telegram,
- store tokens outside the repository,
- and restrict secret file permissions.

A safe Telegram gateway triggers known workflows. It should not become a remote terminal.

---

## Backup safety

Backups should be treated carefully because they may contain private configuration.

Public documentation can describe backup strategy, but it must not include:

- real backup archives,
- private backup paths that reveal sensitive layout,
- tokens inside backup manifests,
- private logs,
- or secret-containing configuration files.

A backup is not considered reliable until at least one restore test has been performed.

---

## NAS-safe monitoring

Scheduled monitoring should avoid unnecessary NAS access.

The reason is simple: repeated checks against mounted NAS paths can prevent standby and create avoidable disk activity.

Recommended model:

- lightweight scheduled checks avoid NAS reads,
- manual maintenance can inspect NAS intentionally,
- backup workflows touch NAS intentionally,
- documentation workflows touch NAS intentionally,
- NAS standby should not automatically be treated as a critical failure.

---

## Public documentation rules

When preparing public documentation:

- replace real paths with placeholders,
- remove private IPs and Tailscale IPs,
- remove usernames if they are not needed,
- remove screenshots with sensitive information,
- remove tokens, secrets, keys, and logs,
- use `.env.example` instead of `.env`,
- and review diffs before every commit.

---

## Incident response

If a secret is accidentally committed:

1. Remove it immediately from the repository.
2. Rotate or revoke the exposed secret.
3. Assume the secret was compromised.
4. Review commit history and public forks if applicable.
5. Replace the secret with a placeholder example.
6. Add or improve `.gitignore` rules.

Deleting a file from the latest commit is not enough if the secret exists in Git history. Rotate the secret.

---

## Security posture summary

HomeLab AgentOps is designed to show professional security thinking at HomeLab scale:

- private access,
- sanitized publication,
- controlled automation,
- recoverable operations,
- safe maintenance,
- and no public exposure of administrative control surfaces.
