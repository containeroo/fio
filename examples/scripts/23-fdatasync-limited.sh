#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "23-fdatasync-limited" \
  "$RESULT_DIR/23-fdatasync-limited.json" \
  --name=fdatasync-16k-limited \
  --filename="$DATA_DIR/fdatasync-limited.bin" \
  --rw=write \
  --bs=16k \
  --size="$TEST_SIZE" \
  --ioengine="$IOENGINE" \
  --direct=0 \
  --fdatasync=1 \
  --rate_iops="$LIMITED_FDATASYNC_IOPS" \
  --time_based=1 \
  --runtime="$RUNTIME" \
  --ramp_time="$RAMP_TIME" \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
