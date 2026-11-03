# Exercise 17 — Pod-to-Pod Encryption

## CKS Domain

**4. Minimize Microservice Vulnerabilities** (20%)

## Competency

> Implement Pod-to-Pod encryption (Cilium, Istio)

## Context

This cluster's CNI is Cilium (installed by `scripts/fase2-control.sh`), but by default Cilium does **not** encrypt pod-to-pod traffic — packets between pods on different nodes travel over the underlying VPC network in plaintext. Namespace `secure-mesh` has a `client` Deployment and a `server` Deployment (a plain HTTP server) scheduled on **different nodes**, so their traffic actually crosses the wire between EC2 instances.

## Requirements

1. Enable Cilium **Transparent Encryption** using **WireGuard** cluster-wide (no application code changes, no sidecars).
2. Confirm via `cilium encrypt status` that WireGuard is enabled and that there is an active, healthy tunnel between your nodes.
3. Prove the encryption is real, not just configured: capture traffic on each node's **physical interface** (not `cilium_wg0`) with `tcpdump` while `client` calls `server`, before and after enabling encryption, and show the HTTP payload is readable before and unreadable after.

## Setup

```bash
kubectl apply -f setup/
```

```bash
kubectl get pods -n secure-mesh -o wide
```

Confirm `client` and `server` landed on different nodes (check the `NODE` column). The default 2-node lab only has `controlplane` and `node01`, so `client` is pinned to `controlplane` (with a toleration for its `NoSchedule` taint) and `server` to `node01`. If your lab has more/different node names, adjust `nodeName` in `setup/01-workloads.yaml`.

## Baseline capture (before your fix)

On the node running `server`:

```bash
ssh -i $KEY ubuntu@<server-node-ip> 'sudo tcpdump -i <iface> -A -s 0 "tcp port 80"'
```

In another terminal, generate traffic:

```bash
kubectl exec -n secure-mesh deploy/client -- wget -qO- server.secure-mesh.svc.cluster.local
```

You should see the plaintext HTTP response in the `tcpdump` output — this is the problem you're fixing.
