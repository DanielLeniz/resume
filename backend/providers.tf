terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.9.0"
    }
  }
}

provider "aws" {
  profile                  = "dleniz"
  region                   = "us-east-1"
  shared_config_files      = ["/Users/mackenziegittinger/.aws/config"]
  shared_credentials_files = ["/Users/mackenziegittinger/.aws/credentials"]
}
