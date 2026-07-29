#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(
    cd "$BATS_TEST_DIRNAME/.." &&
    pwd
  )"

  BACKUP_SCRIPT="$REPO_ROOT/scripts/halo-backup-dryrun.sh"
  SECURITY_SCRIPT="$REPO_ROOT/scripts/halo-security-scan.sh"

  SECRET_FIXTURE="$REPO_ROOT/.halo-bats-secret-fixture.txt"
  RUNTIME_FIXTURE="$REPO_ROOT/.halo-bats-runtime-fixture.env"

  OUTSIDE_SOURCE="$BATS_TEST_TMPDIR/outside-source"
  BACKUP_TARGET="$BATS_TEST_TMPDIR/backup-target"

  rm -f \
    "$SECRET_FIXTURE" \
    "$RUNTIME_FIXTURE"

  rm -rf \
    "$OUTSIDE_SOURCE" \
    "$BACKUP_TARGET"

  mkdir -p "$OUTSIDE_SOURCE"
}

teardown() {
  rm -f \
    "$SECRET_FIXTURE" \
    "$RUNTIME_FIXTURE"

  rm -rf \
    "$OUTSIDE_SOURCE" \
    "$BACKUP_TARGET"
}

@test "backup dry-run completes safely with its default source" {
  cd "$REPO_ROOT"

  run env \
    -u HALO_BACKUP_SOURCE \
    -u HALO_BACKUP_TARGET \
    bash "$BACKUP_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Source safety: inside repository"* ]]
  [[ "$output" == *"HALO_BACKUP_DRYRUN=OK"* ]]
  [[ "$output" == *"No files copied."* ]]
}

@test "backup dry-run refuses a source outside the repository" {
  cd "$REPO_ROOT"

  run env \
    HALO_BACKUP_SOURCE="$OUTSIDE_SOURCE" \
    HALO_BACKUP_TARGET="$BACKUP_TARGET" \
    bash "$BACKUP_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Source safety: outside repository"* ]]
  [[ "$output" == *"Refusing to preview files outside the repository"* ]]
  [[ "$output" == *"HALO_BACKUP_DRYRUN=REFUSED_OUTSIDE_REPO"* ]]
  [[ "$output" == *"No files copied."* ]]
}

@test "backup dry-run never creates the requested target" {
  cd "$REPO_ROOT"

  run env \
    HALO_BACKUP_SOURCE="$REPO_ROOT" \
    HALO_BACKUP_TARGET="$BACKUP_TARGET" \
    bash "$BACKUP_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"HALO_BACKUP_DRYRUN=OK"* ]]
  [ ! -e "$BACKUP_TARGET" ]
}

@test "strict security scan passes on the clean repository" {
  cd "$REPO_ROOT"

  run bash "$SECURITY_SCRIPT" --strict

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mode: strict"* ]]
  [[ "$output" == *"Secret assignment scan: OK"* ]]
  [[ "$output" == *"Forbidden runtime file scan: OK"* ]]
  [[ "$output" == *"Security scan result: GREEN"* ]]
}

@test "security scan detects and recovers from a synthetic secret" {
  cd "$REPO_ROOT"

  secret_name="API""_KEY"
  secret_value="q7W8e9R0t1Y2u3I4o5P6"

  printf '%s=%s\n' \
    "$secret_name" \
    "$secret_value" \
    >"$SECRET_FIXTURE"

  run bash "$SECURITY_SCRIPT" --strict

  [ "$status" -eq 1 ]
  [[ "$output" == *".halo-bats-secret-fixture.txt"* ]]
  [[ "$output" == *"Secret assignment scan: REVIEW REQUIRED"* ]]
  [[ "$output" == *"Security scan result: REVIEW REQUIRED"* ]]

  rm -f "$SECRET_FIXTURE"

  run bash "$SECURITY_SCRIPT" --strict

  [ "$status" -eq 0 ]
  [[ "$output" == *"Security scan result: GREEN"* ]]
}

@test "security scan detects and recovers from a forbidden runtime file" {
  cd "$REPO_ROOT"

  printf '%s\n' \
    "HALO_BATS_MODE=disabled" \
    >"$RUNTIME_FIXTURE"

  run bash "$SECURITY_SCRIPT" --strict

  [ "$status" -eq 1 ]
  [[ "$output" == *".halo-bats-runtime-fixture.env"* ]]
  [[ "$output" == *"Forbidden runtime file scan: REVIEW REQUIRED"* ]]
  [[ "$output" == *"Security scan result: REVIEW REQUIRED"* ]]

  rm -f "$RUNTIME_FIXTURE"

  run bash "$SECURITY_SCRIPT" --strict

  [ "$status" -eq 0 ]
  [[ "$output" == *"Security scan result: GREEN"* ]]
}
