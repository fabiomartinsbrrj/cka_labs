# Exercise 21 — Static Analysis of Workloads and Images

## CKS Domain

**5. Supply Chain Security** (20%)

## Competency

> Perform static analysis of user workloads and container images

## Context

`setup/` has a batch of manifests for the `checkout` service, written by a team in a hurry. Nobody ran a static scanner before merging them. They work, but they're full of avoidable risk: a privileged container, a `hostPath` mount, no resource limits, the `default` ServiceAccount with its token auto-mounted, and an image pinned to `:latest`.

This exercise is about catching that **before** it reaches a cluster — static analysis of the YAML itself, not runtime behavior.

## Requirements

1. Run a static analysis tool (`trivy config setup/`, and/or `kubesec scan` on each manifest) **before** making any changes, and record the findings.
2. Fix every manifest until the scanner reports no CRITICAL/HIGH-equivalent findings:
   - Remove `privileged: true`
   - Remove the `hostPath` volume (use `emptyDir` or a real `PersistentVolumeClaim` if storage is genuinely needed)
   - Add CPU/memory `requests` and `limits`
   - Pin the image to a specific digest or version tag, never `:latest`
   - Set `automountServiceAccountToken: false` unless the workload actually calls the API server
3. Re-run the same scanner and show the finding count dropped to (ideally) zero CRITICAL/HIGH.
4. (Bonus) Wire the same scan command into a pre-commit hook or a CI step description (`STATIC-ANALYSIS.md` in this folder) so this class of issue never reaches `main` again.

## Setup

```bash
trivy config setup/
```

Run this first, before touching anything — this is your baseline. Don't apply these manifests to the cluster; this exercise is about catching the problems before deploy time.
