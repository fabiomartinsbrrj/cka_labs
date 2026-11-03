# Exercise 22 — Kubernetes Audit Logs

## CKS Domain

**6. Monitoring, Logging and Runtime Security** (20%)

## Competency

> Use Kubernetes audit logs to monitor access

## Context

This cluster's `kube-apiserver` has never had audit logging configured — today, there is no record of who read a Secret, who deleted a Pod, or who tried (and failed) to do something they weren't authorized for. Security wants selective, not blanket, logging: full request+response bodies are too noisy and expensive to log for everything, but Secret/ConfigMap access needs to be traceable, and Pod lifecycle changes need full detail.

## Requirements

1. Write an audit `Policy` (`audit.k8s.io/v1`) with at least these rules, in order:
   - Don't log `events` at all (`level: None`) — pure noise.
   - Log `secrets` and `configmaps` access at `Metadata` level (who/when/what, not the actual values).
   - Log `pods` changes at `RequestResponse` level (full detail).
   - A catch-all rule at `Metadata` level for everything else.
2. Wire the policy into `kube-apiserver` on the controlplane: `--audit-policy-file`, `--audit-log-path`, plus the matching `hostPath` volumes/mounts in the static pod manifest.
3. Confirm the API server picked up the change (it restarts automatically as a static pod — `kubectl get pods` may be briefly unresponsive).
4. Generate activity and prove it's captured: read a Secret, create and delete a Pod, and show both show up in the audit log with the right detail level each.

## Setup

This exercise is entirely on the controlplane node — no manifests to `kubectl apply`.

```bash
ssh -i $KEY ubuntu@<controlplane-ip>
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i audit
```

Expected: no output — confirms audit logging isn't configured yet.
