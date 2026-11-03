# Exercise 12 — Minimize External Access to the Network

## CKS Domain

**3. System Hardening** (10%)

## Competency

> Minimize external access to the network

## Context

`main.tf`'s security group (`aws_security_group.lab`) has this rule:

```hcl
ingress {
  description = "All traffic within SG"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  self        = true
}
```

This opens **every port, every protocol**, between any two instances in the security group — justified in the README as "facilitar configuração do Kubernetes." It worked, but it's far broader than what Kubernetes actually needs between nodes. A compromised pod on one node now has unrestricted network reach to every port on every other node, including ports that have nothing to do with Kubernetes.

## Requirements

1. Replace the single `0-0/-1/self` rule with a minimal set of `self = true` ingress rules covering only what a kubeadm + Cilium cluster actually needs between nodes:
   - `6443/tcp` — Kubernetes API server (already covered by an existing rule, but confirm overlap)
   - `2379-2380/tcp` — etcd client/peer (controlplane only, but `self=true` is fine for a 2-node lab)
   - `10250/tcp` — kubelet API
   - `10256/tcp` — kube-proxy health check (if kube-proxy is in use)
   - Cilium's required ports: `4240/tcp` (health checks), `8472/udp` (VXLAN, if used) or `51871/udp` (WireGuard, if you completed exercise 17) — check `cilium status` on your cluster for the exact ports your Cilium mode actually uses
2. Apply the change with Terraform and confirm the cluster still functions — nodes stay `Ready`, pods still schedule and communicate.
3. Prove the narrowing actually took effect: from one node, attempt to reach an arbitrary unrelated port on another node (e.g. `nc -zv <other-node-ip> 9999`) and confirm it's now blocked, where it would have succeeded under the old rule.

## Setup

No manifests to apply — this is a `main.tf` security group change.

```bash
grep -n -A6 "All traffic within SG" main.tf
```
