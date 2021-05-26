provider "aws" {
  region     = "us-east-1"
  access_key = "ACCESS_KEY"
  secret_key = "SECRET_KEY"
}

# VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Terraform_VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "Terraform_IGW"
  }
}

# Route table
resource "aws_route_table" "terraform_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = "Terraform_Route_Table"
  }
}

# Subnet
resource "aws_subnet" "terraform_subnet" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Terraform_Subnet"
  }
}

# Route table association with a subnet
resource "aws_route_table_association" "terraform_route_table_association" {
  subnet_id      = aws_subnet.terraform_subnet.id
  route_table_id = aws_route_table.terraform_route_table.id
}

# Security Group
resource "aws_security_group" "allow_http_https_ssh" {
  name        = "Allow_Web_SSH_Traffic"
  description = "Allow Web & SSH inbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "Terraform - Allow HTTP/HTTPS/SSH"
  }
}

# Network interface
resource "aws_network_interface" "terraform_network_interface" {
  subnet_id       = aws_subnet.terraform_subnet.id
  private_ips     = ["10.0.1.101"]
  security_groups = [aws_security_group.allow_http_https_ssh.id]
  tags = {
    Name = "Terraform_Primary_Network_Interface"
  }
}

# Elastic IP
resource "aws_eip" "terraform_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.terraform_network_interface.id
  associate_with_private_ip = "10.0.1.101"
  depends_on                = [aws_internet_gateway.terraform_igw]
  tags = {
    Name = "Terraform_EIP"
  }
}

# EC2 Instance
resource "aws_instance" "terraform_ec2_instance" {
  ami           = "ami-0d5eff06f840b45e9"
  instance_type = "t2.micro"
  key_name      = "new_pair"

  network_interface {
    network_interface_id = aws_network_interface.terraform_network_interface.id
    device_index         = 0
    }
    tags = {
      Name = "Terraform_EC2"
    }
}

# Getting Public IP after creation
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.terraform_ec2_instance.public_ip
}
