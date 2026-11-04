#!/bin/bash
# Cleanup for Exercise 21 — Static Analysis of Workloads and Images
set -uo pipefail

cd "$(dirname "$0")"
rm -f baseline-scan.txt fixed-scan.txt
