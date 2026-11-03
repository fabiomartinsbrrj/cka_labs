# Exercise 14 — Pod Security Standards

## CKS Domain

**4. Minimize Microservice Vulnerabilities** (20%)

## Competency

> Use appropriate pod security standards

## Context

The `payments` namespace runs a legacy workload, `legacy-api`, that was written before anyone cared about pod security. It currently:

- Runs as `root` (`runAsUser: 0`, no `runAsNonRoot`)
- Sets `privileged: true`
- Keeps the default (full) Linux capability set — nothing is dropped
- Mounts the host's `/etc` via `hostPath`
- Has a writable root filesystem

Security wants this namespace enforced against the **Restricted** Pod Security Standard, but without an outage: the fix has to happen in two steps, like it would in a real migration.

## Requirements

1. The `payments` namespace must **enforce** the `restricted` Pod Security Standard (admission must reject any pod that violates it — not just warn).
2. A separate namespace, `payments-staging`, must only **audit + warn** at the `restricted` level — deployments are still accepted even if they violate the standard, but violations are flagged (for teams still migrating).
3. Fix the `legacy-api` Deployment in `payments` so it complies with `restricted` and keeps running after you turn enforcement on. At minimum it must:
   - Run as a non-root user
   - Not be privileged
   - Drop `ALL` capabilities (add back only what's strictly required, if anything)
   - Use `seccompProfile: RuntimeDefault`
   - Not mount host paths
4. Prove enforcement works: attempting to create a new Pod with `privileged: true` in `payments` must be **rejected by the API server**, not silently allowed.

## Setup

```bash
kubectl apply -f setup/
```

Wait for the legacy deployment to come up before starting:

```bash
kubectl get pods -n payments -o wide
```

Note that neither namespace has Pod Security Admission labels yet — that is part of what you need to add.
