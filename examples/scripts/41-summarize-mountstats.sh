#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

shopt -s nullglob
before_files=("$MOUNTSTATS_DIR"/*-before.txt)
(( ${#before_files[@]} > 0 )) || die "No mountstats before snapshots found in $MOUNTSTATS_DIR."

for before_file in "${before_files[@]}"; do
  base_name="$(basename "$before_file" -before.txt)"
  after_file="$MOUNTSTATS_DIR/${base_name}-after.txt"

  if [[ ! -f "$after_file" ]]; then
    warn "Skipping $base_name because the after snapshot is missing."
    continue
  fi

  echo "=== $base_name ==="
  "$SCRIPT_DIR/05-mountstats-op-delta.sh" "$before_file" "$after_file"
  echo

done
