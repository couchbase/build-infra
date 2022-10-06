# Follow the steps below to generate ami
# 2. Update .env.example with appropriate values and save it as .env
# 3. source .env
# 4. AWS_PROFILE=<AMI Profile Name> packer build proget.pkr.hcl

variable "region" {
  type = string
}
variable "ami_name" {
  type = string
}
variable "efs_id" {
  type = string
}
variable "efs_ap" {
  type = string
}

locals {
  ami_arch = "x86_64"
  instance_type = "t2.medium"
}

source "amazon-ebs" "cc" {
  ami_name      = "${var.ami_name}"
  instance_type = "${local.instance_type}"
  region        = "${var.region}"
  vpc_id        = "vpc-f2b42197"
  subnet_id     = "subnet-30bb0f47"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  tags = {
    creator     = "build-team"
    name        = "${var.ami_name}"
  }
  snapshot_tags = {
    creator     = "build-team"
    name        = "${var.ami_name}"
  }
  ssh_username = "ec2-user"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.cc"]

  provisioner "shell" {
    script = "files/provision.sh"
    environment_vars = [
      "EFS_ID=${var.efs_id}",
      "EFS_AP=${var.efs_ap}"
    ]
  }
}
