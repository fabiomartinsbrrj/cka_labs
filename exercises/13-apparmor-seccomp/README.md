# Exercise 13 — Kernel Hardening Tools (AppArmor, Seccomp)

## CKS Domain

**3. System Hardening** (10%)

## Competency

> Appropriately use kernel hardening tools such as AppArmor, seccomp

## Context

`log-shipper`, in the `telemetry` namespace, tails application logs and forwards them off-box. It has no business doing anything with raw sockets, loading kernel modules, or using `ptrace` to inspect other processes — but today it runs with the Linux kernel's full default seccomp/AppArmor posture (effectively unconfined beyond containerd's own baseline), so nothing would stop it, or a process that compromises it, from trying.

## Requirements

1. Load a custom **AppArmor** profile on the node that denies network raw socket access and write access outside `/var/log/app` and `/tmp`, and apply it to `log-shipper` via the GA `securityContext.appArmorProfile` field (`type: Localhost`, not the old annotation-based mechanism — that's deprecated).
2. Apply a **seccomp** profile to the same pod: start with `RuntimeDefault`, then tighten further with a custom `Localhost` profile that explicitly blocks `ptrace` and module-loading syscalls (`init_module`, `finit_module`, `delete_module`).
3. Confirm the pod still starts and does its actual job (tailing/forwarding a log file) under both profiles — over-restricting seccomp is a common way to softlock a container at startup.
4. Prove the restriction is real: from inside the pod, attempt an action your profile should block (e.g. `ptrace` via `strace` on another process, or opening a raw socket) and confirm it's denied with a permission error, not merely slow or absent by coincidence.

## Setup

```bash
kubectl apply -f setup/
kubectl get pods -n telemetry -o wide
```

```bash
kubectl exec -n telemetry deploy/log-shipper -- sh -c "strace -p 1" 2>&1 | head -5
```

This currently at least attempts to run (no AppArmor/seccomp stopping it at the policy level) — confirm what currently happens before you lock it down, so you have a clear before/after.
