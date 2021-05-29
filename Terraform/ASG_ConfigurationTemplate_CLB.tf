# IN PROGRESS!

provider "aws" {
  region = "us-east-1"
}

# Getting AZ-s with Data Source
data "aws_availability_zones" "available" {}

# Getting AMI Latest Image with Data Source
data "aws_ami" "ami_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  # Filtering by Name to find the Image, using * for dynamic part of Image Name (Date when Image updated)
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*.0-x86_64-gp2"]
  }
}

# Creating Security Group
resource "aws_security_group" "web" {
  name        = "Open ports from a list - Terraform"
  description = "Using for_each function in Terraform"
  # Looping over ports - for creating rules
  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "Dynamic Security Group"
  }
}

# Creating launch configuration for a web server
resource "aws_launch_configuration" "web" {
  name            = "WebServer-Highly-Available-LC"
  # Getting image ID through Data Source
  image_id        = data.aws_ami.ami_linux_2.id
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.web.id]
  # Using external file for User Data
  user_data       = file("user_data.sh")
  
  # Lifecycle policy - as says "Creates new resources and only after destroys the old ones"
  lifecycle {
    create_before_destroy = true
  }
}

# Creating Auto-Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "WebServer-Highly-Available-ASG"
  max_size            = 2
  min_size            = 2
  min_elb_capacity    = 2
  launch_template     = aws_launch_configuration.web.id
  health_check_type   = "ELB"
  vpc_zone_identifier = []
  load_balancers      = []
  
  # Looping over tags
  dynamic "tag" {
    for_each {
      Name  = "Web Server in ASG"
      Owner = "AK"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Lifecycle policy - as says "Creates new resources and only after destroys the old ones"
  lifecycle {
  create_before_destroy = true
  }
}

