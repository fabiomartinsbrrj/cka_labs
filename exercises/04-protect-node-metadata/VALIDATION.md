# Validation — Exercise 04

## 1. Terraform enforces IMDSv2 with hop limit 1

```bash
terraform plan -var="key_name=cka-key"
```
Expected: no unexpected diff if already applied; `metadata_options` shows `http_tokens = "required"`, `http_put_response_hop_limit = 1`.

```bash
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=controlplane,node01" \
  --query 'Reservations[].Instances[].MetadataOptions'
```
Expected: `HttpTokens: required`, `HttpPutResponseHopLimit: 1` for every instance.

## 2. IMDS is unreachable from inside a pod

```bash
kubectl run metadata-probe --image=busybox:1.36 --restart=Never --rm -it -- \
  wget -qO- --timeout=2 http://169.254.169.254/latest/meta-data/
echo "Exit code: $?"
```
Expected: **non-zero exit code / timeout** — blocked by the hop limit and/or the NetworkPolicy.

## 3. IMDS is still reachable from the host itself

```bash
ssh -i $KEY ubuntu@<any-node-ip> 'curl -s -H "X-aws-ec2-metadata-token: $(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")" http://169.254.169.254/latest/meta-data/instance-id'
```
Expected: prints the instance ID — confirms you blocked **pods**, not the host OS's own legitimate use (SSM agent, AWS CLI, etc.).

## 4. NetworkPolicy is scoped correctly

```bash
kubectl get networkpolicy --all-namespaces
```
Expected: the deny-IMDS policy applies cluster-wide except for your allowlisted namespace(s) (e.g. `kube-system`).

## Cleanup

```bash
kubectl delete pod metadata-probe --ignore-not-found
```
