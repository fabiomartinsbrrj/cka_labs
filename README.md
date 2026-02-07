# CKA Study Lab - Infraestrutura AWS com Terraform

Este projeto cria uma infraestrutura na AWS para estudos do Certified Kubernetes Administrator (CKA) usando Terraform.

## 📋 Pré-requisitos

- AWS CLI configurado com credenciais válidas
- Terraform instalado (versão >= 1.0)
- Acesso à região `sa-east-1` na AWS

## 🚀 Como usar

### 1. Criar o Key Pair na AWS

Primeiro, você precisa criar um key pair na AWS para acessar as instâncias EC2:

```bash
# Criar o key pair na região sa-east-1
aws ec2 create-key-pair --key-name cka-key --region sa-east-1 --query 'KeyMaterial' --output text > ~/workspace/cka-key.pem

# Definir permissões corretas para a chave privada
chmod 400 ~/workspace/cka-key.pem
```

### 2. Verificar se o Key Pair foi criado

```bash
# Listar key pairs na região
aws ec2 describe-key-pairs --region sa-east-1
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

- Verifique se o key pair foi criado na região correta (`sa-east-1`)
- Use o comando de verificação mencionado no passo 2

### Erro: "Incorrect attribute value type"

- Certifique-se de que está usando a versão mais recente dos arquivos Terraform
- O `cidr_block` deve ser uma string, não uma lista

### Erro de permissão na chave SSH

```bash
chmod 400 ~/workspace/cka-key.pem
```
