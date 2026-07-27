#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

# This repo does not publish a generated package/version table in the README.
# Keep the hook in place so the Alpine updater can share the same flow as other
# containeroo images without special-casing this repository.
exit 0
