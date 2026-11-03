# Exercise 03 — Ingress with TLS

## CKS Domain

**1. Cluster Setup** (15%)

## Competency

> Properly set up Ingress with TLS

## Context

The `shop` namespace runs `storefront`, exposed only as a `ClusterIP` Service today. The team wants it reachable from outside the cluster over **HTTPS only** — plain HTTP should redirect to HTTPS, not serve content.

This lab has no cloud load balancer, so the Ingress controller needs to run as a `NodePort` (or `hostNetwork`) instead of `LoadBalancer`.

## Requirements

1. Install an Ingress controller (`ingress-nginx`) configured as `NodePort`.
2. Generate a TLS certificate for `storefront.cks-lab.local` (a self-signed cert is fine for this lab) and store it as a `kubernetes.io/tls` Secret.
3. Create an `Ingress` for `storefront` that:
   - Routes `storefront.cks-lab.local` to the `storefront` Service
   - References your TLS Secret
   - Forces HTTP → HTTPS redirect (`nginx.ingress.kubernetes.io/ssl-redirect: "true"`, which is the default — make sure nothing disables it)
4. Prove it end-to-end: a plain HTTP request gets redirected, and an HTTPS request (ignoring the self-signed cert warning) returns the app's response.

## Setup

```bash
kubectl apply -f setup/
kubectl get pods -n shop -o wide
```

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  --set controller.service.type=NodePort
```

Find the NodePort assigned to the HTTPS port:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```
