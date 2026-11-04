#!/bin/bash
# Cleanup for Exercise 23 — Runtime Threat Detection
#
# Usage: KEY=~/workspace/cka-key.pem ./cleanup.sh <node-ip>
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found

NODE_IP="${1:-}"
KEY="${KEY:-$HOME/workspace/cka-key.pem}"

if [ -z "$NODE_IP" ]; then
  echo "Skipping Falco custom rule removal: no node IP given."
  echo "Re-run as: KEY=~/workspace/cka-key.pem ./cleanup.sh <node-ip>"
  exit 0
fi

ssh -i "$KEY" -o StrictHostKeyChecking=no "ubuntu@$NODE_IP" \
  'sudo rm -f /etc/falco/rules.d/custom-rules.yaml && sudo systemctl restart falco'
