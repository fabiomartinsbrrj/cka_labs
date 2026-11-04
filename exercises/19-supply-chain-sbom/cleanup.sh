#!/bin/bash
# Cleanup for Exercise 19 — Understand Your Supply Chain (SBOM)
set -uo pipefail

cd "$(dirname "$0")"
rm -f sbom.cdx.json sbom.spdx.json
