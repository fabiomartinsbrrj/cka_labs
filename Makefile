KEY ?= $(HOME)/workspace/cka-key.pem
SSH  := ssh -i $(KEY) -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@

.DEFAULT_GOAL := help
.PHONY: help fase1 fase2 full

help: ## Mostra os targets disponíveis
	@grep -E '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST) | \
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
