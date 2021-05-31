provider "aws" {
  region = "us-east-1"
}

# Getting AZ-s with Data Source
data "aws_availability_zones" "available" {}

# Getting AMI Latest Image with Data Source
data "aws_ami" "ami_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*.0-x86_64-gp2"]
  }
}

# Getting default subnets names and using their names in Auto-Scaling Group configuration
resource "aws_default_subnet" "default_az_1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}
resource "aws_default_subnet" "default_az_2" {
  availability_zone = data.aws_availability_zones.available.names[1]
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Dynamic Security Group"
  }
}

# Creating launch configuration for a web server
resource "aws_launch_configuration" "web" {
  # Use Name prefix to avoid failure launches due to existing name
  name_prefix = "WebServer-Highly-Available-LC"
  # Getting image ID through Data Source
  image_id        = data.aws_ami.ami_linux_2.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web.id]
  # Using external file for User Data
  user_data = file("user_data.sh")

  # Lifecycle policy - as says "Creates new resources and only after destroys the old ones"
  lifecycle {
    create_before_destroy = true
  }
}

# Creating Auto-Scaling Group
resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  max_size             = 2
  min_size             = 2
  min_elb_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az_1.id, aws_default_subnet.default_az_2.id]
  load_balancers       = [aws_elb.web.name]

  # Looping over tags
  dynamic "tag" {
    for_each = {
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

# Creating ELB in 2 AZ's
resource "aws_elb" "web" {
  name               = "WebServer-HA-ELB"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.web.id]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "WebServer-Highly-Available-ELB"
  }
}

output "web_load_balancer_url" {
  value = aws_elb.web.dns_name
}
