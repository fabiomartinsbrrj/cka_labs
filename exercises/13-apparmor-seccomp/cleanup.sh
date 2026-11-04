#!/bin/bash
# Cleanup for Exercise 13 — Kernel Hardening Tools (AppArmor, Seccomp)
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
