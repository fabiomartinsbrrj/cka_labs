# Validation — Exercise 15

## 1. Secret exists and Deployment no longer uses plaintext env vars

```bash
kubectl get secret invoice-db-credentials -n billing
kubectl get deploy invoice-worker -n billing -o jsonpath='{.spec.template.spec.containers[0].env}'
kubectl get deploy invoice-worker -n billing -o jsonpath='{.spec.template.spec.containers[0].volumeMounts}'
```

Expected: the secret exists; `.env` is empty or absent; the credentials are only reachable via a mounted volume.

```bash
kubectl exec -n billing deploy/invoice-worker -- cat /etc/invoice-db/DB_PASSWORD
```

Expected: prints the password — confirms the mount works.

## 2. RBAC is scoped to exactly one Secret

```bash
kubectl auth can-i get secret/invoice-db-credentials -n billing \
  --as=system:serviceaccount:billing:invoice-worker-sa
```
Expected: `yes`

```bash
kubectl auth can-i list secrets -n billing \
  --as=system:serviceaccount:billing:invoice-worker-sa
echo "---"
kubectl auth can-i get secrets -n billing \
  --as=system:serviceaccount:billing:invoice-worker-sa
```
Expected: both `no` — `get` without a resource name, and `list`, must be denied; only the named resource is allowed.

## 3. Encryption at rest is enabled

```bash
ssh -i $KEY ubuntu@<controlplane-ip> 'sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep encryption-provider-config'
```
Expected: the flag is present and points at your `EncryptionConfiguration` file.

## 4. New Secret values are not stored as recoverable plaintext in etcd

```bash
kubectl delete secret invoice-db-credentials -n billing
kubectl create secret generic invoice-db-credentials -n billing \
  --from-literal=DB_USER=invoice_app --from-literal=DB_PASSWORD=SuperSecret123!

ssh -i $KEY ubuntu@<controlplane-ip> 'sudo ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/billing/invoice-db-credentials | hexdump -C | grep -i supersecret'
```
Expected: **no match** — if `SuperSecret123!` shows up readable in the hexdump, encryption is not actually being applied to new writes.

## Cleanup

```bash
kubectl delete -f setup/
```
