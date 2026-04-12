# CKA Study Lab - Infraestrutura AWS com Terraform

Este projeto cria uma infraestrutura na AWS para estudos do Certified Kubernetes Administrator (CKA) usando Terraform.

## 📋 Pré-requisitos

- AWS CLI configurado com credenciais válidas
- Terraform instalado (versão >= 1.0)
- Acesso à região `us-east-1` na AWS

## 🚀 Como usar

### 1. Criar o Key Pair na AWS

Primeiro, você precisa criar um key pair na AWS para acessar as instâncias EC2:

```bash
# Criar o key pair na região us-east-1
aws ec2 create-key-pair --key-name cka-key --region us-east-1 --query 'KeyMaterial' --output text > ~/workspace/cka-key.pem

# Definir permissões corretas para a chave privada
chmod 400 ~/workspace/cka-key.pem
```

### 2. Verificar se o Key Pair foi criado

```bash
# Listar key pairs na região
aws ec2 describe-key-pairs --region us-east-1
```

### 3. Executar o Terraform

```bash
# Inicializar o Terraform (primeira vez)
terraform init

# Planejar a execução (opcional)
terraform plan -var="key_name=cka-key"

# Aplicar a infraestrutura
terraform apply -auto-approve -var="key_name=cka-key"
```

### 4. Conectar via SSH às instâncias

Após a execução bem-sucedida do Terraform, você verá os IPs públicos das instâncias nos outputs:

```bash
# Conectar ao primeiro nó
ssh -i ~/workspace/cka-key.pem ubuntu@<IP_PUBLICO_NODE_1>

# Conectar ao segundo nó
ssh -i ~/workspace/cka-key.pem ubuntu@<IP_PUBLICO_NODE_2>
```

**Exemplo:**

```bash
ssh -i ~/workspace/cka-key.pem ubuntu@54.233.45.51
ssh -i ~/workspace/cka-key.pem ubuntu@54.94.133.212
```

## ⚙️ Configuração Pós-Instalação

Após conectar em instância via SSH, execute os comandos abaixo para preparar o ambiente para o Kubernetes:

### 1. Atualizar o sistema e instalar dependências

```bash
sudo su -

apt-get update -y

# Instalar dependências básicas https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ 
apt-get install -y apt-transport-https ca-certificates curl gpg conntrack socat

# colocar restos doc comandos aqui
swapoff -a

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF


modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv6.conf.all.rp_filter = 0
EOF

sysctl --system

#Containerd 
apt install -y containerd
mkdir -p /etc/containerd

containerd config default | tee /etc/containerd/config.toml

sed -i 's/SystemdCgroup.*/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl enable --now containerd
systemctl status containerd

```

### 2. Instalar kubeadm, kubelet e kubectl

```bash
# Adicionar chave GPG do Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Adicionar repositório do Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Atualizar lista de pacotes e instalar
apt-get update -y
apt-get install -y kubelet=1.31.0-1.1 kubeadm=1.31.0-1.1 kubectl=1.31.0-1.1
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet
systemctl status kubelet
```

### 3. Configurar o Control Plane (apenas no primeiro nó)

```bash
# Inicializar o cluster (executar apenas no nó master)
kubeadm init

# Configurar kubectl para o usuário ubuntu
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

reboot

# Instalar CNI (Flannel)
# kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### 4. Instalar a Cilium

```bash
# Instalar a Cilium https://docs.cilium.io/en/stable/installation/k8s-install-kubeadm/

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Verificar a Cilium
cilium status

# Instalar a Cilium
cilium install

```

### 4. Adicionar Worker Nodes (nos demais nós)

```bash
# Executar o comando join que aparece após o kubeadm init
# Exemplo:
# sudo kubeadm join <IP_MASTER>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### 5. Verificar o cluster

```bash
# Verificar nós
kubectl get nodes

# Verificar pods do sistema
kubectl get pods -n kube-system
```

/etc/kubernetes/pki = Diretório com os certificados do cluster. Todos os componentes tem uma CA principal e todos eles tem uma chave privada e um certificado.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [ip-10-20-1-64 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.20.1.64]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [ip-10-20-1-64 localhost] and IPs [10.20.1.64 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [ip-10-20-1-64 localhost] and IPs [10.20.1.64 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key

Ir no WORKER NODE e executar o comando abaixo:
executar os mesmos comandos do master node até o kubeadm join

sudo su -
apt-get update -y

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv6.conf.all.rp_filter = 0
EOF

sysctl --system

# Containerd

apt install -y containerd
mkdir -p /etc/containerd

containerd config default | tee /etc/containerd/config.toml

sed -i 's/SystemdCgroup.*/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl enable --now containerd
systemctl status containerd

apt-get install -y apt-transport-https ca-certificates curl gpg conntrack socat

curl -fsSL <https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key> | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Adicionar repositório do Kubernetes

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] <https://pkgs.k8s.io/core:/stable:/v1.31/deb/> /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y

apt-get install -y kubelet=1.31.0-1.1 kubeadm=1.31.0-1.1 kubectl=1.31.0-1.1
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet
systemctl status kubelet

## 🏗️ Recursos Criados

A infraestrutura inclui:

- **VPC**: Rede virtual privada (10.20.0.0/16)
- **Subnet Pública**: Sub-rede pública (10.20.1.0/24)
- **Internet Gateway**: Para acesso à internet
- **Route Table**: Tabela de roteamento para tráfego público
- **Security Group**: Regras de firewall (SSH + tráfego interno)
- **2 Instâncias EC2**: Ubuntu 22.04 LTS (t3.medium)

## 🔧 Configurações

### Variáveis Disponíveis

- `key_name`: Nome do key pair AWS (padrão: "cka-key")
- `instances`: Número de instâncias (padrão: 2)
- `instance_type`: Tipo da instância (padrão: "t3.medium")
- `name_prefix`: Prefixo para nomes dos recursos (padrão: "cka-lab")
- `allowed_ssh_cidr`: CIDR permitido para SSH (padrão: "0.0.0.0/0")

### Exemplo com variáveis customizadas

```bash
terraform apply -auto-approve \
  -var="key_name=meu-key" \
  -var="instances=3" \
  -var="instance_type=t3.large"
```

## 🔒 Segurança

### Acesso SSH Automático (Recomendado)

Por padrão, o projeto **detecta automaticamente seu IP público** e permite SSH apenas do seu IP atual:

- Usa o serviço `https://checkip.amazonaws.com` para detectar seu IP
- Aplica a regra `SEU_IP/32` no Security Group automaticamente
- **Muito mais seguro** que permitir acesso de qualquer IP

### Opções de Configuração SSH

**Usar seu IP automaticamente (padrão):**

```bash
terraform apply -auto-approve -var="key_name=cka-key"
# Permite SSH apenas do seu IP atual
```

**Permitir SSH de qualquer IP (não recomendado):**

```bash
terraform apply -auto-approve -var="key_name=cka-key" -var="allowed_ssh_cidr=0.0.0.0/0"
# ⚠️ INSEGURO: Permite SSH de qualquer lugar da internet
```

**Especificar um IP específico:**

```bash
terraform apply -auto-approve -var="key_name=cka-key" -var="allowed_ssh_cidr=203.0.113.1/32"
# Permite SSH apenas do IP 203.0.113.1
```

### Comunicação entre Instâncias

- As instâncias podem se comunicar entre si através do Security Group
- Todo tráfego interno é permitido para facilitar configuração do Kubernetes

## 🧹 Limpeza

Para destruir toda a infraestrutura:

```bash
terraform destroy -auto-approve -var="key_name=cka-key"
```

**⚠️ Importante:** Isso irá remover todas as instâncias e recursos criados!

## 📝 Outputs

Após a execução, o Terraform exibirá:

- `public_ips`: Lista dos IPs públicos das instâncias
- `ssh_commands`: Comandos SSH prontos para usar

## 🐛 Troubleshooting

### Erro: "The key pair 'X' does not exist"

- Verifique se o key pair foi criado na região correta (`us-east-1`)
- Use o comando de verificação mencionado no passo 2

### Erro: "Incorrect attribute value type"

- Certifique-se de que está usando a versão mais recente dos arquivos Terraform
- O `cidr_block` deve ser uma string, não uma lista

### Erro de permissão na chave SSH

```bash
chmod 400 ~/workspace/cka-key.pem
```
