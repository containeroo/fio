#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "30-sequential-write-full" \
  "$RESULT_DIR/30-sequential-write-full.json" \
  --name=sequential-write-full \
  --filename="$DATA_DIR/sequential-full.bin" \
  --rw=write \
  --bs=1M \
  --size="$FULL_SEQ_SIZE" \
  --ioengine="$IOENGINE" \
  --direct="$DIRECT" \
  --time_based=1 \
  --runtime="$FULL_RUNTIME" \
  --ramp_time="$FULL_RAMP_TIME" \
  --end_fsync=1 \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
