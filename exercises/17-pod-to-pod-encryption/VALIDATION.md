# Validation — Exercise 17

## 1. WireGuard encryption is enabled and healthy

```bash
cilium encrypt status
```
Expected: `Encryption: Wireguard`, with all nodes listed as peers and no errors.

```bash
cilium status | grep -i encryption
```
Expected: confirms WireGuard is the active encryption mode.

## 2. Traffic is actually encrypted on the wire

Repeat the baseline capture from the README, this time with encryption enabled:

```bash
ssh -i $KEY ubuntu@<server-node-ip> 'sudo tcpdump -i <iface> -A -s 0 "tcp port 80"'
```

```bash
kubectl exec -n secure-mesh deploy/client -- wget -qO- server.secure-mesh.svc.cluster.local
```

Expected: **no readable HTTP payload** in the capture — the physical interface only carries WireGuard-encrypted UDP packets between the nodes now. If you still see plaintext `HTTP/1.1` text, encryption is not actually wrapping pod-to-pod traffic.

## 3. Application still works end-to-end

```bash
kubectl exec -n secure-mesh deploy/client -- wget -qO- server.secure-mesh.svc.cluster.local
echo "Exit code: $?"
```
Expected: exit code `0` and the nginx welcome page HTML — encryption must be transparent to the application.

## Cleanup

```bash
kubectl delete -f setup/
```

Disabling WireGuard afterward (optional, cluster-wide Helm value):

```bash
cilium upgrade --set encryption.enabled=false
```
