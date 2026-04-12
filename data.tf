data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

data "aws_ssm_parameter" "ubuntu_2204_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

locals {
  my_ip = trimspace(data.http.my_ip.response_body)
}
