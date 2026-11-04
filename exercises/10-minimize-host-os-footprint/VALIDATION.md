# Validation — Exercise 10

## 1. Targeted services are gone

```bash
ssh -i $KEY ubuntu@<node-ip> 'systemctl is-active apport snapd 2>&1; systemctl is-enabled apport snapd 2>&1'
```
Expected: `inactive`/`masked` (or `unit not found`, if purged) for each service you targeted.

## 2. Load-bearing services are untouched

```bash
ssh -i $KEY ubuntu@<node-ip> 'systemctl is-active containerd kubelet ssh'
```
Expected: `active` for all three.

## 3. Hardening is baked into the provisioning script, not manual

```bash
grep -n "disable\|mask\|purge" scripts/fase1-node.sh
```
Expected: the service-disabling steps appear in the script itself.

## 4. Cluster still works after a fresh fase1 run

```bash
make fase1 KEY=~/workspace/cka-key.pem
kubectl get nodes
```
Expected: all nodes `Ready`, no errors during provisioning.

## 5. Attack surface measurably reduced

```bash
ssh -i $KEY ubuntu@<node-ip> 'systemctl list-units --type=service --state=running | wc -l'
```
Expected: lower count than the baseline you recorded before starting.

## Cleanup

```bash
./cleanup.sh
```
