#!/bin/bash
# Cleanup for Exercise 04 — Protect Node Metadata and Endpoints
set -uo pipefail

kubectl delete pod metadata-probe --ignore-not-found

echo "Note: the Terraform metadata_options change and the cluster-wide NetworkPolicy are intentional"
echo "hardening, not disposable lab objects — this script does not revert them."
