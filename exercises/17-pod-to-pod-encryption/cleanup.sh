#!/bin/bash
# Cleanup for Exercise 17 — Pod-to-Pod Encryption
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found

echo "WireGuard encryption was left enabled cluster-wide on purpose (it's a real hardening, not just"
echo "lab scaffolding). To disable it: cilium upgrade --set encryption.enabled=false"
