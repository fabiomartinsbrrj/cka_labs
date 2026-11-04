# Validation — Exercise 09

## 1. Every node reports the new version

```bash
kubectl get nodes -o wide
```
Expected: `VERSION` column shows the target minor version on **every** node, controlplane and workers alike — no node left behind mid-upgrade.

## 2. Cluster is healthy post-upgrade

```bash
kubectl get pods -n kube-system
kubectl get pods --all-namespaces | grep -v Running
```
Expected: all `kube-system` pods `Running`; no workload pods stuck in a non-`Running` state because of the rolling drain/uncordon cycle.

## 3. No node was ever force-removed or left cordoned

```bash
kubectl get nodes
```
Expected: `STATUS` is `Ready` for every node — none stuck in `Ready,SchedulingDisabled` (meaning you forgot an `uncordon`).

## 4. Repo version pins were updated

```bash
grep -n "kubelet=\|kubeadm=\|kubectl=" scripts/fase1-node.sh README.md CLAUDE.md
```
Expected: all references show the new version consistently — not a mix of old and new.

## 5. Cluster is within the supported window (if you completed every hop)

```bash
kubectl version -o json | jq -r '.serverVersion.minor'
```
Compare against https://kubernetes.io/releases/ — expected to be one of the three currently supported minors.

## Cleanup

```bash
./cleanup.sh
```
