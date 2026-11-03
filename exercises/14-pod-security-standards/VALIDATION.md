# Validation — Exercise 14

Run these commands **after** applying your solution.

## 1. Check PSA labels are set correctly

```bash
kubectl get ns payments payments-staging --show-labels
```

Expected:
- `payments` has `pod-security.kubernetes.io/enforce=restricted`
- `payments-staging` has `pod-security.kubernetes.io/audit=restricted` and `pod-security.kubernetes.io/warn=restricted`, but **no** `enforce=restricted`

## 2. Legacy deployment must be compliant and running

```bash
kubectl get pods -n payments -l app=legacy-api
```

Expected: all pods `Running`, 2/2 available, no `CrashLoopBackOff`.

```bash
kubectl get deploy legacy-api -n payments -o jsonpath='{.spec.template.spec.containers[0].securityContext}'
```

Expected: no `privileged: true`, `runAsNonRoot: true` (or a non-zero `runAsUser`), capabilities dropped (`drop: ["ALL"]`), no `hostPath` volumes in `.spec.template.spec.volumes`.

## 3. Enforcement must actually reject noncompliant pods

```bash
kubectl run should-fail -n payments --image=nginx:1.25 --privileged --restart=Never
echo "Exit code: $?"
```

Expected: **non-zero exit code**, and the error message must reference the `restricted` Pod Security Standard (e.g. `violates PodSecurity "restricted:latest"`), not a generic failure.

## 4. Staging namespace must still accept the same noncompliant pod

```bash
kubectl run would-warn -n payments-staging --image=nginx:1.25 --privileged --restart=Never
echo "Exit code: $?"
kubectl get pod would-warn -n payments-staging
```

Expected: **exit code 0**, pod created (you may see a warning printed to stderr, but creation is not blocked).

## Cleanup

```bash
kubectl delete -f setup/
kubectl delete pod should-fail -n payments --ignore-not-found
kubectl delete pod would-warn -n payments-staging --ignore-not-found
```
