#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

test_file="$DATA_DIR/sequential-full.bin"
[[ -f "$test_file" ]] || die "$test_file does not exist. Run 30-sequential-write-full.sh first."

run_fio_test \
  "31-sequential-read-full" \
  "$RESULT_DIR/31-sequential-read-full.json" \
  --name=sequential-read-full \
  --filename="$test_file" \
  --rw=read \
  --bs=1M \
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
