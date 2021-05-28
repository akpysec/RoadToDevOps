# Terraforms for_each function application

provider "aws" {
  region = "us-east-1"
}


resource "aws_security_group" "security_group_from_list" {

  name        = "Open ports from a list - Terraform"
  description = "Using for_each function in Terraform"
  dynamic "ingress" {
    for_each = ["80", "443", "8080", "1541"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "Terraform for_each function"
  }
}
