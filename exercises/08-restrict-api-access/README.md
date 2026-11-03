# Exercise 08 — Restrict Access to the Kubernetes API

## CKS Domain

**2. Cluster Hardening** (15%)

## Competency

> Restrict access to Kubernetes API

## Context

This cluster already has one layer of API restriction: the Terraform security group only opens port `6443` to `local.my_ip/32` (or whatever `allowed_ssh_cidr` is set to) — see `main.tf` and `CLAUDE.md`'s "Dynamic SSH CIDR" design decision. That's network-level. What's never been checked is the `kube-apiserver` process's own configuration — a kubeadm cluster's defaults are reasonable but not maximally locked down, and `--anonymous-auth` in particular defaults to `true` unless someone explicitly turns it off.

## Requirements

1. Check and, if needed, fix these `kube-apiserver` flags in `/etc/kubernetes/manifests/kube-apiserver.yaml` on the controlplane:
   - `--anonymous-auth=false` (kubeadm does not set this explicitly — the apiserver default is `true`)
   - `--authorization-mode=Node,RBAC` (confirm it's there — kubeadm sets this by default, but confirm rather than assume)
   - `--profiling=false` (also relevant to exercise 02's CIS findings — don't duplicate work if already fixed there)
2. Prove unauthenticated requests are rejected, not silently mapped to `system:anonymous`:
   ```bash
   curl -k https://<controlplane-ip>:6443/api/v1/namespaces
   ```
3. Confirm the network-level restriction from Terraform is still doing its job as a first line of defense — a request from an IP outside `allowed_ssh_cidr` should never even reach the API server's TCP port.
4. Document in `API-ACCESS.md` (this folder) the two layers (network: security group; API server: auth flags) and why you need both — one without the other leaves a real gap.

## Setup

No cluster objects to apply — this is an apiserver flag + infra-config inspection exercise.

```bash
ssh -i $KEY ubuntu@<controlplane-ip> 'sudo grep -E "anonymous-auth|authorization-mode|profiling" /etc/kubernetes/manifests/kube-apiserver.yaml'
```
