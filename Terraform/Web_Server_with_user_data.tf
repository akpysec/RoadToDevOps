provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web_server" {
  ami                    = "ami-0d5eff06f840b45e9"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_server_security_group.id]
  user_data              = file("user_data.sh")

  tags = {
    Name = "Terraform Web Server"
  }
}

resource "aws_security_group" "web_server_security_group" {

  name        = "Allow_Web_Traffic"
  description = "Allow Web inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web Server - Allow HTTP"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}
