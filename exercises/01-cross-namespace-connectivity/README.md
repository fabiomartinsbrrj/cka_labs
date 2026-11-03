# Exercise 01 — Cross-Namespace Connectivity Restrictions

## Context

Your cluster has two namespaces with the following workloads:

**namespace: `project-a`**
| Deployment | Label        | Role              |
|------------|--------------|-------------------|
| `web`      | `role=web`   | Frontend layer    |
| `service`  | `role=service` | Backend service layer |

**namespace: `project-b`**
| Deployment | Label      | Role           |
|------------|------------|----------------|
| `db`       | `role=db`  | Database layer |

A `Service` named `db` exposes the database on port `5432` inside `project-b`.

## Requirements

1. Pods with label `role=service` in `project-a` **must** be able to reach pods labeled `role=db` in `project-b` on port `5432`.
2. Pods with label `role=web` in `project-a` **must not** be able to reach any pod in `project-b`.
3. All cross-namespace ingress traffic into `project-b` is **denied by default** — only explicitly allowed traffic passes.
4. Traffic within `project-a` remains **unrestricted**.

## Setup

```bash
kubectl apply -f setup/
```

Wait for all pods to be running before starting:

```bash
kubectl get pods -n project-a
kubectl get pods -n project-b
```

## What to submit

Apply your solution to the cluster. No files need to be created in this directory — the cluster state is the answer.
