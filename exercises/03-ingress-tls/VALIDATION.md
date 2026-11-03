# Validation — Exercise 03

## 1. TLS Secret exists

```bash
kubectl get secret -n shop -l "" | grep tls
kubectl get secret storefront-tls -n shop -o jsonpath='{.type}'
```
Expected: `kubernetes.io/tls`.

## 2. Ingress references the Secret and host

```bash
kubectl get ingress -n shop storefront -o yaml
```
Expected: `spec.tls[0].secretName: storefront-tls`, `spec.tls[0].hosts` includes `storefront.cks-lab.local`, a matching rule routes to the `storefront` Service.

## 3. HTTPS works end-to-end

```bash
NODE_IP=<any-node-public-ip>
HTTPS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

curl -k --resolve storefront.cks-lab.local:$HTTPS_PORT:$NODE_IP \
  https://storefront.cks-lab.local:$HTTPS_PORT/
```
Expected: the nginx welcome page HTML.

## 4. Plain HTTP redirects to HTTPS

```bash
HTTP_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

curl -I --resolve storefront.cks-lab.local:$HTTP_PORT:$NODE_IP \
  http://storefront.cks-lab.local:$HTTP_PORT/
```
Expected: `HTTP/1.1 308 Permanent Redirect` (or `301`/`302`) with a `Location: https://...` header — not a 200 serving plaintext content.

## Cleanup

```bash
kubectl delete -f setup/
kubectl delete ingress storefront -n shop --ignore-not-found
kubectl delete secret storefront-tls -n shop --ignore-not-found
helm uninstall ingress-nginx -n ingress-nginx
```
