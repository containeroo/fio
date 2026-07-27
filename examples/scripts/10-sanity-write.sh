#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

run_fio_test \
  "10-sanity-write" \
  "$RESULT_DIR/10-sanity-write.json" \
  --name=sanity-write \
  --filename="$DATA_DIR/sanity.bin" \
  --rw=write \
  --bs=1M \
  --size="$SANITY_SIZE" \
  --ioengine="$IOENGINE" \
  --direct="$DIRECT" \
  --end_fsync=1 \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES"
