resource "aws_launch_configuration" "proget" {
  image_id      = local.ami_id
  instance_type = "c5a.large"
  key_name      = "proget"
  security_groups      = [aws_security_group.proget.id]
  lifecycle { create_before_destroy = false }
}

# proget autoscaling group
resource "aws_autoscaling_group" "proget" {
  name     = "proget-${aws_launch_configuration.proget.name}"
  max_size = 1
  min_size = 1

  default_cooldown = 120

  vpc_zone_identifier       = [tolist(data.aws_subnet_ids.public_subnet_ids.ids)[0]]
  target_group_arns         = [aws_lb_target_group.proget.arn]
  wait_for_capacity_timeout = "5m"
  launch_configuration      = aws_launch_configuration.proget.name

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
