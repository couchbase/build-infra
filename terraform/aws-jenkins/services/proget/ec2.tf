resource "aws_launch_configuration" "proget" {
  image_id             = var.proget_ami
  instance_type        = var.proget_instance_type
  key_name             = "${var.prefix}-robot"
  iam_instance_profile = aws_iam_instance_profile.proget.id
  security_groups      = [aws_security_group.proget.id]
  lifecycle { create_before_destroy = false }
  user_data = templatefile("${path.module}/files/userdata/proget_userinit.tpl", {
    proget_accesspoint            = aws_efs_access_point.proget.id
    filesystem                    = var.efs_file_system.id
  })
}

# proget autoscaling group
resource "aws_autoscaling_group" "proget" {
  name     = "${var.prefix}-proget-${aws_launch_configuration.proget.name}"
  max_size = var.stopped ? 0 : 1
  min_size = var.stopped ? 0 : 1

  # availability_zones = [data.aws_availability_zones.available.names[1]]
  default_cooldown = 120

  vpc_zone_identifier       = [var.private_subnets[0]]
  wait_for_capacity_timeout = "5m"
  launch_configuration      = aws_launch_configuration.proget.name

  health_check_grace_period = 300
  health_check_type         = "EC2"
  protect_from_scale_in = true
  force_delete          = true

  tag {
    key                 = "Name"
    value               = "${var.prefix}-proget"
    propagate_at_launch = true
  }
}
