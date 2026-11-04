# Validation — Exercise 08

## 1. API server flags are correctly set

```bash
ssh -i $KEY ubuntu@<controlplane-ip> 'sudo grep -E "anonymous-auth|authorization-mode|profiling" /etc/kubernetes/manifests/kube-apiserver.yaml'
```
Expected:
```
- --anonymous-auth=false
- --authorization-mode=Node,RBAC
- --profiling=false
```

## 2. Unauthenticated requests are rejected

```bash
ssh -i $KEY ubuntu@<controlplane-ip> 'curl -sk https://localhost:6443/api/v1/namespaces'
```
Expected: `401 Unauthorized` (or equivalent), **not** a 403 that implies the request was authenticated as `system:anonymous` and merely lacked RBAC permissions. With `--anonymous-auth=false`, the request should never get an identity at all.

## 3. Network-level restriction still holds

From a machine whose IP is **not** in `allowed_ssh_cidr`:

```bash
curl -k --connect-timeout 5 https://<controlplane-public-ip>:6443/api/v1/namespaces
echo "Exit code: $?"
```
Expected: connection timeout — the security group drops the packet before it ever reaches `kube-apiserver`.

From a machine whose IP **is** allowed:

```bash
curl -k --connect-timeout 5 https://<controlplane-public-ip>:6443/api/v1/namespaces
```
Expected: connects (and then gets the same `401` from check #2, since the request still isn't authenticated).

## 4. Write-up exists

```bash
test -f API-ACCESS.md && echo "present"
```

## Cleanup

```bash
./cleanup.sh
```
