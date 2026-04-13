#!/bin/bash
set -euo pipefail

echo "==> [fase2-control] Inicializando cluster com kubeadm..." >&2
kubeadm init 2>&1 | tee /tmp/kubeadm-init.log >&2

echo "==> [fase2-control] Configurando kubeconfig para ubuntu..." >&2
mkdir -p /home/ubuntu/.kube
cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

echo "==> [fase2-control] Instalando Cilium CLI..." >&2
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all \
  "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz" \
  "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz.sha256sum" 2>&1 >&2
sha256sum --check "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum" >&2
tar xzvfC "cilium-linux-${CLI_ARCH}.tar.gz" /usr/local/bin >&2
rm "cilium-linux-${CLI_ARCH}.tar.gz" "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum"

echo "==> [fase2-control] Instalando Cilium no cluster..." >&2
export KUBECONFIG=/etc/kubernetes/admin.conf
cilium install >&2

echo "==> [fase2-control] Aguardando Cilium ficar pronto..." >&2
cilium status --wait >&2

echo "==> [fase2-control] Gerando token de join..." >&2
# Apenas esta linha vai para stdout — capturada pelo Makefile via JOIN_CMD=$(...)
kubeadm token create --print-join-command
