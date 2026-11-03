# Exercise 07 — Service Account Hardening

## CKS Domain

**2. Cluster Hardening** (15%)

## Competency

> Exercise caution in using service accounts e.g. disable defaults, minimize permissions

## Context

Namespace `jobs` runs two Deployments, both still using the namespace's `default` ServiceAccount (the one Kubernetes creates automatically, with its token auto-mounted by default):

- `report-generator` — generates and emails a static report. It never calls the Kubernetes API at all.
- `config-reloader` — watches a `ConfigMap` and reloads a sidecar when it changes. It genuinely needs API access, but currently gets it through a `RoleBinding` attached to the `default` ServiceAccount — meaning *every* pod in the namespace that happens to use `default` inherits that permission, whether it needs it or not.

## Requirements

1. Create a dedicated ServiceAccount for each workload: `report-generator-sa` and `config-reloader-sa`.
2. `report-generator` never touches the API — set `automountServiceAccountToken: false` on its ServiceAccount (or pod spec) and point the Deployment at `report-generator-sa`.
3. Move the existing `RoleBinding` (get/watch on `configmaps`) off `default` and onto `config-reloader-sa`. `config-reloader-sa` keeps its token auto-mounted since it legitimately needs it.
4. The namespace's `default` ServiceAccount should end up with **no** RoleBindings/ClusterRoleBindings at all, and `automountServiceAccountToken: false` set directly on it — so any future workload that forgets to specify a ServiceAccount doesn't silently inherit API access.

## Setup

```bash
kubectl apply -f setup/
```

```bash
kubectl get rolebinding -n jobs -o wide
kubectl get pods -n jobs -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.serviceAccountName}{"\n"}{end}'
```

Expected: the `RoleBinding` is bound to `default`, and both pods use `default` — that's what you're fixing.
