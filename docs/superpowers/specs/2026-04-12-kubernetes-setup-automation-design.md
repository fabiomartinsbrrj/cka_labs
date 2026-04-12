# Design: Automação do Setup Kubernetes

**Data:** 2026-04-12
**Branch alvo:** feature/k8s-setup-automation

## Objetivo

Automatizar o setup do Kubernetes nas instâncias EC2 criadas pelo Terraform, com execução parametrizada em fases independentes via Makefile.

## Estrutura de Arquivos

```
cka_study/
├── Makefile
└── scripts/
    ├── fase1-node.sh       # instalação em todos os nós
    ├── fase2-control.sh    # kubeadm init + Cilium no controlplane
    └── fase2-worker.sh     # kubeadm join nos workers
```

## Nomes das Instâncias

O Terraform nomeará as instâncias EC2 como:
- `controlplane` — index 0 (node que executa kubeadm init)
- `node01` — index 1 (worker node)

Ajuste em `main.tf` para usar nomes condicionais em vez do padrão sequencial.

## Makefile

### Variáveis

```makefile
KEY ?= ~/workspace/cka-key.pem
SSH  = ssh -i $(KEY) -o StrictHostKeyChecking=no ubuntu@
```

`KEY` tem valor padrão mas pode ser sobrescrito: `make full KEY=/outro/caminho.pem`

### Targets

| Target | Descrição |
|--------|-----------|
| `make help` | Lista todos os targets com descrição |
| `make fase1` | Instala containerd, kubeadm, kubelet, kubectl em todos os nós |
| `make fase2` | Inicializa o cluster (kubeadm init + Cilium + kubeadm join) |
| `make full`  | Executa fase1 seguido de fase2 |

### Como usar

```bash
# Após terraform apply, rodar setup completo:
make full KEY=~/workspace/cka-key.pem

# Ou fases separadas:
make fase1 KEY=~/workspace/cka-key.pem
make fase2 KEY=~/workspace/cka-key.pem

# Definir KEY como variável de ambiente para não repetir:
export KEY=~/workspace/cka-key.pem
make full
```

O Makefile lê os IPs das instâncias automaticamente via `terraform output -json public_ips`, que retorna a lista de IPs públicos definida em `outputs.tf`.

## Scripts

### fase1-node.sh (executado em todos os nós)

Passos em ordem:
1. `apt-get update`
2. Instalar dependências: `apt-transport-https ca-certificates curl gpg conntrack socat`
3. Desabilitar swap (`swapoff -a` + comentar `/etc/fstab`)
4. Carregar módulos do kernel: `overlay`, `br_netfilter`
5. Configurar parâmetros sysctl para Kubernetes
6. Instalar e configurar containerd (com `SystemdCgroup = true`)
7. Instalar `kubelet=1.31.0-1.1`, `kubeadm=1.31.0-1.1`, `kubectl=1.31.0-1.1`
8. Habilitar kubelet (`systemctl enable --now kubelet`)
9. Validação: verificar se `containerd` e `kubelet` estão ativos

### fase2-control.sh (executado no controlplane)

Passos em ordem:
1. `kubeadm init`
2. Configurar kubeconfig para o usuário `ubuntu`
3. Instalar Cilium CLI
4. `cilium install`
5. Aguardar Cilium ficar ready (`cilium status --wait`)
6. Gerar e imprimir o comando `kubeadm join` completo

### fase2-worker.sh (executado nos workers)

Recebe o comando `kubeadm join` como argumento e o executa.

## Fluxo de Execução

```
terraform output -json
       │
       ▼
Makefile extrai IPs:
  CONTROL_IP = IPs[0]   → controlplane
  WORKER_IPS = IPs[1:]  → node01, node02...
       │
  ┌────┴────┐
fase1      fase2
  │          │
SSH todos   SSH controlplane → kubeadm init → captura join token
os nós      SSH workers      → kubeadm join <token>
```

## Tratamento de Erros

Todos os scripts usam `set -euo pipefail` no topo: qualquer comando que falhe interrompe o script imediatamente, evitando estado inconsistente. O Makefile exibe em qual nó e fase o erro ocorreu.

## Validação

- **Após fase1:** script verifica `systemctl is-active containerd kubelet` em cada nó
- **Após fase2:** Makefile executa `kubectl get nodes` via SSH no controlplane e exibe o resultado

## Decisão de Design: SSH vs user_data

Os scripts são executados via SSH em vez de `user_data` do Terraform pelos seguintes motivos:

1. **Coordenação entre nós:** a fase2 exige que o controlplane finalize o `kubeadm init` e gere o token antes dos workers executarem o `kubeadm join`. Com `user_data`, todos os nós sobem em paralelo sem coordenação possível.
2. **Re-executabilidade:** `user_data` roda apenas uma vez na criação da instância. SSH permite re-executar qualquer fase a qualquer momento.
3. **Visibilidade:** erros aparecem diretamente no terminal em vez de exigir acesso ao log da instância.
