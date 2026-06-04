# Public Release Security Checklist

This checklist must be reviewed before every public release or public push.

HomeLab AgentOps is a public/sanitized repository. The private HomeLab contains real operational data that must never be published here.

---

## 1. Files that must never be public

Do not publish:

- `.env`
- `telegram.env`
- real tokens
- real passwords
- API keys
- GitHub tokens
- private keys
- SSH private keys
- NAS credentials
- SMB credentials
- real backup archives
- private logs
- private reports
- private screenshots
- internal production configuration

---

## 2. Pre-push commands

Run these before committing or pushing:

```bash
git status
halo-security-scan
halo-doctor
