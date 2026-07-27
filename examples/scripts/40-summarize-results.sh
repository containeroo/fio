#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

require_command jq

shopt -s nullglob
result_files=("$RESULT_DIR"/*.json)
(( ${#result_files[@]} > 0 )) || die "No fio JSON result files found in $RESULT_DIR."

for result_file in "${result_files[@]}"; do
  echo "=== $(basename "$result_file") ==="
  printf 'job\tread_iops\tread_MiB/s\twrite_iops\twrite_MiB/s\tread_p95_ms\tread_p99_ms\twrite_p95_ms\twrite_p99_ms\tsync_p95_ms\tsync_p99_ms\n'

  jq -r '
    .jobs[] |
    [
      .jobname,
      (.read.iops // 0),
      ((.read.bw_bytes // 0) / 1048576),
      (.write.iops // 0),
      ((.write.bw_bytes // 0) / 1048576),
      ((.read.clat_ns.percentile["95.000000"] // 0) / 1000000),
      ((.read.clat_ns.percentile["99.000000"] // 0) / 1000000),
      ((.write.clat_ns.percentile["95.000000"] // 0) / 1000000),
      ((.write.clat_ns.percentile["99.000000"] // 0) / 1000000),
      ((.sync.lat_ns.percentile["95.000000"] // 0) / 1000000),
      ((.sync.lat_ns.percentile["99.000000"] // 0) / 1000000)
    ] | @tsv
  ' "$result_file"
  echo

done
