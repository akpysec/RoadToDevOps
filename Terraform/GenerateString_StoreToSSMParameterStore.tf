provider "aws" {
  region = "us-east-1"
}

resource "random_string" "random_str" {
  length           = 10
  special          = true
  override_special = "!@#&*"
}

resource "aws_ssm_parameter" "secret" {
  name        = "/production/database/password/master"
  description = "The parameter description"
  type        = "SecureString"
  value       = random_string.random_str.result
}

