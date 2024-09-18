terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.65.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "m7i.2xlarge"
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 80
  }
  key_name = "CI"
  security_groups = [ "unsafe" ]

  tags = {
    Name = "PGVectoRSBenchByCI"
  }
}