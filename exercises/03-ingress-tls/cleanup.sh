#!/bin/bash
# Cleanup for Exercise 03 — Ingress with TLS
set -uo pipefail

kubectl delete -f "$(dirname "$0")/setup/" --ignore-not-found
kubectl delete ingress storefront -n shop --ignore-not-found
kubectl delete secret storefront-tls -n shop --ignore-not-found
helm uninstall ingress-nginx -n ingress-nginx || true
kubectl delete namespace ingress-nginx --ignore-not-found
