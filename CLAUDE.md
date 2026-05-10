# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Terraform infrastructure for CKA (Certified Kubernetes Administrator) study lab on AWS. Creates EC2 instances and a Makefile-driven workflow to bootstrap a multi-node Kubernetes cluster via kubeadm + Cilium.

## Typical Workflow

```bash
# 1. Provision infrastructure
terraform apply -auto-approve -var="key_name=cka-key"

# 2. Install Kubernetes packages on all nodes (containerd, kubeadm, kubelet, kubectl)
make fase1 KEY=~/workspace/cka-key.pem

# 3. Init controlplane, install Cilium CNI, join workers
make fase2 KEY=~/workspace/cka-key.pem

# Or run both phases at once
make full KEY=~/workspace/cka-key.pem

# 4. Pull kubeconfig locally
make kubeconfig KEY=~/workspace/cka-key.pem
export KUBECONFIG=~/workspace/cka-kubeconfig.yaml
```

**Local prerequisite**: `jq` must be installed — the Makefile uses it to parse `terraform output -json public_ips`.

## Terraform Commands

```bash
terraform init                                    # first time or after provider changes
terraform plan -var="key_name=cka-key"
terraform apply -auto-approve -var="key_name=cka-key"
terraform destroy -auto-approve -var="key_name=cka-key"
```

`key_name` is required (no default). SSH key must be pre-created in `us-east-1`:

```bash
aws ec2 create-key-pair --key-name cka-key --region us-east-1 --query 'KeyMaterial' --output text > ~/workspace/cka-key.pem
chmod 400 ~/workspace/cka-key.pem
```

## Architecture

All resources live in a single VPC (`10.20.0.0/16`) with one public subnet (`10.20.1.0/24`) in `us-east-1`:

- `data.tf` — AMI lookup (Ubuntu 22.04 LTS via SSM) + `local.my_ip` via `checkip.amazonaws.com`
- `main.tf` — all resources: VPC, IGW, subnet, route table, security group, EC2 instances
- `variables.tf` / `outputs.tf` — inputs and outputs
- `scripts/fase1-node.sh` — runs on every node: sets hostname, disables swap, configures kernel modules/sysctl, installs containerd + k8s packages v1.31
- `scripts/fase2-control.sh` — runs only on controlplane: `kubeadm init`, Cilium install, prints join command to stdout (all other output goes to stderr — the Makefile captures stdout as `JOIN_CMD`)

## Key Design Decisions

**Dynamic SSH CIDR**: The security group uses `var.allowed_ssh_cidr` if set, otherwise auto-detects your IP (`local.my_ip/32`). The same CIDR also allows access to port 6443 (Kubernetes API) and NodePort range 30000-32767.

**Instance naming**: Instances use Tag `Name`: `controlplane` (index 0) and `node01`, `node02`, … (index 1+). The Makefile reads `public_ips[0]` as the controlplane and `public_ips[1:]` as workers.

**Hostname injection**: `fase1-node.sh` accepts the hostname as `$1`. The Makefile passes `controlplane` or `nodeNN` so hostnames match Kubernetes node names.

**kubeconfig for local access**: `make kubeconfig` copies `/home/ubuntu/.kube/config`, rewrites the server URL from private IP to public IP, and sets `insecure-skip-tls-verify=true` (required because the cert is generated with the private IP as SAN, not the public IP).
