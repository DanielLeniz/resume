terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.9.0"
    }
  }
}

provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["C:\Users\Daniel\.aws\config"]
  shared_credentials_files = ["C:\Users\Daniel\.aws\credentials"]
}
