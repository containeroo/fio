#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

require_fio
print_context

echo
echo "fio version:"
fio --version

echo
echo "Filesystem:"
df -hT "$DATA_DIR"

echo
echo "Resolved mountpoint:"
resolve_data_mountpoint

echo
echo "Mount details:"
mountpoint="$(resolve_data_mountpoint)"
awk -v path="$mountpoint" '$2 == path { print }' /proc/mounts || true

echo
echo "All NFS mounts visible in this container:"
grep -E ' nfs4? ' /proc/mounts || true

echo
echo "Kernel NFS mountstats snapshot:"
capture_mountstats "storage-info"
cat "$MOUNTSTATS_DIR/storage-info.txt"
