# Latest Amazon Linux 2023 AMI. A newer AMI only creates a new launch template
# version; the running instance is not replaced until it is terminated.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "proget" {
  image_id      = nonsensitive(data.aws_ssm_parameter.al2023.value)
  instance_type = "c7a.xlarge"
  key_name      = "proget"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 80
      volume_type = "gp3"
    }
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.proget.id]
  }
  monitoring {
    enabled = true
  }
  user_data = base64encode(templatefile("${path.module}/files/proget_userdata.sh.tftpl", {
    efs_id       = local.efs_id
    efs_ap       = local.efs_ap
    efs_ap_pgsql = local.efs_ap_pgsql
    pg_uid       = local.pg_uid
    pg_gid       = local.pg_gid
    proget_image = "proget.inedo.com/productimages/inedo/proget:${local.proget_version}"
  }))
}

# proget autoscaling group
resource "aws_autoscaling_group" "proget" {
  name             = "proget-${aws_launch_template.proget.name}"
  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  default_cooldown = 120

  vpc_zone_identifier       = [tolist(data.aws_subnets.public_subnet_ids.ids)[0]]
  target_group_arns         = [aws_lb_target_group.proget.arn]
  wait_for_capacity_timeout = "5m"
  launch_template {
    id      = aws_launch_template.proget.id
    version = "$Latest"
  }

  health_check_grace_period = 900 # 15 minutes for first boot installs
  health_check_type         = "ELB"
  protect_from_scale_in     = true
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "proget"
    propagate_at_launch = true
  }
}
