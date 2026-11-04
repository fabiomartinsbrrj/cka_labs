#!/bin/bash
# Cleanup for Exercise 18 — Minimize Base Image Footprint
set -uo pipefail

docker rmi hello-flask:insecure hello-flask:hardened 2>/dev/null || true
