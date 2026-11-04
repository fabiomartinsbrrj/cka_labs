# Validation — Exercise 24

## 1. SecurityContext is correctly locked down

```bash
kubectl get deploy reporting-api -n analytics -o jsonpath='{.spec.template.spec.containers[0].securityContext}'
```
Expected: `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `capabilities: {drop: ["ALL"]}`.

## 2. Pods are running (not stuck/crashlooping)

```bash
kubectl get pods -n analytics -l app=reporting-api
```
Expected: all `Running`.

## 3. Root filesystem write fails

```bash
kubectl exec -n analytics deploy/reporting-api -- sh -c "echo test > /newfile"
echo "Exit code: $?"
```
Expected: **non-zero exit code** — `Read-only file system`.

## 4. Writable mounts still work

```bash
kubectl exec -n analytics deploy/reporting-api -- sh -c "echo test > /tmp/probe && cat /tmp/probe"
kubectl exec -n analytics deploy/reporting-api -- sh -c "mkdir -p /var/run/reporting && echo test > /var/run/reporting/probe && cat /var/run/reporting/probe"
```
Expected: both succeed, printing `test` — the app's legitimate write paths still function.

## Cleanup

```bash
./cleanup.sh
```
