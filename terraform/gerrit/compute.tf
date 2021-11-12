locals {
  _ebs           = aws_ebs_volume.main[*].id
  vol_mount_args = join(" ", [for vol in local.volumes : "-v /mnt/data/${vol}:/var/gerrit/${vol}"])
  vol_list       = join(" ", [for vol in local.volumes : "\"${vol}\""])
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "host" {
  name          = local.project
  image_id      = data.aws_ami.amzn2.id
  instance_type = local.instance_type
  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_type           = "gp3"
      volume_size           = 16
    }
  }

  user_data = base64encode(templatefile("files/host_userdata.sh.tpl", {
    backup_device  = local.backup_device
    data_device    = local.data_device
    scratch_device = local.scratch_device
    volumes        = join(",", local.volumes)
    web_port       = local.web_port
    git_port       = local.git_port
    redirect_port  = local.redirect_port
    backup_bucket  = local.backup_bucket_name
    vol_list       = local.vol_list
    vol_mount_args = local.vol_mount_args
    region         = local.region
    sns_arn        = aws_sns_topic.backups.arn
    volume         = local.volume_id != "" ? local.volume_id : local._ebs[0]
    url            = local.gerrit_url

    data_volume_throughput           = local.data_volume_throughput
    backup_restore_volume_iops       = local.backup_restore_volume_iops
    backup_restore_volume_throughput = local.backup_restore_volume_throughput
  }))

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = module.vpc.public_subnets[0]
    security_groups             = [module.ec2-instance-sg.this_security_group_id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.project
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.gerrit.arn
  }
}

resource "aws_autoscaling_group" "gerrit" {
  name               = local.project
  availability_zones = ["${local.region}${local.az}"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 0
  target_group_arns  = module.alb.target_group_arns

  health_check_grace_period = 300
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.host.id
    version = "$Latest"
  }

  tag {
    key                 = "Owner"
    value               = local.owner
    propagate_at_launch = true
  }
}
