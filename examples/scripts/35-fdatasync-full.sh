#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "35-fdatasync-full" \
  "$RESULT_DIR/35-fdatasync-full.json" \
  --name=fdatasync-16k-full \
  --directory="$DATA_DIR" \
  --filename_format='fdatasync-16k.$jobnum' \
  --rw=write \
  --bs=16k \
  --size="$FULL_TEST_SIZE_PER_JOB" \
  --numjobs="$FULL_NUMJOBS" \
  --ioengine="$IOENGINE" \
  --direct=0 \
  --fdatasync=1 \
  --time_based=1 \
  --runtime="$FULL_RUNTIME" \
  --ramp_time="$FULL_RAMP_TIME" \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
