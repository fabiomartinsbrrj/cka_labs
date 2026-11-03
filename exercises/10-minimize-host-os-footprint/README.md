# Exercise 10 — Minimize Host OS Footprint

## CKS Domain

**3. System Hardening** (10%)

## Competency

> Minimize host OS footprint (reduce attack surface)

## Context

`scripts/fase1-node.sh` itself is already lean — it only installs `containerd`, `kubeadm`/`kubelet`/`kubectl`, and the handful of base dependencies (`conntrack`, `socat`, etc.) actually required. What's never been audited is everything the **base Ubuntu 22.04 AMI** ships with before that script even runs: cloud-init leftovers, crash reporting, telemetry/news services, and whatever else `apt` pulled in as "recommended" — none of it is needed on a single-purpose Kubernetes node, and every running service is one more thing that can have a CVE.

## Requirements

1. On a running node, list every active service (`systemctl list-units --type=service --state=running`) and every listening port (`ss -tlnp`).
2. Identify services that are pure attack surface with no benefit to this node's job — e.g. `apport` (crash reporting that could leak container memory contents), `motd-news`/`ubuntu-advantage` (telemetry/ads in the MOTD), `snapd` (not used by anything here). Disable and mask each one you remove.
3. Do **not** touch anything load-bearing: `containerd`, `kubelet`, `ssh`, `systemd-*` core units, and anything Cilium/kube-proxy depend on must keep working exactly as before.
4. Bake the hardening into `scripts/fase1-node.sh` itself (not a one-off manual SSH session) so every future node provisioned by `make fase1` starts hardened.
5. Prove the cluster still works end-to-end after re-running `make fase1` with your changes — nodes join, pods schedule, `kubectl get nodes` shows `Ready`.

## Setup

No manifests to apply. Baseline audit:

```bash
ssh -i $KEY ubuntu@<any-node-ip> 'systemctl list-units --type=service --state=running | wc -l'
ssh -i $KEY ubuntu@<any-node-ip> 'sudo ss -tlnp'
```
