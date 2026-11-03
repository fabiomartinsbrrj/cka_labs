# Exercise 23 — Runtime Threat Detection

## CKS Domain

**6. Monitoring, Logging and Runtime Security** (20%)

## Competency

> Perform behavioral analytics to detect malicious activities; Detect threats within physical infrastructure, apps, networks, data, users and workloads; Investigate and identify phases of attack and bad actors within the environment

## Context

Namespace `exposed-app` runs `webshop`, a Deployment that nobody is watching at runtime. If someone got a shell inside one of its containers right now — via a vulnerable dependency, a misconfigured sidecar, anything — nobody would know. Falco watches syscalls at the kernel/eBPF level and fires on suspicious patterns regardless of what triggered them, which is the point: it doesn't care *how* the attacker got in, only *what they do once they're there*.

## Requirements

1. Install Falco on the node where `webshop` runs and get it running as a service.
2. Trigger a **built-in** Falco rule by spawning an interactive shell inside a `webshop` container, and confirm the alert appears.
3. Trigger another built-in rule by reading a sensitive file (`/etc/shadow`) from inside the container.
4. Write a **custom** Falco rule that detects `curl` or `wget` being spawned inside any container in `exposed-app`, reload Falco, and trigger it.
5. Using only what Falco logged (not prior knowledge of what you did), reconstruct the "attack": which pod, which user/process, which command, in what order. Write it up in `INCIDENT.md` in this folder as if reporting to a teammate.

## Setup

```bash
kubectl apply -f setup/
kubectl get pods -n exposed-app -o wide
```

Falco install requires SSH + `sudo` on the node the `webshop` pod lands on (same access the Makefile's `fase1`/`fase2` targets use). Official install docs: https://falco.org/docs/install-operate/installation/
