# Validation — Exercise 22

Run on the controlplane node (`ssh -i $KEY ubuntu@<controlplane-ip>`).

## 1. API server is configured for audit logging

```bash
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -E "audit-policy-file|audit-log-path"
```
Expected: both flags present, pointing at your policy file and log path.

## 2. Policy structure is correct

```bash
sudo cat /etc/kubernetes/audit/policy.yaml
```
Expected: `events` at `None`, `secrets`/`configmaps` at `Metadata`, `pods` at `RequestResponse`, catch-all at `Metadata`.

## 3. Secret access is logged at Metadata level (no values leaked into the log)

```bash
kubectl create secret generic probe-secret --from-literal=k=v -n default
kubectl get secret probe-secret -n default -o yaml >/dev/null

sudo grep '"resource":"secrets"' /var/log/kubernetes/audit/audit.log | tail -5 | jq .
```
Expected: entries show `user`, `verb: get`, `objectRef` — but **no** `requestObject`/`responseObject` bodies (that would leak the secret value).

## 4. Pod changes are logged at RequestResponse level

```bash
kubectl run audit-probe --image=busybox:1.36 --restart=Never -- sleep 60
kubectl delete pod audit-probe --wait=true

sudo grep '"resource":"pods"' /var/log/kubernetes/audit/audit.log | tail -10 | jq 'select(.objectRef.name=="audit-probe")'
```
Expected: entries for both `create` and `delete`, each including full `requestObject`/`responseObject` bodies.

## 5. Events are not logged

```bash
sudo grep '"resource":"events"' /var/log/kubernetes/audit/audit.log | wc -l
```
Expected: `0`.

## Cleanup

```bash
kubectl delete secret probe-secret -n default --ignore-not-found
kubectl delete pod audit-probe --ignore-not-found
```
