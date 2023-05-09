terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.66.1"
    }
  }


  backend "s3" {
    profile        = "main"
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
provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["C:/Users/Daniel/.aws/config"]
  shared_credentials_files = ["C:/Users/Daniel/.aws/credentials"]
  profile                  = "main"
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
}

resource "docker_image" "nginx" {
  name         = "nginx"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "resume"

  ports {
    internal = 80
    external = 8000
  }
}
resource "aws_instance" "app_server" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"

  tags = {
    Name = "ResumeServerInstance"
  }
}
