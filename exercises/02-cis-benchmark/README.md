# Exercise 02 — CIS Benchmark

## CKS Domain

**1. Cluster Setup** (15%)

## Competency

> Use CIS benchmark to review the security configuration of Kubernetes components

## Context

Nobody has ever run a CIS benchmark against this cluster. `kube-bench` checks the live configuration of `kube-apiserver`, `kubelet`, `etcd`, and the controller-manager/scheduler against the CIS Kubernetes Benchmark and tells you exactly which flags and file permissions are wrong — by check ID, with the exact remediation.

## Requirements

1. Install and run `kube-bench` against the **controlplane** (`--targets=master`) and against a **worker node** (`--targets=node`).
2. From the raw output, fix at least these three real findings (they are very likely to show up on this cluster, since it was bootstrapped with defaults):
   - Kubelet config file (`/var/lib/kubelet/config.yaml`) has overly permissive file permissions — tighten to `600`, owned by `root:root`.
   - `kube-apiserver` has profiling enabled by default — set `--profiling=false`.
   - The etcd data directory has permissive permissions — tighten to `700`, owned by `etcd:etcd` (or `root:root` on kubeadm-managed etcd).
3. Re-run `kube-bench` and confirm those specific checks now report `[PASS]` instead of `[FAIL]` or `[WARN]`.
4. Write a short `FINDINGS.md` in this folder listing every check that was still failing after your fixes, with a one-line justification for each one you consciously chose not to fix (not everything flagged by kube-bench is fixable in a kubeadm lab — know which ones and why).

## Setup

This exercise runs entirely on the controlplane and worker nodes over SSH — no `kubectl apply` needed.

```bash
ssh -i $KEY ubuntu@<controlplane-ip>
curl -L https://github.com/aquasecurity/kube-bench/releases/latest/download/kube-bench_linux_amd64.tar.gz -o kube-bench.tar.gz
tar -xzf kube-bench.tar.gz
sudo ./kube-bench run --targets=master
```
