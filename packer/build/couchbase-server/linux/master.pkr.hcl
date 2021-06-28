# Invoke with `ARCH=[x86_64/amd64] packer build master.pkr.hcl`

packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "arch" {
  default = env("ARCH")
}

variable "region" {
  default = "us-east-2"
}

locals {
  arch = var.arch == "x86_64" ? "x86_64" : "arm64"
  instance_type = var.arch == "x86_64" ? "t2.micro": "t4g.micro"
}

source "amazon-ebs" "amzn2" {
  ami_name      = "jenkins-host-amzn2-${var.arch}-${formatdate("YYYY-MM-DD-HH-mm", timestamp())}"
  instance_type = local.instance_type
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-minimal-hvm-*-${local.arch}-ebs"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [
      "amazon"
    ]
  }
  ssh_username = "ec2-user"
}

build {
  sources = [
    "source.amazon-ebs.amzn2"
  ]

  provisioner "file"{
    source = "files/bootstrap"
    destination = "/tmp/bootstrap"
  }

  provisioner "shell" {
    script = "files/provision.sh"
    environment_vars = [
      "REGION=${var.region}"
    ]
  }
}
