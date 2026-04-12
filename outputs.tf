output "public_ips" {
  value = [for i in aws_instance.nodes : i.public_ip]
}

output "private_ips" {
  value = [for i in aws_instance.nodes : i.private_ip]
}

output "nodes" {
  value = {
    for i in aws_instance.nodes :
    i.tags["Name"] => {
      public_ip  = i.public_ip
      private_ip = i.private_ip
    }
  }
}

output "ssh_commands" {
  value = {
    for i in aws_instance.nodes :
    i.tags["Name"] => "ssh -i <path-da-sua-chave.pem> ubuntu@${i.public_ip}"
  }
}
