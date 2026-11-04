#!/bin/bash
# Cleanup for Exercise 05 — Verify Platform Binaries Before Deploying
set -uo pipefail

cd "$(dirname "$0")"
rm -f kubectl kubectl.sha256

echo "Nothing to clean up in the cluster. If you refactored scripts/fase2-control.sh, that change is intentional"
echo "and not reverted by this script."
