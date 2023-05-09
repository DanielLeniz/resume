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
    cloud {
      organization = "dleniz"
    }

    backend "s3" {
      profile = "main"
      bucket = "danielleniz.com"
      key    = "terraform.tfstate"
      region = "us-east-1"
    }
  }

provider "aws" {
  region = "us-east-1"
  shared_config_files = ["C:/Users/Daniel/.aws/config"]
  shared_credentials_files = ["C:/Users/Daniel/.aws/credentials"]
  profile = "main"
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
