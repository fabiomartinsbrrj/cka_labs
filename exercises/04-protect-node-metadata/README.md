# Exercise 04 — Protect Node Metadata and Endpoints

## CKS Domain

**1. Cluster Setup** (15%)

## Competency

> Protect node metadata and endpoints

## Context

Every EC2 instance in this lab exposes the AWS Instance Metadata Service at `http://169.254.169.254` — by default reachable not just from the host, but from **any pod running on that node**, since pod network namespaces route through the host. If an attacker compromises any pod, IMDS is a direct path to the node's IAM role credentials. This needs two independent layers of defense: one at the AWS/Terraform level, one at the Kubernetes level, since either one alone can be bypassed.

## Requirements

1. **AWS layer (Terraform):** `resource "aws_instance" "nodes"` in `main.tf` has no `metadata_options` block today (everything defaults to IMDSv1-or-v2 allowed, unlimited hop limit). Add one requiring **IMDSv2** (`http_tokens = "required"`) with `http_put_response_hop_limit = 1`. The hop limit is the real control here — IMDSv2 requests from inside a pod's network namespace cross an extra network hop versus requests from the host itself, so a hop limit of `1` lets the host OS reach IMDS while blocking containers.
2. Apply the Terraform change (`terraform apply`) and confirm existing instances pick it up (EC2 `metadata_options` updates apply in-place, no instance replacement needed).
3. **Kubernetes layer (defense in depth):** on top of the AWS-level block, add a cluster-wide `NetworkPolicy` that denies egress to `169.254.169.254/32` from all pods except an explicitly allowlisted namespace (e.g. `kube-system`, which may legitimately need it for some controllers).
4. Prove both layers: from a pod, a request to IMDS must fail. From the node itself (SSH), the same request must still succeed (confirming you didn't break legitimate host-level IMDS use, e.g. for the AWS CLI or SSM agent).

## Setup

No new Kubernetes objects to apply for this one — you're modifying `main.tf` directly and writing a NetworkPolicy yourself. Baseline check before making any changes:

```bash
kubectl run metadata-probe --image=busybox:1.36 --restart=Never --rm -it -- \
  wget -qO- --timeout=2 http://169.254.169.254/latest/meta-data/
```

This currently succeeds — that's the problem you're fixing.
