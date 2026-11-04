#!/bin/bash
# Cleanup for Exercise 15 — Kubernetes Secrets Management
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
