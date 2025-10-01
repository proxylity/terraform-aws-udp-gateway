terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration is intentionally omitted
# Users should configure the AWS provider in their root module
#
# Example provider configuration:
# provider "aws" {
#   region = "us-east-1"
#   # Additional configuration as needed
# }