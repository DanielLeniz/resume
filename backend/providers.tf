terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.66.1"
    }
  }
  backend "s3" {
    bucket         = "backend-resume"
    key            = "tf-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.10.1"
}
provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["C:/Users/Daniel/.aws/config"]
  shared_credentials_files = ["C:/Users/Daniel/.aws/credentials"]
}
