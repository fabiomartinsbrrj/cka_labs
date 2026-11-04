# Validation — Exercise 11

## 1. Role exists with exactly one managed policy attached

```bash
terraform output -json 2>/dev/null | jq -r 'keys[]' | grep -i iam
aws iam list-attached-role-policies --role-name <your-role-name> --region us-east-1
```
Expected: exactly `AmazonSSMManagedInstanceCore` — nothing else.

## 2. Instance profile is attached to the nodes

```bash
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=controlplane,node01" \
  --query 'Reservations[].Instances[].IamInstanceProfile'
```
Expected: non-null for every instance.

## 3. SSM Session Manager works

```bash
INSTANCE_ID=$(aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=controlplane" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ssm start-session --target "$INSTANCE_ID" --region us-east-1
```
Expected: session opens successfully.

## 4. The role can't do anything beyond SSM

From inside the node (via the SSM session or SSH):

```bash
aws sts get-caller-identity
aws s3 ls
echo "Exit code: $?"
```
Expected: `get-caller-identity` succeeds (confirms the role is attached and credentials are flowing), but `aws s3 ls` fails with an `AccessDenied` — **non-zero exit code**.

## Cleanup

```bash
./cleanup.sh
```
