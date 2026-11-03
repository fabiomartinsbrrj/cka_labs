# Exercise 06 — RBAC Least Privilege

## CKS Domain

**2. Cluster Hardening** (15%)

## Competency

> Use Role Based Access Controls to minimize exposure

## Context

`platform-ops` runs a monitoring script under the `ops-bot` ServiceAccount. Whoever set it up got tired of debugging RBAC errors and bound it straight to `cluster-admin` via a `ClusterRoleBinding`. In reality, the script only ever does two things, cluster-wide: list Pods, and read Pod logs. Everything else — Secrets, RBAC objects themselves, the ability to delete anything — is exposure with zero corresponding need.

## Requirements

1. Remove the `cluster-admin` `ClusterRoleBinding` from `ops-bot`.
2. Create a `ClusterRole` granting exactly: `get`, `list`, `watch` on `pods`, and `get` on `pods/log` — cluster-wide (the script does need to see every namespace, that part of the original design was legitimate).
3. Bind it to `ops-bot` via a `ClusterRoleBinding`.
4. Confirm `ops-bot` can still do its actual job, and prove it can no longer do anything else — specifically, that it can't read Secrets, can't delete Pods, and can't create or modify RBAC objects.

## Setup

```bash
kubectl apply -f setup/
```

```bash
kubectl get clusterrolebinding -o wide | grep ops-bot
```

Expected: bound to `cluster-admin` — that's the problem you're fixing.
