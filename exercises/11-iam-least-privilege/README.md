# Exercise 11 — Least-Privilege Identity and Access Management

## CKS Domain

**3. System Hardening** (10%)

## Competency

> Using least-privilege identity and access management

## Context

`resource "aws_instance" "nodes"` in `main.tf` has **no IAM instance profile at all** today — SSH with a `.pem` key is the only way in. The team wants to add **AWS Systems Manager (SSM) Session Manager** access for break-glass troubleshooting without needing to distribute the SSH key further. The fast way to do that is to attach `AdministratorAccess` to a new instance role and move on — don't do that.

## Requirements

1. Create an `aws_iam_role` for the nodes with an assume-role policy scoped to `ec2.amazonaws.com`.
2. Attach **only** the managed policy that SSM Session Manager actually needs: `AmazonSSMManagedInstanceCore`. Nothing else — no S3, no EC2 describe/modify permissions, no CloudWatch beyond what that policy already includes.
3. Create the matching `aws_iam_instance_profile` and attach it to `aws_instance.nodes` via `iam_instance_profile`.
4. Apply with Terraform and confirm SSM Session Manager can connect to a node (`aws ssm start-session --target <instance-id>`) — this is in-place on existing instances only if the instance profile change doesn't force replacement; check `terraform plan` output for `aws_instance.nodes` before applying to confirm whether it's an in-place update or a replace.
5. Confirm the role genuinely can't do anything beyond SSM: try to use the node's own instance credentials (via `aws sts get-caller-identity` run **from inside the node**, using the instance's metadata-derived credentials) to call an unrelated API (e.g. `aws s3 ls`) and confirm it's denied.

## Setup

No manifests to apply — this is a `main.tf` change.

```bash
grep -n "iam_instance_profile\|aws_iam_role" main.tf
echo "Exit code: $?"
```
Expected: no output, exit code `1` — confirms no IAM role exists yet.
