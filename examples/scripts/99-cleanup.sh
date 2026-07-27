#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

assert_safe_data_dir

if [[ "${CONFIRM_CLEANUP:-no}" != "yes" ]]; then
  cat >&2 <<EOF_MESSAGE
Refusing to delete test data without explicit confirmation.
The following directories would be removed:
  DATA_DIR=$DATA_DIR
  RESULT_DIR=$RESULT_DIR

Run with:
  CONFIRM_CLEANUP=yes $0
EOF_MESSAGE
  exit 1
fi

rm -rf -- "$DATA_DIR"
rm -rf -- "$RESULT_DIR"
printf 'Removed %s and %s\n' "$DATA_DIR" "$RESULT_DIR"
