# Invoke with `[TEST=true] ARCH=[x86_64|aarch64] packer build master.pkr.hcl`
#
# TEST is optional, but when its value is `true` will ensure the name of the
# output AMI is prefixed by test- - this is purely to help differentiate
# WIP AMIs from in-use AMIs to facilitate cleanup.

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

variable "test" {
  default = env("TEST")
}

variable "region" {
  default = "us-east-2"
}

locals {
  test = var.test == "true" ? "-testing" : ""
  arch = var.arch == "x86_64" ? "x86_64" : "arm64"
  instance_type = var.arch == "x86_64" ? "t2.micro": "t4g.micro"
}

source "amazon-ebs" "amzn2" {
  ami_name      = "jenkins-host-amzn2-${var.arch}-${formatdate("YYYY-MM-DD-HH-mm", timestamp())}${local.test}"
  instance_type = local.instance_type
  region        = var.region
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 16
    volume_type           = "gp3"
    delete_on_termination = true
  }
  source_ami_filter {
    filters = {
      name                = "al2023-ami-minimal-*-${local.arch}"
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

  provisioner "file"{
    source = "files/cv-hook.sh"
    destination = "/tmp/cv-hook.sh"
  }

  provisioner "shell" {
    script = "files/provision.sh"
    environment_vars = [
      "REGION=${var.region}"
    ]
  }
}
