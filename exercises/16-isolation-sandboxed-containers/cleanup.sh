#!/bin/bash
# Cleanup for Exercise 16 — Isolation Techniques (Multi-Tenancy, Sandboxed Containers)
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
kubectl delete runtimeclass gvisor-runsc --ignore-not-found
