#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

before_file="${1:-${MOUNTSTATS_DIR}/${MOUNTSTATS_LABEL}-before.txt}"
after_file="${2:-${MOUNTSTATS_DIR}/${MOUNTSTATS_LABEL}-after.txt}"

[[ -f "$before_file" ]] || die "Before snapshot not found: $before_file"
[[ -f "$after_file" ]] || die "After snapshot not found: $after_file"
require_command mountstats

mountpoint="$(awk '$1 == "device" { print $5; exit }' "$after_file")"
[[ -n "$mountpoint" ]] || die "No NFS mountpoint found in snapshot: $after_file"

mountstats mountstats \
  --rpc \
  --file "$after_file" \
  --since "$before_file" \
  "$mountpoint"
