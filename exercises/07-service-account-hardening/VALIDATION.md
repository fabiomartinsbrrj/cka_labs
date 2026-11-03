# Validation — Exercise 07

## 1. Dedicated ServiceAccounts in use

```bash
kubectl get pods -n jobs -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.serviceAccountName}{"\n"}{end}'
```
Expected: `report-generator` uses `report-generator-sa`, `config-reloader` uses `config-reloader-sa` — neither uses `default`.

## 2. report-generator-sa has no API access and no auto-mounted token

```bash
kubectl get sa report-generator-sa -n jobs -o jsonpath='{.automountServiceAccountToken}'
```
Expected: `false`.

```bash
kubectl auth can-i get configmaps -n jobs --as=system:serviceaccount:jobs:report-generator-sa
```
Expected: `no`.

## 3. config-reloader-sa has exactly the permission it needs

```bash
kubectl auth can-i get configmaps -n jobs --as=system:serviceaccount:jobs:config-reloader-sa
kubectl auth can-i watch configmaps -n jobs --as=system:serviceaccount:jobs:config-reloader-sa
kubectl auth can-i delete configmaps -n jobs --as=system:serviceaccount:jobs:config-reloader-sa
```
Expected: `yes`, `yes`, `no`.

## 4. default ServiceAccount is fully neutered

```bash
kubectl get sa default -n jobs -o jsonpath='{.automountServiceAccountToken}'
echo
kubectl auth can-i get configmaps -n jobs --as=system:serviceaccount:jobs:default
```
Expected: `false`, then `no` — no RoleBinding should reference `default` anymore.

```bash
kubectl get rolebinding -n jobs -o jsonpath='{range .items[*]}{.subjects[*].name}{"\n"}{end}' | grep -w default
echo "Exit code: $?"
```
Expected: **non-zero exit code** — no match.

## Cleanup

```bash
kubectl delete -f setup/
```
