# Exercise 18 — Minimize Base Image Footprint

## CKS Domain

**5. Supply Chain Security** (20%)

## Competency

> Minimize base image footprint

## Context

`app/` contains a trivial Python Flask "hello world" service and `app/Dockerfile.insecure` — the image currently used to build and run it. That Dockerfile:

- Starts from the full `ubuntu:22.04` base
- Runs `apt-get install` for build tools it doesn't need at runtime (`build-essential`, `curl`, `vim`, `git`)
- Never drops privileges — the container runs as `root`
- Uses a single stage, so build-time dependencies ship in the final image
- Has no `.dockerignore`, so `.git/` gets copied into the image too

This is exactly the kind of image that fails a Trivy scan with dozens of CRITICAL/HIGH findings that have nothing to do with the app itself — they come from the base OS and the unused build tooling.

## Requirements

1. Write a new `app/Dockerfile` using a **multi-stage build**: one stage installs dependencies, the final stage ships only what's needed to run the app, on a minimal base (Alpine or distroless).
2. The final image must run as a **non-root user**.
3. Add a `.dockerignore` so `.git/`, `__pycache__/`, and local virtualenvs never reach the build context.
4. Compare image size and Trivy vulnerability counts between `Dockerfile.insecure` and your new `Dockerfile` — the new image must be smaller and have materially fewer CRITICAL/HIGH findings.

## Setup

This exercise doesn't touch the Kubernetes cluster — it's a local Docker build-and-scan exercise (you'll push the resulting image to the registry in exercise 20).

```bash
cd app/
docker build -f Dockerfile.insecure -t hello-flask:insecure .
```

You'll need `trivy` installed locally: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
