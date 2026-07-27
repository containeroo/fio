#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "22-random-write-limited" \
  "$RESULT_DIR/22-random-write-limited.json" \
  --name=random-write-16k-limited \
  --filename="$DATA_DIR/random-write-limited.bin" \
  --rw=randwrite \
  --bs=16k \
  --size="$TEST_SIZE" \
  --ioengine="$IOENGINE" \
  --direct="$DIRECT" \
  --rate_iops="$LIMITED_RAND_WRITE_IOPS" \
  --time_based=1 \
  --runtime="$RUNTIME" \
  --ramp_time="$RAMP_TIME" \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
