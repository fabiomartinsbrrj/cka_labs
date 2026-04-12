# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Terraform infrastructure for CKA (Certified Kubernetes Administrator) study lab on AWS. Creates EC2 instances pre-configured for manual Kubernetes cluster setup via kubeadm.

## Terraform Commands

```bash
# Initialize (first time or after provider changes)
terraform init

# Preview changes
terraform plan -var="key_name=cka-key"

# Apply infrastructure
terraform apply -auto-approve -var="key_name=cka-key"

# Destroy all resources
terraform destroy -auto-approve -var="key_name=cka-key"
```

The `key_name` variable is required (no default). SSH key must be pre-created in AWS `us-east-1`:

```bash
aws ec2 create-key-pair --key-name cka-key --region us-east-1 --query 'KeyMaterial' --output text > ~/workspace/cka-key.pem
chmod 400 ~/workspace/cka-key.pem
```

## Architecture

All resources live in a single VPC (`10.20.0.0/16`) with one public subnet (`10.20.1.0/24`) in `us-east-1`. The layout is flat:

- `provider.tf` — AWS provider config
- `versions.tf` — Terraform + provider version constraints
- `data.tf` — AMI lookup (Ubuntu 22.04 LTS) + `local.my_ip` via `checkip.amazonaws.com`
- `main.tf` — all resources: VPC, IGW, subnet, route table, security group, EC2 instances
- `variables.tf` — input variables
- `outputs.tf` — public IPs and ready-to-use SSH commands

## Key Design Decisions

**Dynamic SSH CIDR**: `data.tf` auto-detects the caller's public IP via `https://checkip.amazonaws.com` and stores it as `local.my_ip`. The security group uses `var.allowed_ssh_cidr` if set, otherwise falls back to `"${local.my_ip}/32"`. Passing `allowed_ssh_cidr=0.0.0.0/0` disables this auto-restriction.

**Instance count**: Controlled by `var.instances` (default: 2). Instances are named `cka-lab-node-01`, `cka-lab-node-02`, etc. The first node becomes the control plane; remaining nodes are workers.

**No user_data**: Kubernetes components (containerd, kubeadm, kubelet, kubectl v1.31) are installed manually via SSH after provisioning. Setup steps are documented in `README.md`.
