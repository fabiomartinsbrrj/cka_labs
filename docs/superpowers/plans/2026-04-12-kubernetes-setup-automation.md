# Kubernetes Setup Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar Makefile com targets `fase1`, `fase2` e `full` que automatizam o setup do Kubernetes nas instâncias EC2 via SSH após o `terraform apply`.

**Architecture:** O Makefile lê os IPs públicos via `terraform output -json public_ips` e executa scripts bash nos nós remotos via SSH. A fase1 prepara todos os nós em paralelo. A fase2 inicializa o controlplane, captura o token de join via stdout e adiciona os workers ao cluster.

**Tech Stack:** Bash, GNU Make, SSH, kubeadm 1.31, containerd, Cilium CLI, jq (dependência local para parsear o output do Terraform)

---

## Arquivos

| Ação | Arquivo | Responsabilidade |
|------|---------|-----------------|
| Modificar | `main.tf` linha 117 | Renomear instâncias para `controlplane` / `node01` |
| Criar | `scripts/fase1-node.sh` | Instalar containerd + kubeadm + kubelet + kubectl em um nó |
| Criar | `scripts/fase2-control.sh` | kubeadm init + Cilium + imprime join command em stdout |
| Criar | `Makefile` | Targets help / fase1 / fase2 / full |
| Modificar | `README.md` | Documentar uso do Makefile |

> **Nota de simplificação vs spec:** O `fase2-worker.sh` foi removido. O join command é passado inline via SSH no Makefile — adicionar um script wrapper não agrega valor (YAGNI).

---

## Task 1: Renomear instâncias EC2 no Terraform

**Files:**
- Modify: `main.tf:117`

- [ ] **Step 1: Verificar o estado atual do nome das instâncias**

```bash
grep -n "Name" main.tf
```
Esperado: linha 117 com `format("%s-node-%02d", var.name_prefix, count.index + 1)`

- [ ] **Step 2: Alterar a lógica de nomeação**

Em `main.tf`, substituir a linha 117:

```hcl
# antes:
Name = format("%s-node-%02d", var.name_prefix, count.index + 1)

# depois:
Name = count.index == 0 ? "controlplane" : format("node%02d", count.index)
```

- [ ] **Step 3: Validar o Terraform**

```bash
terraform validate
```
Esperado: `Success! The configuration is valid.`

- [ ] **Step 4: Commit**

```bash
git add main.tf
git commit -m "feat: rename EC2 instances to controlplane/node01"
```

---

## Task 2: Criar scripts/fase1-node.sh

**Files:**
- Create: `scripts/fase1-node.sh`

Este script roda como `root` em cada nó e instala tudo necessário para o Kubernetes. Deve ser idempotente — re-executar não quebra o nó.

- [ ] **Step 1: Criar o diretório scripts**

```bash
mkdir -p scripts
```

- [ ] **Step 2: Verificar que bash -n falha em arquivo vazio com erro esperado**

```bash
echo "#!/bin/bash" > scripts/fase1-node.sh && bash -n scripts/fase1-node.sh
```
Esperado: sem erro (um shebang é válido).

- [ ] **Step 3: Escrever o script completo**

Criar `scripts/fase1-node.sh` com o conteúdo abaixo:

```bash
#!/bin/bash
set -euo pipefail

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
```

- [ ] **Step 4: Verificar sintaxe**

```bash
bash -n scripts/fase1-node.sh
```
Esperado: nenhuma saída (sem erros de sintaxe).

- [ ] **Step 5: Tornar executável e commitar**

```bash
chmod +x scripts/fase1-node.sh
git add scripts/fase1-node.sh
git commit -m "feat: add fase1-node.sh - install containerd and kubernetes components"
```

---

## Task 3: Criar scripts/fase2-control.sh

**Files:**
- Create: `scripts/fase2-control.sh`

Este script roda no controlplane. Todo output de progresso vai para **stderr**. Apenas o join command vai para **stdout** — isso permite que o Makefile capture o join command com `$(...)` sem capturar logs.

- [ ] **Step 1: Escrever o script**

Criar `scripts/fase2-control.sh` com o conteúdo abaixo:

```bash
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
  https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} 2>&1 >&2
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum >&2
tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin >&2
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

echo "==> [fase2-control] Instalando Cilium no cluster..." >&2
export KUBECONFIG=/etc/kubernetes/admin.conf
cilium install >&2

echo "==> [fase2-control] Aguardando Cilium ficar pronto..." >&2
cilium status --wait >&2

echo "==> [fase2-control] Gerando token de join..." >&2
# Apenas esta linha vai para stdout — capturada pelo Makefile
kubeadm token create --print-join-command
```

- [ ] **Step 2: Verificar sintaxe**

```bash
bash -n scripts/fase2-control.sh
```
Esperado: nenhuma saída.

- [ ] **Step 3: Tornar executável e commitar**

```bash
chmod +x scripts/fase2-control.sh
git add scripts/fase2-control.sh
git commit -m "feat: add fase2-control.sh - kubeadm init, Cilium, and join token"
```

---

## Task 4: Criar Makefile

**Files:**
- Create: `Makefile`

**Dependência local:** o Makefile usa `jq` para parsear o output JSON do Terraform. Se o usuário não tiver `jq`, o Make falhará com `jq: command not found`.

- [ ] **Step 1: Verificar que make help ainda não existe**

```bash
make help 2>&1 || true
```
Esperado: erro como `make: *** No rule to make target 'help'`.

- [ ] **Step 2: Criar o Makefile**

Criar `Makefile` com o conteúdo abaixo. Atenção: as linhas de recipe **devem usar TAB**, não espaços.

```makefile
KEY ?= $(HOME)/workspace/cka-key.pem
SSH  := ssh -i $(KEY) -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@

.DEFAULT_GOAL := help
.PHONY: help fase1 fase2 full

help: ## Mostra os targets disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Variáveis:"
	@echo "  KEY   Caminho da chave SSH (padrão: $(HOME)/workspace/cka-key.pem)"
	@echo ""
	@echo "Exemplos:"
	@echo "  make full KEY=~/workspace/cka-key.pem"
	@echo "  export KEY=~/workspace/cka-key.pem && make full"

fase1: ## Instala containerd, kubeadm, kubelet e kubectl em todos os nós
	@set -e; \
	CONTROL_IP=$$(terraform output -json public_ips | jq -r '.[0]'); \
	WORKER_IPS=$$(terraform output -json public_ips | jq -r '.[1:][]'); \
	echo "==> [fase1] Configurando controlplane ($$CONTROL_IP)..."; \
	$(SSH)$$CONTROL_IP 'sudo bash -s' < scripts/fase1-node.sh; \
	for ip in $$WORKER_IPS; do \
		echo "==> [fase1] Configurando worker ($$ip)..."; \
		$(SSH)$$ip 'sudo bash -s' < scripts/fase1-node.sh; \
	done; \
	echo "==> Fase 1 concluída em todos os nós!"

fase2: ## Inicializa o cluster Kubernetes (kubeadm init + Cilium + join dos workers)
	@set -e; \
	CONTROL_IP=$$(terraform output -json public_ips | jq -r '.[0]'); \
	WORKER_IPS=$$(terraform output -json public_ips | jq -r '.[1:][]'); \
	echo "==> [fase2] Inicializando controlplane ($$CONTROL_IP)..."; \
	JOIN_CMD=$$($(SSH)$$CONTROL_IP 'sudo bash -s' < scripts/fase2-control.sh); \
	echo "==> [fase2] Join command capturado: $$JOIN_CMD"; \
	for ip in $$WORKER_IPS; do \
		echo "==> [fase2] Adicionando worker ($$ip) ao cluster..."; \
		$(SSH)$$ip "sudo $$JOIN_CMD"; \
	done; \
	echo "==> Verificando cluster..."; \
	$(SSH)$$CONTROL_IP 'kubectl get nodes'

full: fase1 fase2 ## Executa fase1 e fase2 (setup completo do cluster)
```

- [ ] **Step 3: Verificar que make help funciona**

```bash
make help
```
Esperado:
```
  fase1      Instala containerd, kubeadm, kubelet e kubectl em todos os nós
  fase2      Inicializa o cluster Kubernetes (kubeadm init + Cilium + join dos workers)
  full       Executa fase1 e fase2 (setup completo do cluster)

Variáveis:
  KEY   Caminho da chave SSH (padrão: /home/<user>/workspace/cka-key.pem)
```

- [ ] **Step 4: Dry-run do fase1 para verificar que os targets existem**

```bash
make -n fase1 KEY=~/workspace/cka-key.pem
```
Esperado: comandos impressos sem executar, sem erros de sintaxe do Make.

- [ ] **Step 5: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile with fase1, fase2 and full targets"
```

---

## Task 5: Atualizar README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Adicionar seção de uso do Makefile após a seção "Como usar"**

Adicionar após o bloco `### 3. Executar o Terraform` e antes de `### 4. Conectar via SSH às instâncias`:

```markdown
### 4. Configurar o cluster Kubernetes com o Makefile

Após o `terraform apply`, use o Makefile para automatizar o setup:

```bash
# Setup completo (fase1 + fase2):
make full KEY=~/workspace/cka-key.pem

# Ou em etapas separadas:
make fase1 KEY=~/workspace/cka-key.pem   # instala containerd, kubeadm, kubelet, kubectl
make fase2 KEY=~/workspace/cka-key.pem   # inicializa o cluster (kubeadm init + Cilium + join)

# Para não repetir o KEY toda vez:
export KEY=~/workspace/cka-key.pem
make full
```

**Pré-requisito:** `jq` instalado localmente (usado para parsear o output do Terraform).

```bash
# Ubuntu/Debian:
sudo apt-get install -y jq

# Mac:
brew install jq
```

**Targets disponíveis:**
```bash
make help
```
```

- [ ] **Step 2: Verificar que a seção foi inserida corretamente**

```bash
grep -n "Makefile\|make full\|make fase" README.md | head -10
```
Esperado: linhas com as referências ao Makefile.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document Makefile usage in README"
```

---

## Self-Review do Plano

**Cobertura do spec:**
- ✅ Makefile com targets `help`, `fase1`, `fase2`, `full`
- ✅ Variável `KEY` configurável com default
- ✅ `fase1-node.sh` cobre todos os 9 passos do spec
- ✅ `fase2-control.sh` cobre os 6 passos + join command via stdout
- ✅ `set -euo pipefail` em todos os scripts
- ✅ Validação após fase1 (`systemctl is-active`)
- ✅ Validação após fase2 (`kubectl get nodes`)
- ✅ Renomeação das instâncias para `controlplane` / `node01`
- ✅ README atualizado com instruções de uso
- ⚠️ `fase2-worker.sh` removido intencionalmente (YAGNI — join command passa inline via SSH)

**Dependência externa adicionada:** `jq` — documentada no README e nos pré-requisitos da Task 4.
