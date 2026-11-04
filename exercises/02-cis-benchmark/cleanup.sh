#!/bin/bash
# Cleanup for Exercise 02 — CIS Benchmark
set -uo pipefail

echo "Nothing to clean up in the cluster — this exercise only runs kube-bench and edits node-level config/permissions."
echo "If you want to remove the kube-bench binary/tarball you downloaded on the node, SSH in and:"
echo "  rm -f kube-bench kube-bench.tar.gz"
