KEY ?= $(HOME)/workspace/cka-key.pem
SSH  := ssh -i $(KEY) -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@

.DEFAULT_GOAL := help
.PHONY: help fase1 fase2 full kubeconfig

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
	$(SSH)$$CONTROL_IP 'sudo bash -s controlplane' < scripts/fase1-node.sh; \
	INDEX=1; \
	for ip in $$WORKER_IPS; do \
		WORKER_NAME=$$(printf "node%02d" $$INDEX); \
		echo "==> [fase1] Configurando worker ($$ip) como $$WORKER_NAME..."; \
		$(SSH)$$ip "sudo bash -s $$WORKER_NAME" < scripts/fase1-node.sh; \
		INDEX=$$((INDEX + 1)); \
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

kubeconfig: ## Baixa e configura o kubeconfig do controlplane (~/.workspace/cka-kubeconfig.yaml)
	@set -e; \
	CONTROL_IP=$$(terraform output -json public_ips | jq -r '.[0]'); \
	KUBECONFIG_PATH=$(HOME)/workspace/cka-kubeconfig.yaml; \
	echo "==> Baixando kubeconfig do controlplane ($$CONTROL_IP)..."; \
	scp -i $(KEY) -o StrictHostKeyChecking=no ubuntu@$$CONTROL_IP:/home/ubuntu/.kube/config $$KUBECONFIG_PATH; \
	echo "==> Substituindo IP privado pelo IP público..."; \
	sed -i "s|https://10\.[^:]*:6443|https://$$CONTROL_IP:6443|" $$KUBECONFIG_PATH; \
	echo "==> Configurando acesso sem TLS verify..."; \
	kubectl --kubeconfig $$KUBECONFIG_PATH config set-cluster kubernetes --certificate-authority=""; \
	kubectl --kubeconfig $$KUBECONFIG_PATH config set-cluster kubernetes --insecure-skip-tls-verify=true; \
	echo "==> Kubeconfig salvo em $$KUBECONFIG_PATH"; \
	echo "==> Execute: export KUBECONFIG=$$KUBECONFIG_PATH"
