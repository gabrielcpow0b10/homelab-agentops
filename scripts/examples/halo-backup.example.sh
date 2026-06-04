#!/usr/bin/env bash
# Sanitized example only.
# This is not the private production script.

set -euo pipefail

echo "Manual backup workflow example"
echo "1. Confirm user intent"
echo "2. Check backup storage"
echo "3. Save system inventory"
echo "4. Save Docker inventory"
echo "5. Stop containers if needed"
echo "6. Archive important Docker volumes"
echo "7. Restart containers"
echo "8. Create checksums"
echo "9. Run restore test"
echo "10. Create final status report"
