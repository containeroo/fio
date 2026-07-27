#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "34-mixed-16k-full" \
  "$RESULT_DIR/34-mixed-16k-full.json" \
  --name=mixed-16k-full \
  --directory="$DATA_DIR" \
  --filename_format='mixed-16k.$jobnum' \
  --rw=randrw \
  --rwmixread="$FULL_MIX_READ_PERCENT" \
  --bs=16k \
  --size="$FULL_TEST_SIZE_PER_JOB" \
  --numjobs="$FULL_NUMJOBS" \
  --ioengine="$IOENGINE" \
  --direct="$DIRECT" \
  --time_based=1 \
  --runtime="$FULL_RUNTIME" \
  --ramp_time="$FULL_RAMP_TIME" \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
