# Find ECS Optimized amzn2 AMI
data "aws_ami" "aws_optimized_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# We use a placement group to try to keep container instances together
resource "aws_placement_group" "main" {
  name     = local.name
  strategy = "cluster"
}

# When initialising the cluster instances, these scripts will provision local disks putting
# /var/lib/docker on the instance volumes, and will prevent containers from accessing the 
# instance metadata on http://169.254.169.254
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-boothook"
    content      = templatefile("files/userdata/docker_host_preboot.tpl", { ecs_cluster = local.name })
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("files/userdata/docker_host_postboot.sh")
  }
}

# The launch configuration dictates what the instances our ASG brings up will look like
resource "aws_launch_configuration" "master" {
  depends_on    = [tls_private_key.main]
  image_id      = data.aws_ami.aws_optimized_ecs.id
  instance_type = local.ec2_instance_type
  key_name             = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_ecs.id
  security_groups      = [aws_security_group.ecs_instances.id]
  lifecycle { create_before_destroy = false }

  user_data_base64 = data.template_cloudinit_config.config.rendered
}

# Our ECS managed autoscaling group
resource "aws_autoscaling_group" "master" {
  name     = "${local.name}-${aws_launch_configuration.master.name}"
  max_size = local.stopped ? 0 : local.ec2_max_instances
  min_size = local.stopped ? 0 : 1

  default_cooldown = 120

  vpc_zone_identifier       = [module.vpc.private_subnets[0]]
  wait_for_capacity_timeout = "5m"
  launch_configuration      = aws_launch_configuration.master.name

  health_check_grace_period = 300
  health_check_type         = "ELB"
  placement_group       = aws_placement_group.main.id
  protect_from_scale_in = true
  force_delete          = true

  tag {
    key                 = "AmazonECSManaged"
    propagate_at_launch = true
    value               = ""
  }
}
