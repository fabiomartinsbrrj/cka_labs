# Exercise 09 — Upgrade Kubernetes to Avoid Vulnerabilities

## CKS Domain

**2. Cluster Hardening** (15%)

## Competency

> Upgrade Kubernetes to avoid vulnerabilities

## Context

This cluster now bootstraps on Kubernetes **1.37** (`scripts/fase1-node.sh`), which as of this writing sits inside the officially supported window (the project actively patches only the **three most recent minor releases** — check https://kubernetes.io/releases/ for the current set). That won't stay true forever: a new minor ships roughly every 4 months, and 1.37 will eventually age out exactly like 1.31 did before this exercise prompted the bump. The skill this competency tests isn't "upgrade this one specific cluster" — it's knowing the repeatable procedure so you can run it again the day this cluster's version falls out of support.

Kubernetes' version-skew policy only allows upgrading **one minor version at a time** — you can never skip a hop, no matter how far behind you are.

## Requirements

1. Once a new Kubernetes minor ships (or using a disposable second cluster pinned one minor behind, if you want to practice today without waiting), on the **controlplane**: run `kubeadm upgrade plan` to see what's available, then `kubeadm upgrade apply vX.Y.Z` for the next minor version up from what's currently running.
2. Upgrade `kubelet` and `kubectl` packages on the controlplane to match, restart `kubelet`.
3. On **each worker node**, in order, one at a time:
   - `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
   - `kubeadm upgrade node`
   - Upgrade `kubelet`/`kubectl` packages, restart `kubelet`
   - `kubectl uncordon <node>`
4. Confirm the cluster is healthy and fully on the new minor version before moving to the next hop.
5. Update the version pin in `scripts/fase1-node.sh`, `README.md`, and `CLAUDE.md` to match, so future `make fase1` runs on fresh nodes start at the new baseline instead of silently drifting back to an old version.
6. Repeat steps 1-5 for each subsequent minor version if you're catching up from more than one hop behind, until the cluster is within the officially supported window.

## Setup

No manifests to apply. Baseline check:

```bash
kubectl get nodes -o wide
```
Expected: `VERSION` column shows `v1.37.x` on every node — confirming you're starting from a currently-supported version, not practicing the recovery-from-neglect scenario this exercise originally caught.
