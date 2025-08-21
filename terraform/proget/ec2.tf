resource "aws_launch_template" "proget" {
  image_id      = local.ami_id
  instance_type = "c5a.large"
  key_name      = "proget"
  network_interfaces {
      associate_public_ip_address = true
      security_groups = [aws_security_group.proget.id]
  }
  monitoring {
      enabled   = true
  }
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

  health_check_grace_period = 300
  health_check_type         = "ELB"
  protect_from_scale_in = true
  force_delete          = true

  tag {
    key                 = "Name"
    value               = "proget"
    propagate_at_launch = true
  }
}
