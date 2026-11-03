# CKS Study Notes — Certified Kubernetes Security Specialist

Este arquivo é o ponto central de anotações e progresso para o estudo do **CKS (Certified Kubernetes Security Specialist)**, usando o mesmo cluster/lab provisionado por este repositório (ver [README.md](./README.md) para o setup de infraestrutura).

Referência oficial dos domínios e competências:
https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/

## 📊 Domínios & Competências (peso na prova)

| # | Domínio | Peso |
|---|---------|------|
| 1 | [Cluster Setup](#1-cluster-setup-15) | 15% |
| 2 | [Cluster Hardening](#2-cluster-hardening-15) | 15% |
| 3 | [System Hardening](#3-system-hardening-10) | 10% |
| 4 | [Minimize Microservice Vulnerabilities](#4-minimize-microservice-vulnerabilities-20) | 20% |
| 5 | [Supply Chain Security](#5-supply-chain-security-20) | 20% |
| 6 | [Monitoring, Logging and Runtime Security](#6-monitoring-logging-and-runtime-security-20) | 20% |

**Pré-requisito do lab:** cluster kubeadm (controlplane + workers) com Cilium como CNI, provisionado via `terraform apply` + `make full` (ver raiz do projeto). O CNI Cilium é usado deliberadamente porque cobre tanto NetworkPolicy (Domínio 1) quanto Pod-to-Pod encryption (Domínio 4).

## 📁 Estrutura de exercícios (`exercises/`)

Cada subpasta de `exercises/` mapeia **1:1** para uma competência (bullet) oficial do CKS. O número do prefixo não segue a ordem do site — segue a ordem em que os exercícios foram criados neste repo, agrupados por domínio.

Status: ✅ todos os 24 exercícios têm README + setup/ (quando aplicável) + VALIDATION.md completos.

### 1. Cluster Setup (15%)

| Pasta | Competência | Status |
|-------|-------------|--------|
| [`exercises/01-cross-namespace-connectivity/`](exercises/01-cross-namespace-connectivity/) | Use Network security policies to restrict cluster level access | ✅ Completo |
| [`exercises/02-cis-benchmark/`](exercises/02-cis-benchmark/) | Use CIS benchmark to review the security configuration of Kubernetes components | ✅ Completo |
| [`exercises/03-ingress-tls/`](exercises/03-ingress-tls/) | Properly set up Ingress with TLS | ✅ Completo |
| [`exercises/04-protect-node-metadata/`](exercises/04-protect-node-metadata/) | Protect node metadata and endpoints | ✅ Completo |
| [`exercises/05-verify-platform-binaries/`](exercises/05-verify-platform-binaries/) | Verify platform binaries before deploying | ✅ Completo |

### 2. Cluster Hardening (15%)

| Pasta | Competência | Status |
|-------|-------------|--------|
| [`exercises/06-rbac-least-privilege/`](exercises/06-rbac-least-privilege/) | Use Role Based Access Controls to minimize exposure | ✅ Completo |
| [`exercises/07-service-account-hardening/`](exercises/07-service-account-hardening/) | Exercise caution in using service accounts e.g. disable defaults, minimize permissions | ✅ Completo |
| [`exercises/08-restrict-api-access/`](exercises/08-restrict-api-access/) | Restrict access to Kubernetes API | ✅ Completo |
| [`exercises/09-kubernetes-upgrade/`](exercises/09-kubernetes-upgrade/) | Upgrade Kubernetes to avoid vulnerabilities | ✅ Completo |

### 3. System Hardening (10%)

| Pasta | Competência | Status |
|-------|-------------|--------|
| [`exercises/10-minimize-host-os-footprint/`](exercises/10-minimize-host-os-footprint/) | Minimize host OS footprint (reduce attack surface) | ✅ Completo |
| [`exercises/11-iam-least-privilege/`](exercises/11-iam-least-privilege/) | Using least-privilege identity and access management | ✅ Completo |
| [`exercises/12-minimize-external-access/`](exercises/12-minimize-external-access/) | Minimize external access to the network | ✅ Completo |
| [`exercises/13-apparmor-seccomp/`](exercises/13-apparmor-seccomp/) | Appropriately use kernel hardening tools such as AppArmor, seccomp | ✅ Completo |

### 4. Minimize Microservice Vulnerabilities (20%)

| Pasta | Competência | Status |
|-------|-------------|--------|
| [`exercises/14-pod-security-standards/`](exercises/14-pod-security-standards/) | Use appropriate pod security standards | ✅ Completo |
| [`exercises/15-secrets-management/`](exercises/15-secrets-management/) | Manage Kubernetes secrets | ✅ Completo |
| [`exercises/16-isolation-sandboxed-containers/`](exercises/16-isolation-sandboxed-containers/) | Understand and implement isolation techniques (multi-tenancy, sandboxed containers) | ✅ Completo |
| [`exercises/17-pod-to-pod-encryption/`](exercises/17-pod-to-pod-encryption/) | Implement Pod-to-Pod encryption (Cilium, Istio) | ✅ Completo |

### 5. Supply Chain Security (20%)

| Pasta | Competência | Status |
|-------|-------------|--------|
| [`exercises/18-minimize-base-image-footprint/`](exercises/18-minimize-base-image-footprint/) | Minimize base image footprint | ✅ Completo |
| [`exercises/19-supply-chain-sbom/`](exercises/19-supply-chain-sbom/) | Understand your supply chain (e.g. SBOM, CI/CD, artifact repositories) | ✅ Completo |
| [`exercises/20-secure-registries-sign-artifacts/`](exercises/20-secure-registries-sign-artifacts/) | Secure your supply chain (permitted registries, sign and validate artifacts) | ✅ Completo |
| [`exercises/21-static-analysis-workloads/`](exercises/21-static-analysis-workloads/) | Perform static analysis of user workloads and container images | ✅ Completo |

### 6. Monitoring, Logging and Runtime Security (20%)

| Pasta | Competência | Status |
|-------|-------------|--------|
| [`exercises/22-audit-logs/`](exercises/22-audit-logs/) | Use Kubernetes audit logs to monitor access | ✅ Completo |
| [`exercises/23-runtime-threat-detection/`](exercises/23-runtime-threat-detection/) | Perform behavioral analytics to detect malicious activities; Detect threats within physical infrastructure, apps, networks, data, users and workloads; Investigate and identify phases of attack and bad actors within the environment | ✅ Completo |
| [`exercises/24-immutable-containers-runtime/`](exercises/24-immutable-containers-runtime/) | Ensure immutability of containers at runtime | ✅ Completo |

> **Nota:** `23-runtime-threat-detection` consolida 3 bullets do domínio 6 porque, na prática, são exercitados juntos com a mesma ferramenta (ex: Falco) — behavioral analytics, detecção de ameaças e investigação de fases de ataque não se separam bem em exercícios distintos.

## 📝 Anotações por domínio

Use esta seção para registrar conceitos, comandos e pegadinhas conforme for estudando. Preencher à medida que os exercícios forem completados.

### 1. Cluster Setup (15%)

- _(anotações pendentes)_

### 2. Cluster Hardening (15%)

- _(anotações pendentes)_

### 3. System Hardening (10%)

- _(anotações pendentes)_

### 4. Minimize Microservice Vulnerabilities (20%)

- _(anotações pendentes)_

### 5. Supply Chain Security (20%)

- _(anotações pendentes)_

### 6. Monitoring, Logging and Runtime Security (20%)

- _(anotações pendentes)_

## 🔧 Ferramentas que vamos precisar instalar no lab

Lista de ferramentas externas ao kubeadm/Cilium básico que os exercícios acima vão exigir, para referência futura (ainda não instaladas):

| Ferramenta | Para qual(is) exercício(s) |
|------------|------------------------------|
| `kube-bench` | 02-cis-benchmark |
| Ingress controller (ex: ingress-nginx) + cert-manager | 03-ingress-tls |
| `kubeadm upgrade` / múltiplas versões do k8s | 09-kubernetes-upgrade |
| AppArmor / seccomp profiles | 13-apparmor-seccomp |
| gVisor ou Kata Containers | 16-isolation-sandboxed-containers |
| Cilium Transparent Encryption (WireGuard/IPsec) ou Istio mTLS | 17-pod-to-pod-encryption |
| `trivy` ou `grype` (scan de imagens) | 18-minimize-base-image-footprint, 21-static-analysis-workloads |
| `syft` (geração de SBOM) | 19-supply-chain-sbom |
| `cosign` (assinatura de imagens) + admission controller (Kyverno/OPA Gatekeeper) | 20-secure-registries-sign-artifacts |
| Audit policy no `kube-apiserver` (`--audit-log-path`, `--audit-policy-file`) | 22-audit-logs |
| `Falco` | 23-runtime-threat-detection |
| Admission controller para read-only root filesystem | 24-immutable-containers-runtime |

## 🔗 Referências

- Domains & Competencies oficial: https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/
- [CKS-Certified-Kubernetes-Security-Specialist](https://github.com/theplatformlab/CKS-Certified-Kubernetes-Security-Specialist) (MIT) — guia de estudo de terceiros usado como referência de comandos/flags exatos (kube-bench, Falco, EncryptionConfiguration, ValidatingAdmissionPolicy) ao escrever os exercícios deste repo.
- Kubernetes Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
- Cilium Network Policy: https://docs.cilium.io/en/stable/security/policy/
- Cilium Transparent Encryption: https://docs.cilium.io/en/stable/security/network/encryption/
- CIS Kubernetes Benchmark (kube-bench): https://github.com/aquasecurity/kube-bench
- Falco: https://falco.org/docs/
