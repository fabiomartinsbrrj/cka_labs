# Validation — Exercise 05

## 1. Script verifies a correct binary successfully

```bash
VERSION=$(grep -oE 'kubectl=[0-9.]+-[0-9.]+' scripts/fase1-node.sh | head -1 | cut -d= -f2 | cut -d- -f1)
./scripts/verify-binary.sh \
  "https://dl.k8s.io/release/v${VERSION}/bin/linux/amd64/kubectl" \
  "https://dl.k8s.io/release/v${VERSION}/bin/linux/amd64/kubectl.sha256"
echo "Exit code: $?"
```
Expected: `0`, with a clear success message.

## 2. Script rejects a tampered/mismatched binary

```bash
./scripts/verify-binary.sh \
  "https://dl.k8s.io/release/v${VERSION}/bin/linux/amd64/kubectl" \
  "0000000000000000000000000000000000000000000000000000000000000000"
echo "Exit code: $?"
```
Expected: **non-zero exit code**, clear error message naming the mismatch — the script must not extract/install/chmod +x anything in this path.

## 3. fase2-control.sh was refactored, not duplicated

```bash
grep -n "verify-binary.sh" scripts/fase2-control.sh
grep -c "sha256sum --check" scripts/fase2-control.sh
```
Expected: `fase2-control.sh` calls `verify-binary.sh`; the old inline `sha256sum --check` block for Cilium CLI is gone (count `0` or `1` if `verify-binary.sh` itself still uses it internally, which is fine).

## 4. fase2 still works end-to-end

```bash
make fase2 KEY=~/workspace/cka-key.pem
```
Expected: completes successfully, Cilium installs and reports ready — the refactor didn't break the real flow.
