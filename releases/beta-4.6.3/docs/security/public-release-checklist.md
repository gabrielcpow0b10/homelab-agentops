# Sanitization Checklist

Before publishing:

- [ ] No Telegram token
- [ ] No real chat ID
- [ ] No .env file
- [ ] No NAS password
- [ ] No private SSH key
- [ ] No private API key
- [ ] No raw personal logs
- [ ] No sensitive IP/Tailscale details unless intentionally generalized
- [ ] No private filesystem paths that expose personal data unnecessarily
- [ ] Scripts are examples or sanitized production-safe excerpts
