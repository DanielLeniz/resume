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

module "tf-state" {
  source      = "./modules/tf-state"
  bucket_name = "backend-resume"
}

module "vpc-infra" {
  source = "./modules/tf-state/vpc"

  # VPC Input Vars
  vpc_cidr             = local.vpc_cidr
  availability_zones   = local.availability_zones
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
}
provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["C:/Users/Daniel/.aws/config"]
  shared_credentials_files = ["C:/Users/Daniel/.aws/credentials"]
}

resource "aws_instance" "app_server" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"

  tags = {
    Name = "ResumeServerInstance"
  }
}
