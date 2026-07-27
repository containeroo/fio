#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

test_file="$DATA_DIR/sequential-limited.bin"
[[ -f "$test_file" ]] || die "$test_file does not exist. Run 20-sequential-write-limited.sh first."

run_fio_test \
  "21-random-read-limited" \
  "$RESULT_DIR/21-random-read-limited.json" \
  --name=random-read-4k-limited \
  --filename="$test_file" \
  --rw=randread \
  --bs=4k \
  --size="$LIMITED_SEQ_SIZE" \
  --ioengine="$IOENGINE" \
  --direct="$DIRECT" \
  --invalidate=1 \
  --rate_iops="$LIMITED_RAND_READ_IOPS" \
  --time_based=1 \
  --runtime="$RUNTIME" \
  --ramp_time="$RAMP_TIME" \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
