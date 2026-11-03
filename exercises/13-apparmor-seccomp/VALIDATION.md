# Validation — Exercise 13

## 1. Pod uses the GA field, not annotations

```bash
kubectl get pod -n telemetry -l app=log-shipper -o jsonpath='{.items[0].spec.containers[0].securityContext.appArmorProfile}'
echo
kubectl get pod -n telemetry -l app=log-shipper -o jsonpath='{.items[0].spec.containers[0].securityContext.seccompProfile}'
```
Expected: `appArmorProfile.type: Localhost` with your profile name; `seccompProfile.type: Localhost` (or `RuntimeDefault` if you stopped at step 2's first half) with your profile referenced.

## 2. Pod is actually running, not stuck

```bash
kubectl get pods -n telemetry -l app=log-shipper
```
Expected: `Running`, not `CrashLoopBackOff` — a profile that's too aggressive will usually show up here first.

## 3. Legitimate behavior still works

```bash
kubectl exec -n telemetry deploy/log-shipper -- tail -3 /var/log/app/app.log
```
Expected: recent heartbeat lines — the app's actual job (writing to `/var/log/app`) still works under both profiles.

## 4. Blocked behavior is actually blocked

```bash
kubectl exec -n telemetry deploy/log-shipper -- sh -c "strace -p 1" 2>&1
echo "Exit code: $?"
```
Expected: **non-zero exit code**, permission denied — not merely "command not found" (install `strace` in the test, or use a documented syscall-blocking proof appropriate to your base image, e.g. attempting to load a kernel module).

```bash
kubectl exec -n telemetry deploy/log-shipper -- sh -c "echo test > /etc/should-be-blocked"
echo "Exit code: $?"
```
Expected: **non-zero exit code** — AppArmor's write restriction outside `/var/log/app` and `/tmp` is enforced.

## Cleanup

```bash
kubectl delete -f setup/
```
