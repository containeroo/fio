#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Shared configuration
# =============================================================================
# Override any value for a single command, for example:
#   RUNTIME=120 RATE_IOPS=50 ./23-fdatasync-limited.sh
#
# All test data is destructive. Use only a dedicated, empty test PVC.

# Directory on the PVC under which fio creates all test files.
# Never point this to an OpenSearch data directory or any production data.
DATA_ROOT="${DATA_ROOT:-/data}"
DATA_DIR="${DATA_DIR:-${DATA_ROOT}/fio-test}"

# Container-local directory for fio JSON output, mountstats snapshots, and logs.
# Keeping results outside DATA_ROOT prevents result files from affecting the
# storage system being measured.
RESULT_DIR="${RESULT_DIR:-/tmp/fio-results}"
MOUNTSTATS_DIR="${MOUNTSTATS_DIR:-${RESULT_DIR}/mountstats}"

# fio I/O engine used by the tests. "sync" intentionally uses one outstanding
# I/O per job. Parallelism is introduced explicitly with NUMJOBS.
IOENGINE="${IOENGINE:-sync}"

# Use direct I/O where supported:
#   1 = request O_DIRECT and mostly bypass the Linux page cache
#   0 = use buffered I/O
# The fdatasync tests always use direct=0 because they measure buffered writes
# followed by synchronous persistence.
DIRECT="${DIRECT:-1}"

# Latency percentiles recorded in fio JSON output. p95, p99, and p99.9 are more
# useful for OpenSearch than average latency alone because they reveal stalls.
PERCENTILES="${PERCENTILES:-50:95:99:99.9}"

# =============================================================================
# Limited test profile
# =============================================================================
# These defaults are intentionally conservative, but they still generate real
# load. Run them only after the storage provider has approved the limits.

# Measured duration in seconds for each limited test.
RUNTIME="${RUNTIME:-60}"

# Warm-up duration in seconds. fio excludes this period from measured results.
# The total wall-clock duration is approximately RAMP_TIME + RUNTIME.
RAMP_TIME="${RAMP_TIME:-10}"

# Size of the file or test area used by one random-I/O job.
TEST_SIZE="${TEST_SIZE:-2G}"

# Size of the shared sequential test file used by the limited write/read tests.
LIMITED_SEQ_SIZE="${LIMITED_SEQ_SIZE:-8G}"

# Small write size used only by the initial direct-I/O compatibility check.
SANITY_SIZE="${SANITY_SIZE:-256M}"

# Maximum sequential write bandwidth for the limited test.
LIMITED_SEQ_WRITE_RATE="${LIMITED_SEQ_WRITE_RATE:-50M}"

# Maximum IOPS for the limited random-read test.
LIMITED_RAND_READ_IOPS="${LIMITED_RAND_READ_IOPS:-500}"

# Maximum IOPS for the limited random-write test.
LIMITED_RAND_WRITE_IOPS="${LIMITED_RAND_WRITE_IOPS:-250}"

# Maximum write-plus-fdatasync cycles per second for the limited sync test.
LIMITED_FDATASYNC_IOPS="${LIMITED_FDATASYNC_IOPS:-100}"

# Pause in seconds between tests when a suite is used. This gives the backend
# time to settle and makes individual test windows easier to identify.
TEST_PAUSE="${TEST_PAUSE:-30}"

# =============================================================================
# Full-load test profile
# =============================================================================
# These tests are intentionally unlimited and can significantly load a shared
# NFS backend. Run only after explicit provider approval.

# Measured duration and warm-up duration for full-load tests.
FULL_RUNTIME="${FULL_RUNTIME:-300}"
FULL_RAMP_TIME="${FULL_RAMP_TIME:-30}"

# Sequential file size used by the full write/read/random-read tests.
FULL_SEQ_SIZE="${FULL_SEQ_SIZE:-16G}"

# Test area per job for full random-write, mixed, and fdatasync tests.
# Total space can be FULL_TEST_SIZE_PER_JOB multiplied by FULL_NUMJOBS.
FULL_TEST_SIZE_PER_JOB="${FULL_TEST_SIZE_PER_JOB:-2G}"

# Number of parallel jobs used by the parallel full-load tests.
FULL_NUMJOBS="${FULL_NUMJOBS:-4}"

# Read percentage for the mixed random workload. The remaining percentage is
# writes. A value of 70 means 70% reads and 30% writes.
FULL_MIX_READ_PERCENT="${FULL_MIX_READ_PERCENT:-70}"

# Safety switch required by 91-run-full-suite.sh.
ALLOW_FULL_TESTS="${ALLOW_FULL_TESTS:-no}"

# =============================================================================
# Mountstats settings
# =============================================================================

# Label used by the manual before/after mountstats scripts.
MOUNTSTATS_LABEL="${MOUNTSTATS_LABEL:-manual}"

# =============================================================================
# Helper functions
# =============================================================================

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

warn() {
  printf 'WARNING: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "$command_name is not installed in this container."
}

require_fio() {
  require_command fio
}

ensure_directories() {
  mkdir -p "$DATA_DIR" "$RESULT_DIR" "$MOUNTSTATS_DIR"
}

assert_safe_data_dir() {
  case "$DATA_DIR" in
  "$DATA_ROOT"/*) ;;
  *) die "DATA_DIR must be below DATA_ROOT. DATA_ROOT=$DATA_ROOT DATA_DIR=$DATA_DIR" ;;
  esac

  [[ "$DATA_DIR" != "$DATA_ROOT" ]] || die "DATA_DIR must not be the PVC mount root itself."
  [[ "$DATA_DIR" != "/" ]] || die "Refusing to use / as DATA_DIR."
}

resolve_data_mountpoint() {
  ensure_directories
  df -P "$DATA_DIR" | awk 'NR == 2 { print $6 }'
}

sanitize_label() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

capture_mountstats() {
  local raw_label="${1:-snapshot}"
  local label
  local output_file
  local mountpoint

  label="$(sanitize_label "$raw_label")"
  output_file="${MOUNTSTATS_DIR}/${label}.txt"

  if [[ ! -r /proc/self/mountstats ]]; then
    warn "/proc/self/mountstats is not readable; no mountstats snapshot was created."
    return 0
  fi

  mountpoint="$(resolve_data_mountpoint)"

  if ! command -v mountstats >/dev/null 2>&1; then
    warn "mountstats is not installed; saving the full kernel mountstats file."
    cat /proc/self/mountstats >"$output_file"
  elif ! mountstats mountstats --raw "$mountpoint" >"$output_file"; then
    warn "No NFS mountstats section was found for mountpoint $mountpoint; saving the full kernel mountstats file."
    cat /proc/self/mountstats >"$output_file"
  fi

  log "Mountstats snapshot written to $output_file"
}

run_fio_test() {
  local test_name="$1"
  local output_file="$2"
  shift 2

  local status=0
  local started_at
  local finished_at
  local metadata_file="${RESULT_DIR}/${test_name}.metadata.txt"

  require_fio
  ensure_directories
  assert_safe_data_dir

  capture_mountstats "${test_name}-before"
  started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  log "Starting fio test: $test_name"

  if fio "$@" --output-format=json --output="$output_file"; then
    status=0
  else
    status=$?
  fi

  finished_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  capture_mountstats "${test_name}-after"

  {
    printf 'test_name=%s\n' "$test_name"
    printf 'started_at_utc=%s\n' "$started_at"
    printf 'finished_at_utc=%s\n' "$finished_at"
    printf 'exit_status=%s\n' "$status"
    printf 'hostname=%s\n' "$(hostname)"
    printf 'data_dir=%s\n' "$DATA_DIR"
    printf 'mountpoint=%s\n' "$(resolve_data_mountpoint)"
    printf 'fio_version=%s\n' "$(fio --version)"
  } >"$metadata_file"

  if ((status != 0)); then
    die "fio test $test_name failed with exit status $status."
  fi

  log "Completed fio test: $test_name"
  log "Result: $output_file"
}

pause_between_tests() {
  if ((TEST_PAUSE > 0)); then
    log "Pausing for ${TEST_PAUSE} seconds before the next test."
    sleep "$TEST_PAUSE"
  fi
}

print_context() {
  cat <<EOF_CONTEXT
DATA_ROOT=$DATA_ROOT
  PVC mount root.

DATA_DIR=$DATA_DIR
  Dedicated directory used for all destructive fio test files.

RESULT_DIR=$RESULT_DIR
  Container-local directory used for JSON results and diagnostics.

MOUNTSTATS_DIR=$MOUNTSTATS_DIR
  Directory containing before/after kernel NFS mountstats snapshots.

IOENGINE=$IOENGINE
  fio I/O engine. The default sync engine uses one outstanding I/O per job.

DIRECT=$DIRECT
  1 requests direct I/O where supported; 0 uses buffered I/O.

PERCENTILES=$PERCENTILES
  Latency percentiles recorded by fio.

RUNTIME=$RUNTIME
  Measured duration in seconds for limited tests.

RAMP_TIME=$RAMP_TIME
  Warm-up duration in seconds for limited tests.

TEST_SIZE=$TEST_SIZE
  File or test-area size per random-I/O job in the limited profile.

LIMITED_SEQ_SIZE=$LIMITED_SEQ_SIZE
  Shared file size for limited sequential write/read tests.

SANITY_SIZE=$SANITY_SIZE
  File size for the initial direct-I/O compatibility check.

LIMITED_SEQ_WRITE_RATE=$LIMITED_SEQ_WRITE_RATE
  Maximum bandwidth for the limited sequential write test.

LIMITED_RAND_READ_IOPS=$LIMITED_RAND_READ_IOPS
  Maximum IOPS for the limited random-read test.

LIMITED_RAND_WRITE_IOPS=$LIMITED_RAND_WRITE_IOPS
  Maximum IOPS for the limited random-write test.

LIMITED_FDATASYNC_IOPS=$LIMITED_FDATASYNC_IOPS
  Maximum write-plus-fdatasync cycles per second.

TEST_PAUSE=$TEST_PAUSE
  Pause between suite tests in seconds.

FULL_RUNTIME=$FULL_RUNTIME
  Measured duration in seconds for full-load tests.

FULL_RAMP_TIME=$FULL_RAMP_TIME
  Warm-up duration in seconds for full-load tests.

FULL_SEQ_SIZE=$FULL_SEQ_SIZE
  Sequential file size for full-load write/read/random-read tests.

FULL_TEST_SIZE_PER_JOB=$FULL_TEST_SIZE_PER_JOB
  Test-area size per job for parallel full-load tests.

FULL_NUMJOBS=$FULL_NUMJOBS
  Number of parallel jobs used by parallel full-load tests.

FULL_MIX_READ_PERCENT=$FULL_MIX_READ_PERCENT
  Read percentage for the mixed random workload.

ALLOW_FULL_TESTS=$ALLOW_FULL_TESTS
  91-run-full-suite.sh requires the exact value yes.

MOUNTSTATS_LABEL=$MOUNTSTATS_LABEL
  Label used by manual mountstats before/after scripts.
EOF_CONTEXT
}

ensure_directories
assert_safe_data_dir
