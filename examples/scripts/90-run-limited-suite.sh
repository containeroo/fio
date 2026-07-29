#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

cat <<'MSG'
This suite generates real NFS load even though bandwidth and IOPS are limited.
Run it only after the storage provider has approved the configured limits.
MSG

"$SCRIPT_DIR/01-storage-info.sh"
"$SCRIPT_DIR/10-sanity-write.sh"
pause_between_tests
"$SCRIPT_DIR/20-sequential-write-limited.sh"
pause_between_tests
"$SCRIPT_DIR/19-prepare-random-read-file.sh"
"$SCRIPT_DIR/21-random-read-limited.sh"
pause_between_tests
"$SCRIPT_DIR/22-random-write-limited.sh"
pause_between_tests
"$SCRIPT_DIR/23-fdatasync-limited.sh"

log "Limited suite completed. Results are in $RESULT_DIR."
