# Exercise 09 — Upgrade Kubernetes to Avoid Vulnerabilities

## CKS Domain

**2. Cluster Hardening** (15%)

## Competency

> Upgrade Kubernetes to avoid vulnerabilities

## Context

This cluster was bootstrapped on Kubernetes **1.31** (see `scripts/fase1-node.sh`, pinned via `kubelet=1.31.0-1.1 kubeadm=1.31.0-1.1 kubectl=1.31.0-1.1`). As of now, the Kubernetes project only actively patches the **three most recent minor releases** — 1.31 is well outside that window, meaning it no longer receives CVE fixes. That's the exact scenario this competency exists for.

Kubernetes' version-skew policy only allows upgrading **one minor version at a time** — you cannot go straight from 1.31 to the latest supported minor. This exercise walks the repeatable procedure for a single minor-version hop; you then repeat it until you reach a supported version.

## Requirements

1. On the **controlplane**: run `kubeadm upgrade plan` to see what's available, then `kubeadm upgrade apply vX.Y.Z` for the next minor version up from what's currently running.
2. Upgrade `kubelet` and `kubectl` packages on the controlplane to match, restart `kubelet`.
3. On **each worker node**, in order, one at a time:
   - `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
   - `kubeadm upgrade node`
   - Upgrade `kubelet`/`kubectl` packages, restart `kubelet`
   - `kubectl uncordon <node>`
4. Confirm the cluster is healthy and fully on the new minor version before moving to the next hop.
5. Update the version pin in `scripts/fase1-node.sh`, `README.md`, and `CLAUDE.md` to match, so future `make fase1` runs on fresh nodes start at the new baseline instead of silently drifting back to 1.31.
6. Repeat steps 1-5 for each subsequent minor version until the cluster is within the officially supported window (check https://kubernetes.io/releases/ for the current three supported minors).

## Setup

No manifests to apply. Baseline check:

```bash
kubectl get nodes -o wide
```
Expected: `VERSION` column shows `v1.31.x` on every node — that's the starting point.
