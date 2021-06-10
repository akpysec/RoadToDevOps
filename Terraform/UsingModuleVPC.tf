provider "aws" {
  region = "us-east-1"
}


# Where to store the tfstate
terraform {
  backend "s3" {
    bucket = "my-s3-bucket-for-terraform"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpc-dev" {
  source               = "git@github.com:akpysec/TerrformModules.git//networking"
  environment          = "DEVELOPMENT"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = []
  private_subnet_cidrs = ["10.0.123.0/24", "10.0.213.0/24"]
}

module "vpc-prod" {
  source               = "git@github.com:akpysec/TerrformModules.git//networking"
  environment          = "PRODUCTION"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.20.0/24", "10.0.30.0/24"]
  private_subnet_cidrs = ["10.0.123.0/24", "10.0.213.0/24"]
}
