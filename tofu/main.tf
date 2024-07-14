provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      Stack = "k8s-the-hard-way"
      Name  = "k8s-the-hard-way"
    }
  }
}

data "external" "myip" {
  program = ["/bin/bash", "${path.module}/myip.sh"]
}

variable "pubkey" {
  type      = string
  sensitive = true
}

resource "aws_key_pair" "k8s" {
  key_name   = "k8s"
  public_key = var.pubkey
}

data "aws_ami" "debian_arm" {
  most_recent = true
  name_regex  = "^debian-12"
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_vpc" "k8s" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "k8s" {
  vpc_id = aws_vpc.k8s.id
}

output "jumphost-pubip" {
  value = aws_instance.jumphost.public_ip
}
