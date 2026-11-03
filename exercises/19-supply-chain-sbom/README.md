# Exercise 19 — Understand Your Supply Chain (SBOM)

## CKS Domain

**5. Supply Chain Security** (20%)

## Competency

> Understand your supply chain (e.g. SBOM, CI/CD, artifact repositories)

## Context

"Understanding your supply chain" means being able to answer, for any image running in your cluster: *what exactly is in it, where did each piece come from, and which of those pieces have known vulnerabilities?* An SBOM (Software Bill of Materials) is the artifact that answers the first two questions; a vulnerability scanner cross-referenced against the SBOM answers the third.

You'll use the `hello-flask:hardened` image from exercise 18 (rebuild it here if needed) as the subject.

## Requirements

1. Generate an SBOM for the image in **both** CycloneDX and SPDX formats using `syft`.
2. From the SBOM alone (not by re-scanning the image), identify: the base OS/distro, the language package manager in use, and the exact installed version of Flask.
3. Cross-reference the SBOM against a vulnerability database — i.e., feed the SBOM (not the image) into `grype` or `trivy sbom` — and get a vulnerability report purely from the SBOM artifact.
4. Write a short note (`SUPPLY-CHAIN.md` in this folder) describing this image's supply chain end to end: source repo → base image origin → build step → where the SBOM would be stored/attached in a real CI/CD pipeline (e.g., attached to the image in the registry via `cosign attach sbom`, or pushed to an artifact repository alongside the image).

## Setup

No cluster changes needed — this is a local tooling exercise.

```bash
# from exercise 18, or rebuild it:
cd ../18-minimize-base-image-footprint/app
docker build -t hello-flask:hardened .
```

You'll need `syft` and `grype` installed locally:
- https://github.com/anchore/syft
- https://github.com/anchore/grype
