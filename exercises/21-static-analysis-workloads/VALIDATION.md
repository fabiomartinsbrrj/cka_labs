# Validation — Exercise 21

## 1. Baseline scan (before your fix) — for the record

```bash
trivy config setup/ 2>&1 | tee baseline-scan.txt
```
Expected: multiple CRITICAL/HIGH findings — privileged container, hostPath, missing resource limits, mutable tag.

## 2. Scan after your fix

```bash
trivy config setup/ 2>&1 | tee fixed-scan.txt
diff baseline-scan.txt fixed-scan.txt
```
Expected: CRITICAL/HIGH findings resolved — ideally the scan passes clean (only informational/low findings left, if any).

## 3. Spot-check each fix individually

```bash
grep -q "privileged: true" setup/checkout-deployment.yaml && echo "STILL PRIVILEGED" || echo "ok"
grep -q "hostPath" setup/checkout-deployment.yaml && echo "STILL HOSTPATH" || echo "ok"
grep -q ":latest" setup/checkout-deployment.yaml && echo "STILL LATEST TAG" || echo "ok"
grep -q "automountServiceAccountToken: false" setup/checkout-deployment.yaml && echo "ok" || echo "TOKEN STILL AUTOMOUNTED"
grep -q "limits:" setup/checkout-deployment.yaml && echo "ok" || echo "NO RESOURCE LIMITS"
```
Expected: every line prints `ok`.

## 4. (Bonus) CI write-up exists

```bash
test -f STATIC-ANALYSIS.md && echo "present"
```

## Cleanup

```bash
./cleanup.sh
```
