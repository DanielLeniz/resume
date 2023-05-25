terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.10.1"
}
provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["/Users/mackenziegittinger/.aws/config"]
  shared_credentials_files = ["/Users/mackenziegittinger/.aws/credentials"]
}
