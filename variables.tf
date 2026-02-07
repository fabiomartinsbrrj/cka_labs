variable "aws_region" {
  type        = string
  description = "Região AWS"
  default     = "sa-east-1"
}

variable "name_prefix" {
  type        = string
  description = "Prefixo de nome"
  default     = "cka-lab"
}

variable "instance_type" {
  type        = string
  description = "Tipo da instância"
  default     = "t3.medium"
}

variable "key_name" {
  type        = string
  description = "Nome do Key Pair existente na AWS (para SSH)"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR permitido para SSH (recomendado: seu IP/32)"
  default     = null # Será usado local.my_ip se não especificado
}

variable "instances" {
  type        = number
  description = "Quantidade de instâncias EC2"
  default     = 2
}
