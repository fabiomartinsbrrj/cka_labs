# Exercise 05 — Verify Platform Binaries Before Deploying

## CKS Domain

**1. Cluster Setup** (15%)

## Competency

> Verify platform binaries before deploying

## Context

This repo actually already does this reasonably well in two places: `kubeadm`/`kubelet`/`kubectl` come from the GPG-signed `pkgs.k8s.io` apt repository (`scripts/fase1-node.sh`), and the Cilium CLI download in `scripts/fase2-control.sh` already pulls the matching `.sha256sum` file and runs `sha256sum --check` before extracting — combined with `set -euo pipefail` at the top of the script, a checksum mismatch aborts the whole run. That's the pattern to learn from, not fix.

What's missing is the **standalone binary verification skill itself** — on the actual CKS exam you're frequently handed a bare `curl`-downloaded binary (`kubectl`, `kubeadm`, a CNI plugin) with no apt/package-manager signing underneath it at all, and asked to verify it before trusting it.

## Requirements

1. Write a reusable script, `scripts/verify-binary.sh <url> <expected-sha256-url-or-value>`, that:
   - Downloads the binary and its checksum (from a URL, or accepts a literal expected hash)
   - Verifies the checksum
   - Exits non-zero with a clear error message if it doesn't match — it must **refuse to continue**, never just warn
   - Exits `0` and prints a success message if it matches
2. Use your script to download and verify `kubectl` directly from `dl.k8s.io` (bypassing apt entirely) for the Kubernetes version this cluster runs:
   ```
   https://dl.k8s.io/release/<version>/bin/linux/amd64/kubectl
   https://dl.k8s.io/release/<version>/bin/linux/amd64/kubectl.sha256
   ```
3. Prove your script actually catches tampering, not just happy-path success: deliberately feed it a mismatched checksum (e.g. the checksum of a different `kubectl` version) and confirm it refuses to proceed with a non-zero exit.
4. Refactor `scripts/fase2-control.sh`'s existing Cilium CLI block to call your new `verify-binary.sh` instead of its inline `curl`/`sha256sum` — same behavior, less duplicated logic, one script to get right.

## Setup

No cluster objects to apply — this is a local/node-provisioning script exercise.

```bash
grep -n "K8S_VERSION\|kubelet=\|kubeadm=\|kubectl=" scripts/fase1-node.sh
```

Use the version pinned there as `<version>` in step 2 above (check with the team whether it's still current — see the note in `README-CKS.md` about this).
