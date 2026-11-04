#!/bin/bash
# Cleanup for Exercise 20 — Secure Your Supply Chain (Registries, Signing)
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
kubectl delete pod approved unapproved -n supply-chain-demo --ignore-not-found
