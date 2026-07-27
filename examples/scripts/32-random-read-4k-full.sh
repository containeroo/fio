#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

test_file="$DATA_DIR/sequential-full.bin"
[[ -f "$test_file" ]] || die "$test_file does not exist. Run 30-sequential-write-full.sh first."

run_fio_test \
  "32-random-read-4k-full" \
  "$RESULT_DIR/32-random-read-4k-full.json" \
  --name=random-read-4k-full \
  --filename="$test_file" \
  --rw=randread \
  --bs=4k \
  --size="$FULL_SEQ_SIZE" \
  --ioengine="$IOENGINE" \
  --direct="$DIRECT" \
  --invalidate=1 \
  --time_based=1 \
  --runtime="$FULL_RUNTIME" \
  --ramp_time="$FULL_RAMP_TIME" \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
