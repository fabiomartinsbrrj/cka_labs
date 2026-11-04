# Validation — Exercise 20

## 1. Image is signed and verifiable

```bash
cosign verify --key cosign.pub localhost:5000/hello-flask:hardened
```
Expected: verification succeeds and prints the signature payload.

```bash
docker tag hello-flask:hardened localhost:5000/tampered:latest
docker push localhost:5000/tampered:latest
cosign verify --key cosign.pub localhost:5000/tampered:latest
echo "Exit code: $?"
```
Expected: **non-zero exit code** — an image pushed without signing must fail verification.

## 2. ValidatingAdmissionPolicy exists and targets Pods

```bash
kubectl get validatingadmissionpolicy
kubectl get validatingadmissionpolicybinding
```
Expected: your policy and binding are both present, binding's `validationActions` includes `Deny`.

## 3. Enforcement — approved registry is admitted

```bash
kubectl run approved --image=localhost:5000/hello-flask:hardened -n supply-chain-demo --restart=Never
echo "Exit code: $?"
```
Expected: `0` — pod created.

## 4. Enforcement — unapproved registry is rejected

```bash
kubectl run unapproved --image=nginx:1.25 -n supply-chain-demo --restart=Never
echo "Exit code: $?"
```
Expected: **non-zero exit code**, and the rejection message references your policy's deny message, not a generic image-pull error — it must be blocked at admission time, before the kubelet ever tries to pull the image.

## Cleanup

```bash
./cleanup.sh
```
