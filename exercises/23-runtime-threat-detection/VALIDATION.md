# Validation — Exercise 23

## 1. Falco is running

```bash
ssh -i $KEY ubuntu@<node-ip> 'sudo systemctl status falco --no-pager | head -5'
```
Expected: `active (running)`.

## 2. Built-in rule — shell spawned in container

```bash
kubectl exec -n exposed-app deploy/webshop -- /bin/sh -c "sh"
```

```bash
ssh -i $KEY ubuntu@<node-ip> 'sudo journalctl -u falco --no-pager | tail -20'
```
Expected: an alert referencing a shell being spawned inside a container, naming the `webshop` pod/namespace.

## 3. Built-in rule — sensitive file read

```bash
kubectl exec -n exposed-app deploy/webshop -- cat /etc/shadow
```

```bash
ssh -i $KEY ubuntu@<node-ip> 'sudo journalctl -u falco --no-pager | tail -20'
```
Expected: an alert referencing a sensitive file being read, naming `/etc/shadow`.

## 4. Custom rule — curl/wget detection

```bash
ssh -i $KEY ubuntu@<node-ip> 'sudo cat /etc/falco/rules.d/custom-rules.yaml'
```
Expected: a rule matching `proc.name in (curl, wget)` scoped (or at least applicable) to `exposed-app`.

```bash
kubectl exec -n exposed-app deploy/webshop -- sh -c "apt-get install -y curl >/dev/null 2>&1 || true; curl -s example.com >/dev/null || true"
```

```bash
ssh -i $KEY ubuntu@<node-ip> 'sudo journalctl -u falco --no-pager | tail -20'
```
Expected: your custom rule fires, with the output format showing user, command, container, namespace and pod — not just a generic message.

## 5. Incident write-up exists and is accurate

```bash
test -f INCIDENT.md && echo "present"
```
Expected: `INCIDENT.md` correctly lists, in order: shell spawn → sensitive file read → curl execution, each tied to the `webshop` pod in `exposed-app`, reconstructed from the Falco log lines alone.

## Cleanup

```bash
kubectl delete -f setup/
ssh -i $KEY ubuntu@<node-ip> 'sudo rm -f /etc/falco/rules.d/custom-rules.yaml && sudo systemctl restart falco'
```
