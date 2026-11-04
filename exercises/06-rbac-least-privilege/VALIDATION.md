# Validation — Exercise 06

## 1. cluster-admin binding is gone

```bash
kubectl get clusterrolebinding ops-bot-cluster-admin
echo "Exit code: $?"
```
Expected: **non-zero exit code** — `NotFound`.

## 2. ops-bot can still do its job, cluster-wide

```bash
kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:platform-ops:ops-bot
kubectl auth can-i get pods/log -n kube-system --as=system:serviceaccount:platform-ops:ops-bot
```
Expected: both `yes`.

## 3. ops-bot can't do anything else

```bash
kubectl auth can-i get secrets --all-namespaces --as=system:serviceaccount:platform-ops:ops-bot
kubectl auth can-i delete pods -n platform-ops --as=system:serviceaccount:platform-ops:ops-bot
kubectl auth can-i create clusterrolebindings --as=system:serviceaccount:platform-ops:ops-bot
```
Expected: all three `no`.

## Cleanup

```bash
./cleanup.sh
```
