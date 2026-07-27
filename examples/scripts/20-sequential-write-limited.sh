#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "20-sequential-write-limited" \
  "$RESULT_DIR/20-sequential-write-limited.json" \
  --name=sequential-write-limited \
  --filename="$DATA_DIR/sequential-limited.bin" \
  --rw=write \
  --bs=1M \
  --size="$LIMITED_SEQ_SIZE" \
  --ioengine="$IOENGINE" \
  --direct="$DIRECT" \
  --rate="$LIMITED_SEQ_WRITE_RATE" \
  --time_based=1 \
  --runtime="$RUNTIME" \
  --ramp_time="$RAMP_TIME" \
  --end_fsync=1 \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
