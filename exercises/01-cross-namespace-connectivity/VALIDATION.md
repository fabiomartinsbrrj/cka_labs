# Validation — Exercise 01

Run these commands **after** applying your solution.

## 1. Check pods are running

```bash
kubectl get pods -n project-a -o wide
kubectl get pods -n project-b -o wide
```

## 2. Test allowed traffic (must succeed)

Pods with `role=service` should reach the database on port 5432:

```bash
kubectl exec -n project-a deploy/service -- nc -w 2 db.project-b.svc.cluster.local 5432
echo "Exit code: $?"
```

Expected: **exit code 0** (connection established).

## 3. Test blocked traffic (must fail)

Pods with `role=web` should be blocked from reaching the database:

```bash
kubectl exec -n project-a deploy/web -- nc -w 2 db.project-b.svc.cluster.local 5432
echo "Exit code: $?"
```

Expected: **non-zero exit code** after the 2-second timeout (connection timed out, not refused).

## 4. Verify default-deny is in place

No other pod outside of `project-a` with `role=service` should reach `project-b`:

```bash
kubectl run intruder --image=busybox:1.36 --rm -it --restart=Never \
  -- nc -w 2 db.project-b.svc.cluster.local 5432
echo "Exit code: $?"
```

Expected: **non-zero exit code** (blocked by default-deny).

## Cleanup

```bash
kubectl delete -f setup/
```
