#!/bin/bash
# Cleanup for Exercise 14 — Pod Security Standards
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
kubectl delete pod should-fail -n payments --ignore-not-found
kubectl delete pod would-warn -n payments-staging --ignore-not-found
