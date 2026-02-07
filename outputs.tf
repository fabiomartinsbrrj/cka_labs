output "public_ips" {
  value = [for i in aws_instance.nodes : i.public_ip]
}

output "ssh_commands" {
  value = [
    for i in aws_instance.nodes :
    "ssh -i <path-da-sua-chave.pem> ubuntu@${i.public_ip}"
  ]
}
