# Exercise 16 — Isolation Techniques (Multi-Tenancy, Sandboxed Containers)

## CKS Domain

**4. Minimize Microservice Vulnerabilities** (20%)

## Competency

> Understand and implement isolation techniques (multi-tenancy, sandboxed containers)

## Context

Your cluster is shared by two tenants:

- `tenant-trusted` — your own teams' workloads, trusted, runs normally with `runc`.
- `tenant-untrusted` — runs third-party/unreviewed container images. A kernel-level container escape here must **not** reach the host kernel that other tenants share.

Regular `runc` containers share the host kernel: an escape is a host compromise. You need a sandboxed runtime — **gVisor (`runsc`)** — that intercepts syscalls in a userspace kernel, so even a successful container escape lands inside the sandbox, not on the real host.

## Requirements

1. Install gVisor (`runsc`) on a worker node and register it with `containerd` as a new Kubernetes `RuntimeClass` named `gvisor-runsc`.
2. Every pod in `tenant-untrusted` must run under `gvisor-runsc`. Pods in `tenant-trusted` keep using the default runtime.
3. Prove the sandbox is actually active from inside a `tenant-untrusted` pod — not just that the RuntimeClass object exists.
4. (Bonus, real-world concern) Make sure `tenant-untrusted` pods only land on the node where you installed gVisor — use a taint on that node plus a matching toleration/nodeSelector on the namespace's workloads, so tenants without the sandbox requirement aren't scheduled there unnecessarily.

## Setup

```bash
kubectl apply -f setup/
```

```bash
kubectl get pods -n tenant-trusted -n tenant-untrusted -o wide
```

Both namespaces currently run identical workloads on the default (`runc`) runtime — `tenant-untrusted`'s Deployment is what you need to move onto the sandbox.

> Installing gVisor requires SSH + `sudo` on a worker node (same access the Makefile's `fase1`/`fase2` targets use). Official install docs: https://gvisor.dev/docs/user_guide/install/
