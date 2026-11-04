# Validation — Exercise 02

Run on the respective node via SSH.

## 1. Kubelet config permissions

```bash
stat -c "%a %U:%G" /var/lib/kubelet/config.yaml
```
Expected: `600 root:root`.

## 2. API server profiling disabled

```bash
sudo grep profiling /etc/kubernetes/manifests/kube-apiserver.yaml
```
Expected: `--profiling=false`.

## 3. etcd data directory permissions

```bash
sudo stat -c "%a %U:%G" /var/lib/etcd
```
Expected: `700`, owned by `root:root` (or `etcd:etcd` if you created a dedicated system user).

## 4. kube-bench re-run shows the specific checks passing

```bash
sudo ./kube-bench run --targets=master | grep -A1 -E "1\.1\.1[2-9]|1\.2\.[0-9]+" | grep -i profiling
sudo ./kube-bench run --targets=master | grep -i "kubelet.*permission"
```
Expected: the checks tied to the three fixes above now show `[PASS]`.

## 5. Findings write-up exists

```bash
test -f FINDINGS.md && echo "present"
```

## Cleanup

```bash
./cleanup.sh
```
