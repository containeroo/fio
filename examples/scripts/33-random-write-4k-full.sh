#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "33-random-write-4k-full" \
  "$RESULT_DIR/33-random-write-4k-full.json" \
  --name=random-write-4k-full \
  --directory="$DATA_DIR" \
  --filename_format='random-write-4k.$jobnum' \
  --rw=randwrite \
  --bs=4k \
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
