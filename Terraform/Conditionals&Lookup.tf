provider "aws" {
  region = "us-east-1"
}


variable "env" {
    default = "prod"
}


variable "ec2_sizes" {
    default = {
        "prod" = "t2.large"
        "dev"  = "t2.medium"
    }
}

resource "aws_instance" "webserver" {
    ami = "ami-0d5eff06f840b45e9"
    instance_type = var.env == "prod" ? lookup(var.ec2_sizes, var.env) : var.ec2_sizes["dev"]
    tags = {
        Name = "${var.env}-app"
        Environment = var.env
    }
}

