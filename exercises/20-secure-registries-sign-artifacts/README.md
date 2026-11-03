# Exercise 20 — Secure Your Supply Chain (Registries, Signing)

## CKS Domain

**5. Supply Chain Security** (20%)

## Competency

> Secure your supply chain (permitted registries, sign and validate artifacts)

## Context

Two separate controls, often confused with each other:

1. **Registry allowlisting** — the cluster should refuse to run images from anywhere except approved registries, regardless of whether the image is signed.
2. **Image signing** — even from an approved registry, you want cryptographic proof the image wasn't tampered with after your CI built it.

This exercise builds both, using `hello-flask:hardened` from exercise 18.

## Requirements

1. Sign `hello-flask:hardened` with **cosign** (a local key pair is fine — `cosign generate-key-pair`) after pushing it to a registry you control (a local `registry:2` container is enough — no need for a real cloud registry).
2. Verify the signature with `cosign verify` using the public key, and show that verification **fails** against a tampered/different image.
3. Create a Kubernetes `ValidatingAdmissionPolicy` + binding that rejects any Pod whose image does **not** start with your approved registry prefix (e.g. `localhost:5000/` or your chosen registry hostname) — cluster-wide, in all namespaces except `kube-system`.
4. Prove enforcement: a pod using an image from the approved registry is admitted; a pod using `nginx:1.25` straight from Docker Hub is rejected by the API server.

## Setup

```bash
kubectl apply -f setup/
```

This creates the `supply-chain-demo` namespace and confirms your cluster's `kube-apiserver` supports `ValidatingAdmissionPolicy` (GA since Kubernetes 1.30 — check `kubectl api-resources | grep validatingadmissionpolic`).

> Running a local registry: `docker run -d -p 5000:5000 --restart=always --name registry registry:2`
