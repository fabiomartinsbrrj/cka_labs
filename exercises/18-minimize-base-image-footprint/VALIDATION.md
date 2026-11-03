# Validation — Exercise 18

## 1. Build both images

```bash
cd app/
docker build -f Dockerfile.insecure -t hello-flask:insecure .
docker build -f Dockerfile -t hello-flask:hardened .
```

## 2. Compare image size

```bash
docker images hello-flask
```
Expected: `hello-flask:hardened` is dramatically smaller than `hello-flask:insecure` (Ubuntu + build-essential easily clears 400-500MB; a proper Alpine/distroless multi-stage build should land well under 100MB, often under 50MB).

## 3. Compare vulnerability counts

```bash
trivy image --severity CRITICAL,HIGH hello-flask:insecure
echo "=================================="
trivy image --severity CRITICAL,HIGH hello-flask:hardened
```
Expected: the hardened image has materially fewer CRITICAL/HIGH findings — ideally close to zero, since it carries no build tooling and a minimal base.

## 4. Non-root check

```bash
docker run --rm hello-flask:hardened id
```
Expected: UID is **not** `0`.

## 5. App still works

```bash
docker run --rm -d -p 8080:8080 --name hello-flask-test hello-flask:hardened
sleep 1
curl -s http://localhost:8080/
docker stop hello-flask-test
```
Expected: `hello from the CKS lab`.

## Cleanup

```bash
docker rmi hello-flask:insecure hello-flask:hardened
```
