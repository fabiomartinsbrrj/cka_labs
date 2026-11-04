#!/bin/bash
# Cleanup for Exercise 06 — RBAC Least Privilege
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
kubectl delete clusterrole ops-bot-reader --ignore-not-found
kubectl delete clusterrolebinding ops-bot-reader --ignore-not-found
