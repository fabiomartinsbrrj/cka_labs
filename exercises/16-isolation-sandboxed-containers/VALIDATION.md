# Validation — Exercise 16

## 1. RuntimeClass exists

```bash
kubectl get runtimeclass gvisor-runsc
```
Expected: `handler` is `runsc`.

## 2. `tenant-untrusted` pods use the sandbox, `tenant-trusted` does not

```bash
kubectl get pod -n tenant-untrusted -o jsonpath='{.items[0].spec.runtimeClassName}'
echo
kubectl get pod -n tenant-trusted -o jsonpath='{.items[0].spec.runtimeClassName}'
```
Expected: first command prints `gvisor-runsc`; second prints empty (default runtime).

## 3. Sandbox is actually active, not just configured

```bash
kubectl exec -n tenant-untrusted deploy/untrusted-app -- cat /proc/version
```
Expected: the output contains the string `gVisor` — this is gVisor's own kernel identification string and only appears when the pod is genuinely running inside the `runsc` sandbox.

Compare with the trusted tenant, which should show a normal Linux kernel version with no `gVisor` string:

```bash
kubectl exec -n tenant-trusted deploy/trusted-app -- cat /proc/version
```

## 4. (Bonus) Scheduling is pinned to the gVisor-enabled node

```bash
kubectl get pod -n tenant-untrusted -o wide
```
Expected: the pod landed on the node you installed gVisor on, via taint + toleration/nodeSelector — not scheduled arbitrarily.

## Cleanup

```bash
kubectl delete -f setup/
kubectl delete runtimeclass gvisor-runsc
```
