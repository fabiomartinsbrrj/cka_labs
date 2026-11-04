#!/bin/bash
# Cleanup for Exercise 07 — Service Account Hardening
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
