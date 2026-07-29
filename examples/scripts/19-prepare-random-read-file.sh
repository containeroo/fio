#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

require_fio

# These defaults are also added to 00-common.sh by the update script.
READ_FILE="${READ_FILE:-$DATA_DIR/random-read-source.bin}"
READ_FILE_SIZE="${READ_FILE_SIZE:-2G}"
PREP_RATE="${PREP_RATE:-50M}"

# Create the complete source file before the measured random-read workload.
# This is intentionally not time-based: exactly READ_FILE_SIZE is written.
fio \
  --name=prepare-random-read-file \
  --filename="$READ_FILE" \
  --rw=write \
  --bs=1M \
  --size="$READ_FILE_SIZE" \
  --ioengine=sync \
  --direct="$DIRECT" \
  --rate="$PREP_RATE" \
  --end_fsync=1 \
  --group_reporting \
  --lat_percentiles=1 \
  --percentile_list="$PERCENTILES" \
  --output-format=json \
  --output="$RESULT_DIR/19-prepare-random-read-file.json"
