#!/bin/bash
# Cleanup for Exercise 24 — Immutability of Containers at Runtime
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
