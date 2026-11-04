#!/bin/bash
# Cleanup for Exercise 01 — Cross-Namespace Connectivity Restrictions
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
