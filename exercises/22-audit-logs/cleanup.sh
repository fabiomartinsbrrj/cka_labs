#!/bin/bash
# Cleanup for Exercise 22 — Kubernetes Audit Logs
set -uo pipefail

kubectl delete secret probe-secret -n default --ignore-not-found
kubectl delete pod audit-probe --ignore-not-found

echo "Note: the audit policy and kube-apiserver flags on the controlplane are intentional hardening"
echo "and are not reverted by this script."
