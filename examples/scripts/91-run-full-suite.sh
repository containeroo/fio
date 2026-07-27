#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

if [[ "$ALLOW_FULL_TESTS" != "yes" ]]; then
  cat >&2 <<'MSG'
Refusing to run the unlimited full-load suite.
Run it only after explicit storage-provider approval and set:
  ALLOW_FULL_TESTS=yes
MSG
  exit 1
fi

"$SCRIPT_DIR/01-storage-info.sh"
"$SCRIPT_DIR/30-sequential-write-full.sh"
pause_between_tests
"$SCRIPT_DIR/31-sequential-read-full.sh"
pause_between_tests
"$SCRIPT_DIR/32-random-read-4k-full.sh"
pause_between_tests
"$SCRIPT_DIR/33-random-write-4k-full.sh"
pause_between_tests
"$SCRIPT_DIR/34-mixed-16k-full.sh"
pause_between_tests
"$SCRIPT_DIR/35-fdatasync-full.sh"

log "Full suite completed. Results are in $RESULT_DIR."
