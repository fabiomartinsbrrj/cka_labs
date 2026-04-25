#!/bin/bash
set -euo pipefail

NODE_HOSTNAME="${1:-}"
if [ -n "$NODE_HOSTNAME" ]; then
  echo "==> [fase1] Configurando hostname para $NODE_HOSTNAME..."
  hostnamectl set-hostname "$NODE_HOSTNAME"
fi

echo "==> [fase1] Atualizando pacotes..."
apt-get update -y

echo "==> [fase1] Instalando dependências..."
apt-get install -y apt-transport-https ca-certificates curl gpg conntrack socat

echo "==> [fase1] Desabilitando swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "==> [fase1] Carregando módulos do kernel..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "==> [fase1] Configurando parâmetros sysctl..."
cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv6.conf.all.rp_filter = 0
EOF
sysctl --system

echo "==> [fase1] Instalando containerd..."
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup.*/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl enable --now containerd

echo "==> [fase1] Instalando kubeadm, kubelet e kubectl v1.31..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' \
  | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet=1.31.0-1.1 kubeadm=1.31.0-1.1 kubectl=1.31.0-1.1
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

echo "==> [fase1] Validando instalação..."
systemctl is-active containerd
systemctl is-active kubelet
echo "==> [fase1] Concluído com sucesso!"
