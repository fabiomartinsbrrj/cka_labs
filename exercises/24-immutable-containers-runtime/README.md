# Exercise 24 — Immutability of Containers at Runtime

## CKS Domain

**6. Monitoring, Logging and Runtime Security** (20%)

## Competency

> Ensure immutability of containers at runtime

## Context

`reporting-api`, in the `analytics` namespace, is a Deployment whose containers can currently write anywhere in their own filesystem. If an attacker gets code execution inside one of these pods, they can drop a binary, modify `/usr/bin`, or persist a backdoor on disk — all without needing to escape the container. An immutable root filesystem turns "I got a shell" into "I got a shell that can't write anything useful."

## Requirements

1. Make every container in `reporting-api` run with `readOnlyRootFilesystem: true`.
2. The application still needs to write to `/tmp` and `/var/run/reporting` at runtime — mount those as writable `emptyDir` volumes so the app keeps working with the root filesystem locked down.
3. While you're in there, also set `allowPrivilegeEscalation: false` and `capabilities: drop: [ALL]` — immutability without those is a leaky boat.
4. Prove it: from inside a running pod, confirm a write to the root filesystem fails, while a write to `/tmp` succeeds.

## Setup

```bash
kubectl apply -f setup/
kubectl get pods -n analytics -o wide
```

```bash
kubectl exec -n analytics deploy/reporting-api -- sh -c "echo test > /newfile && cat /newfile"
```

This currently succeeds — that's the problem you're fixing.
