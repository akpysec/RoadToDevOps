provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "my-s3-bucket-for-terraform"
    key    = "dev/servers/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-s3-bucket-for-terraform"
    key    = "dev/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "latest_ami_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*.0-x86_64-gp2"]
  }
}

resource "aws_instance" "webserver" {
  ami                    = data.aws_ami.latest_ami_linux_2.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  tags = {
    Name = "Web-Server"
  }
}

resource "aws_security_group" "main" {
  name   = "WebServer Security Group"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Web-Server-SG"
    Owner = "AK"
  }
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "network_details" {
  value = data.terraform_remote_state.network
}

output "webserver_public_ip" {
  value = aws_instance.webserver.public_ip
}
