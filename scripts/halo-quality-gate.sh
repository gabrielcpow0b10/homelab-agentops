#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

passed=0
failed=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

section() {
  echo
  echo "== $1 =="
}

pass() {
  echo "[PASS] $1"
  passed=$((passed + 1))
}

fail() {
  echo "[FAIL] $1"
  failed=$((failed + 1))
}

run_with_marker() {
  local label="$1"
  local marker="$2"
  shift 2

  local output_file
  local result_code=0

  output_file="$(mktemp "$TMP_DIR/check.XXXXXX")"
  "$@" >"$output_file" 2>&1 || result_code=$?

  if [ "$result_code" -eq 0 ] && grep -Fq "$marker" "$output_file"; then
    pass "$label"
  else
    fail "$label"
    echo "  Exit code: $result_code"
    echo "  Expected marker: $marker"
    tail -20 "$output_file" | sed 's/^/  /'
  fi
}

echo "HomeLab AgentOps Public Quality Gate"
echo "===================================="

section "Required public files"

required_files=(
  "README.md"
  "VERSIONING.md"
  "SECURITY.md"
  "CONTRIBUTING.md"
  "install.sh"
  "scripts/halo-security-scan.sh"
  "scripts/halo-backup-dryrun.sh"
  "scripts/halo-doctor.sh"
  "scripts/halo-status.sh"
  "scripts/halo-quality-gate.sh"
  ".github/workflows/security-scan.yml"
  ".github/workflows/shell-validation.yml"
  ".github/workflows/quality-gate.yml"
)

missing_files=0

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing: $file"
    missing_files=$((missing_files + 1))
  fi
done

if [ "$missing_files" -eq 0 ]; then
  pass "Required public files are present"
else
  fail "Required public files are present"
fi

section "Shell syntax"

syntax_failed=0

if ! bash -n install.sh; then
  syntax_failed=1
fi

while IFS= read -r -d '' file; do
  if ! bash -n "$file"; then
    syntax_failed=1
  fi
done < <(find scripts -type f -name "*.sh" -print0)

if [ "$syntax_failed" -eq 0 ]; then
  pass "Shell syntax validation"
else
  fail "Shell syntax validation"
fi

section "Whitespace"

whitespace_hits="$(
  git ls-files -z 2>/dev/null \
    | xargs -0 grep -nE ' +$' -- 2>/dev/null \
    | grep -vE '\.(png|jpg|jpeg|gif|ico|pdf)' \
    || true
)"

if [ -z "$whitespace_hits" ]; then
  pass "Trailing whitespace validation"
else
  fail "Trailing whitespace validation"
  printf '%s\n' "$whitespace_hits" | head -20 | sed 's/^/  /'
fi

section "Current public version"

readme_version="$(
  sed -n \
    's/^\*\*Current public release:\*\* \(v[0-9][0-9.]*\).*/\1/p' \
    README.md | head -1
)"

versioning_version="$(
  awk '
    /^## Current Public Release$/ {
      in_section = 1
      next
    }

    in_section && /^\*\*v[0-9]/ {
      line = $0
      sub(/^\*\*/, "", line)
      sub(/[[:space:]].*$/, "", line)
      print line
      exit
    }
  ' VERSIONING.md
)"

demo_version="$(
  sed -n \
    's/^Public release: \(v[0-9][0-9.]*\).*/\1/p' \
    docs/demo-output.md | head -1
)"

overview_version="$(
  sed -n \
    's/^The current public milestone is \(v[0-9][0-9.]*\).*/\1/p' \
    docs/project-overview.md | head -1
)"

if [ -n "$readme_version" ] &&
   [ "$readme_version" = "$versioning_version" ] &&
   [ "$readme_version" = "$demo_version" ] &&
   [ "$readme_version" = "$overview_version" ]; then
  pass "Current public version is consistent: $readme_version"
else
  fail "Current public version consistency"
  echo "  README:          ${readme_version:-missing}"
  echo "  VERSIONING:      ${versioning_version:-missing}"
  echo "  Demo output:     ${demo_version:-missing}"
  echo "  Project overview:${overview_version:-missing}"
fi

section "Canonical public tree"

if [ ! -e "releases/beta-4.6.3" ]; then
  pass "Legacy Beta archive is absent from the canonical tree"
else
  fail "Legacy Beta archive is absent from the canonical tree"
fi

legacy_references="$(
  grep -RInE \
    'releases/beta-4\.6\.3|public sanitized draft' \
    README.md QUICKSTART.md VERSIONING.md docs .github \
    2>/dev/null || true
)"

if [ -z "$legacy_references" ]; then
  pass "No active legacy Beta references"
else
  fail "No active legacy Beta references"
  printf '%s\n' "$legacy_references" | sed 's/^/  /'
fi

section "Public security"

run_with_marker \
  "Strict public security scan" \
  "Security scan result: GREEN" \
  bash scripts/halo-security-scan.sh --strict

section "Backup dry-run"

run_with_marker \
  "Public backup dry-run" \
  "HALO_BACKUP_DRYRUN=OK" \
  bash scripts/halo-backup-dryrun.sh

section "Host diagnostics"

echo "halo-doctor.sh and halo-status.sh are intentionally non-blocking."
echo "They report host-specific conditions and are not required for CI success."

echo
echo "== Summary =="
echo "Passed: $passed"
echo "Failed: $failed"

if [ "$failed" -eq 0 ]; then
  echo "HALO_QUALITY_GATE=GREEN"
  exit 0
fi

echo "HALO_QUALITY_GATE=RED"
exit 1
