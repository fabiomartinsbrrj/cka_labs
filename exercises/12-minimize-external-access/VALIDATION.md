# Validation — Exercise 12

## 1. The broad self-referencing rule is gone

```bash
terraform plan -var="key_name=cka-key"
aws ec2 describe-security-groups --region us-east-1 \
  --filters "Name=group-name,Values=*-sg" \
  --query 'SecurityGroups[].IpPermissions[?FromPort==`0` && ToPort==`0`]'
```
Expected: no rule spanning `0-0` with protocol `-1` remains.

## 2. Cluster still functions end-to-end

```bash
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running
```
Expected: all nodes `Ready`; no pods stuck due to blocked node-to-node traffic.

```bash
kubectl exec -n secure-mesh deploy/client -- wget -qO- server.secure-mesh.svc.cluster.local
```
(if you completed exercise 17 — otherwise use any cross-node pod-to-pod test)
Expected: still succeeds — the narrowed rules cover everything the cluster actually needs.

## 3. Unrelated ports are now blocked between nodes

```bash
ssh -i $KEY ubuntu@<node-a-ip> 'nc -zv -w2 <node-b-private-ip> 9999'
echo "Exit code: $?"
```
Expected: **non-zero exit code / timeout** — this port has nothing to do with Kubernetes and should no longer be reachable.

## 4. Cilium is still healthy

```bash
cilium status
```
Expected: no connectivity errors, all nodes report healthy.

## Cleanup

```bash
./cleanup.sh
```
