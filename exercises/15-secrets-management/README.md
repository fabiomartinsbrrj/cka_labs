# Exercise 15 — Kubernetes Secrets Management

## CKS Domain

**4. Minimize Microservice Vulnerabilities** (20%)

## Competency

> Manage Kubernetes secrets

## Context

The `billing` namespace runs `invoice-worker`, a Deployment that currently has its database credentials hardcoded as **plaintext environment variables** directly in the pod spec. Its `ServiceAccount`, `invoice-worker-sa`, has no RBAC bound to it yet. On top of the application-level problem, this cluster has never had **encryption at rest** configured for Secrets — anything stored in `Secret` objects today sits in etcd as base64 (i.e., plaintext for any purpose other than casual readability).

## Requirements

1. Create a `Secret` named `invoice-db-credentials` in `billing` holding `DB_USER` and `DB_PASSWORD`, and update the `invoice-worker` Deployment to consume it via a **mounted volume** (not environment variables) — remove the plaintext env vars entirely.
2. Scope RBAC so that `invoice-worker-sa` can `get` **only** the `invoice-db-credentials` Secret in `billing` — it must not be able to list or read any other Secret in the namespace or cluster.
3. Enable **encryption at rest** for Secrets cluster-wide using the `aescbc` provider (this requires editing the `kube-apiserver` static pod manifest on the controlplane — `/etc/kubernetes/manifests/kube-apiserver.yaml` — and supplying an `EncryptionConfiguration` file).
4. Prove the encryption actually took effect by re-creating the Secret after enabling it and reading its raw value directly from etcd — it must **not** appear as recognizable plaintext/base64 of the original value.

## Setup

```bash
kubectl apply -f setup/
```

```bash
kubectl get pods -n billing -o wide
kubectl get deploy invoice-worker -n billing -o jsonpath='{.spec.template.spec.containers[0].env}'
```

You should see `DB_USER` and `DB_PASSWORD` sitting in plaintext in the Deployment spec — that's the problem you're fixing.

> Step 3 requires SSH access to the controlplane node (`ssh -i $KEY ubuntu@<controlplane-ip>`) and `sudo` — same access the Makefile's `fase2` target uses.
