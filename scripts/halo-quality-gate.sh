#!/usr/bin/env bash
set -u

SCRIPT_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
  pwd
)"

read_public_version() {
  local version

  version="$(
    sed -n \
      's/^\*\*Current public release:\*\* \(v[0-9][0-9.]*\).*/\1/p' \
      "$SCRIPT_ROOT/README.md" 2>/dev/null |
    head -1 ||
    true
  )"

  printf '%s\n' "${version:-unknown}"
}

usage() {
  cat <<'EOF'
Usage: halo-quality-gate [--help | --version]

Options:
  -h, --help   Show this help message.
  --version    Show the public release version.
EOF
}

print_version() {
  printf 'halo-quality-gate %s\n' "$(read_public_version)"
}

if [ "$#" -eq 0 ]; then
  :
elif [ "$#" -eq 1 ]; then
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
    --version)
      print_version
      exit 0
      ;;
    *)
      echo "Error: unsupported argument: ${1:-}" >&2
      usage >&2
      exit 2
      ;;
  esac
else
  echo "Error: halo-quality-gate accepts at most one option." >&2
  usage >&2
  exit 2
fi

ROOT="$SCRIPT_ROOT"
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
  "tests/public-safety.bats"
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

section "ShellCheck"

if ! command -v shellcheck >/dev/null 2>&1; then
  fail "ShellCheck is available"
  echo "  Install shellcheck before running the canonical quality gate."
else
  shellcheck_failures=0

  while IFS= read -r -d '' script; do
    if ! shellcheck -S style -e SC1091 "$script"; then
      shellcheck_failures=$((shellcheck_failures + 1))
    fi
  done < <(
    {
      printf '%s\0' "install.sh"
      find scripts -type f -name '*.sh' -print0
    }
  )

  if [ "$shellcheck_failures" -eq 0 ]; then
    pass "ShellCheck validation"
  else
    fail "ShellCheck validation"
  fi
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

section "Script documentation coverage"

undocumented_scripts=""

while IFS= read -r -d '' script; do
  if ! grep -qF "$script" README.md; then
    undocumented_scripts="${undocumented_scripts}${script}"$'\n'
  fi
done < <(find scripts -type f -name "*.sh" -print0)

if [ -z "$undocumented_scripts" ]; then
  pass "All scripts are documented in README"
else
  fail "All scripts are documented in README"
  printf '%s' "$undocumented_scripts" | sed 's/^/  /'
fi

section "Environment variable contract"

consumed_vars="$(
  grep -rhoE '\$\{HALO_[A-Z0-9_]+' scripts/ install.sh 2>/dev/null \
    | sed 's/^\${//' | sort -u
)"

declared_vars="$(
  grep -oE '^[[:space:]]*HALO_[A-Z0-9_]+=' .env.example 2>/dev/null \
    | tr -d ' =' | sort -u
)"

ALLOWLIST='HALO_PUBLIC_STATUS|HALO_BACKUP_DRYRUN|HALO_QUALITY_GATE|HALO_TELEGRAM_ENABLED|HALO_LOCAL_AI_ENABLED|HALO_MODEL_PROVIDER|HALO_MODEL_NAME'

orphans="$(
  comm -23 <(printf '%s\n' "$consumed_vars") <(printf '%s\n' "$declared_vars") \
    | grep -vE "^($ALLOWLIST)$" || true
)"

dead="$(
  comm -13 <(printf '%s\n' "$consumed_vars") <(printf '%s\n' "$declared_vars") \
    | grep -vE "^($ALLOWLIST)$" || true
)"

if [ -z "$orphans" ] && [ -z "$dead" ]; then
  pass "Environment variables match .env.example"
else
  fail "Environment variables match .env.example"
  [ -n "$orphans" ] && {
    echo "  Read by scripts but undocumented:"
    printf '%s\n' "$orphans" | sed 's/^/    /'
  }
  [ -n "$dead" ] && {
    echo "  Documented but unused:"
    printf '%s\n' "$dead" | sed 's/^/    /'
  }
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

changelog_version="$(
  sed -n     's/^## v\([0-9][0-9.]*\).*/v\1/p'     CHANGELOG.md | head -1
)"

if [ -n "$readme_version" ] &&
   [ "$readme_version" = "$versioning_version" ] &&
   [ "$readme_version" = "$demo_version" ] &&
   [ "$readme_version" = "$overview_version" ] &&
  [ "$readme_version" = "$changelog_version" ]; then
  pass "Current public version is consistent: $readme_version"
else
  fail "Current public version consistency"
  echo "  README:          ${readme_version:-missing}"
  echo "  VERSIONING:      ${versioning_version:-missing}"
  echo "  Demo output:     ${demo_version:-missing}"
  echo "  Project overview:${overview_version:-missing}"
  echo "  CHANGELOG:       ${changelog_version:-missing}"
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

section "Bats regression suite"

if ! command -v bats >/dev/null 2>&1; then
  fail "Bats is available"
  echo "  Install Bats before running the canonical quality gate."
else
  bats_log="$TMP_DIR/public-safety-bats.txt"
  bats_rc=0

  defined_bats_tests="$(
    grep -c '^@test ' tests/public-safety.bats ||
      true
  )"

  bats --tap tests/public-safety.bats \
    >"$bats_log" 2>&1 ||
    bats_rc=$?

  passed_bats_tests="$(
    grep -c '^ok [0-9][0-9]* ' "$bats_log" ||
      true
  )"

  if [ "$bats_rc" -eq 0 ] &&
     [ "$defined_bats_tests" -ge 5 ] &&
     [ "$defined_bats_tests" -le 6 ] &&
     [ "$passed_bats_tests" -eq "$defined_bats_tests" ]; then
    pass "Public safety Bats suite"
  else
    fail "Public safety Bats suite"
    echo "  Exit code: $bats_rc"
    echo "  Defined tests: $defined_bats_tests"
    echo "  Passed tests: $passed_bats_tests"
    tail -30 "$bats_log" | sed 's/^/  /'
  fi
fi

section "Demo output contract"

demo_output="$ROOT/docs/demo-output.md"
demo_contract_failed=0

if [ ! -f "$demo_output" ]; then
  fail "Demo output file is missing"
else
  for marker in \
    "HALO_PUBLIC_STATUS=GREEN" \
    "Security scan result: GREEN" \
    "Shell validation passed." \
    "## Public-Safe Principle" \
    "## What This Demo Proves"
  do
    marker_count="$(grep -cF -- "$marker" "$demo_output" || true)"

    if [ "$marker_count" -ne 1 ]; then
      fail "Demo output marker contract failed: $marker"
      demo_contract_failed=1
    fi
  done

  if [ "$demo_contract_failed" -eq 0 ]; then
    pass "Demo output contract"
  fi
fi

section "Runtime report bridge"

runtime_report="$TMP_DIR/halo-runtime-public-safe-report.txt"
runtime_report_rc=0
runtime_report_failed=0

bash scripts/halo-status.sh   --report-out "$runtime_report"   >/dev/null 2>&1 || runtime_report_rc=$?

if [ "$runtime_report_rc" -ne 0 ]; then
  runtime_report_failed=1
  echo "  halo-status.sh exited with code: $runtime_report_rc"
elif [ ! -f "$runtime_report" ]; then
  runtime_report_failed=1
  echo "  Runtime report was not created."
elif [ -L "$runtime_report" ]; then
  runtime_report_failed=1
  echo "  Runtime report must not be a symbolic link."
else
  runtime_report_bytes="$(
    wc -c <"$runtime_report" |
      tr -d ' '
  )"

  if [ "$runtime_report_bytes" -ge 65536 ]; then
    runtime_report_failed=1
    echo "  Runtime report exceeds the 64 KB limit."
  fi

  if ! grep -q '^HALO_PUBLIC_STATUS=' "$runtime_report"; then
    runtime_report_failed=1
    echo "  Runtime report is missing HALO_PUBLIC_STATUS."
  fi

  blocked_report_markers="$(
    printf '%s' \
      '(/Users/|~/\.ssh|192\.168\.|10\.0\.|172\.16\.|100\.|localhost|0\.0\.0\.0|' \
      'pass''word|to''ken|sec''ret|api''_key|api''key|BEGIN PRIVATE'' KEY)'
  )"

  if grep -qiE "$blocked_report_markers" "$runtime_report"; then
    runtime_report_failed=1
    echo "  Runtime report contains a blocked private marker."
  fi
fi

if [ "$runtime_report_failed" -eq 0 ]; then
  pass "Runtime report is agent-safe"
else
  fail "Runtime report is agent-safe"
fi

section "Runtime report CLI contract"

runtime_cli_failed=0
default_status_rc=0
missing_value_rc=0
extra_argument_rc=0
unknown_option_rc=0

default_status_log="$TMP_DIR/halo-status-default.txt"
missing_value_log="$TMP_DIR/halo-status-missing-value.txt"
extra_argument_log="$TMP_DIR/halo-status-extra-argument.txt"
unknown_option_log="$TMP_DIR/halo-status-unknown-option.txt"
extra_report="$TMP_DIR/halo-status-extra-report.txt"

bash scripts/halo-status.sh   >"$default_status_log" 2>&1 || default_status_rc=$?

bash scripts/halo-status.sh   --report-out   >"$missing_value_log" 2>&1 || missing_value_rc=$?

bash scripts/halo-status.sh   --report-out "$extra_report" extra   >"$extra_argument_log" 2>&1 || extra_argument_rc=$?

bash scripts/halo-status.sh   --unknown-option   >"$unknown_option_log" 2>&1 || unknown_option_rc=$?

if [ "$default_status_rc" -ne 0 ]; then
  runtime_cli_failed=1
  echo "  Default halo-status invocation exited with code: $default_status_rc"
elif ! grep -q '^HALO_PUBLIC_STATUS=' "$default_status_log"; then
  runtime_cli_failed=1
  echo "  Default halo-status output is missing HALO_PUBLIC_STATUS."
fi

if [ "$missing_value_rc" -ne 2 ]; then
  runtime_cli_failed=1
  echo "  Missing report path returned: $missing_value_rc"
fi

if [ "$extra_argument_rc" -ne 2 ]; then
  runtime_cli_failed=1
  echo "  Extra report argument returned: $extra_argument_rc"
fi

if [ "$unknown_option_rc" -ne 2 ]; then
  runtime_cli_failed=1
  echo "  Unsupported option returned: $unknown_option_rc"
fi

if [ -e "$extra_report" ]; then
  runtime_cli_failed=1
  echo "  Rejected extra-argument invocation created a report."
fi

if [ "$runtime_cli_failed" -eq 0 ]; then
  pass "Runtime report CLI contract"
else
  fail "Runtime report CLI contract"
fi

section "CLI help and version contract"

cli_contract_failed=0

cli_scripts=(
  "scripts/halo-status.sh"
  "scripts/halo-doctor.sh"
  "scripts/halo-quality-gate.sh"
  "scripts/halo-security-scan.sh"
  "scripts/halo-backup-dryrun.sh"
)

for cli_script in "${cli_scripts[@]}"; do
  cli_filename="$(basename "$cli_script")"
  cli_name="${cli_filename%.sh}"

  cli_help_log="$TMP_DIR/${cli_name}-help.txt"
  cli_short_help_log="$TMP_DIR/${cli_name}-short-help.txt"
  cli_version_log="$TMP_DIR/${cli_name}-version.txt"
  cli_unknown_log="$TMP_DIR/${cli_name}-unknown.txt"
  cli_extra_log="$TMP_DIR/${cli_name}-extra.txt"

  cli_help_rc=0
  cli_short_help_rc=0
  cli_version_rc=0
  cli_unknown_rc=0
  cli_extra_rc=0

  bash "$cli_script"     --help     >"$cli_help_log" 2>&1 ||
    cli_help_rc=$?

  bash "$cli_script"     -h     >"$cli_short_help_log" 2>&1 ||
    cli_short_help_rc=$?

  bash "$cli_script"     --version     >"$cli_version_log" 2>&1 ||
    cli_version_rc=$?

  bash "$cli_script"     --definitely-unsupported     >"$cli_unknown_log" 2>&1 ||
    cli_unknown_rc=$?

  bash "$cli_script"     --help extra     >"$cli_extra_log" 2>&1 ||
    cli_extra_rc=$?

  if [ "$cli_help_rc" -ne 0 ]; then
    cli_contract_failed=1
    echo "  $cli_name --help returned: $cli_help_rc"
  elif ! grep -qE     "^Usage: ${cli_name}"     "$cli_help_log"; then
    cli_contract_failed=1
    echo "  $cli_name --help is missing its Usage line."
  fi

  if [ "$cli_short_help_rc" -ne 0 ]; then
    cli_contract_failed=1
    echo "  $cli_name -h returned: $cli_short_help_rc"
  elif ! cmp -s     "$cli_help_log"     "$cli_short_help_log"; then
    cli_contract_failed=1
    echo "  $cli_name -h and --help outputs differ."
  fi

  expected_cli_version="${cli_name} ${readme_version}"
  actual_cli_version="$(cat "$cli_version_log")"

  if [ "$cli_version_rc" -ne 0 ]; then
    cli_contract_failed=1
    echo "  $cli_name --version returned: $cli_version_rc"
  elif [ "$actual_cli_version" != "$expected_cli_version" ]; then
    cli_contract_failed=1
    echo "  $cli_name --version output is incorrect."
    echo "    Expected: $expected_cli_version"
    echo "    Actual:   $actual_cli_version"
  fi

  if [ "$cli_unknown_rc" -ne 2 ]; then
    cli_contract_failed=1
    echo "  $cli_name unknown option returned: $cli_unknown_rc"
  elif ! grep -q '^Error:' "$cli_unknown_log"; then
    cli_contract_failed=1
    echo "  $cli_name unknown-option error message is missing."
  fi

  if [ "$cli_extra_rc" -ne 2 ]; then
    cli_contract_failed=1
    echo "  $cli_name extra argument returned: $cli_extra_rc"
  elif ! grep -q '^Error:' "$cli_extra_log"; then
    cli_contract_failed=1
    echo "  $cli_name extra-argument error message is missing."
  fi
done

if [ "$cli_contract_failed" -eq 0 ]; then
  pass "All functional scripts expose consistent CLI help and version contracts"
else
  fail "All functional scripts expose consistent CLI help and version contracts"
fi

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
