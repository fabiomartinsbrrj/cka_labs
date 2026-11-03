# Validation — Exercise 19

## 1. SBOMs generated in both formats

```bash
syft hello-flask:hardened -o cyclonedx-json=sbom.cdx.json
syft hello-flask:hardened -o spdx-json=sbom.spdx.json
ls -la sbom.cdx.json sbom.spdx.json
```
Expected: both files exist and are non-empty valid JSON.

## 2. Facts extracted from the SBOM match the image

```bash
jq -r '.metadata.component.name, .metadata.component.version' sbom.cdx.json 2>/dev/null
jq -r '.components[] | select(.name=="flask") | .version' sbom.cdx.json
```
Expected: the Flask version printed matches `requirements.txt` (`3.0.3`) from exercise 18.

## 3. Vulnerability scan from the SBOM artifact (not the image)

```bash
grype sbom:./sbom.cdx.json
```
or
```bash
trivy sbom sbom.cdx.json
```
Expected: a vulnerability report is produced purely from the SBOM file — confirming the SBOM alone carries enough information to assess risk without having the original image on hand.

## 4. Supply chain write-up exists

```bash
test -f SUPPLY-CHAIN.md && echo "present"
```
Expected: `SUPPLY-CHAIN.md` describes the full chain (source → base image → build → SBOM storage location) in your own words.

## Cleanup

```bash
rm -f sbom.cdx.json sbom.spdx.json
```
