resource "aws_ecs_service" "latestbuilds" {
  platform_version = var.context == "EC2" ? "" : "1.4.0"
  name             = "${var.prefix}-latestbuilds"
  cluster          = var.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.latestbuilds.arn
  launch_type      = var.context
  desired_count    = var.stopped ? 0 : 1

  service_registries {
      registry_arn = aws_service_discovery_service.latestbuilds.arn
  }

  network_configuration {
    subnets          = var.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.latestbuilds.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.latestbuilds.arn
    container_name   = var.hostname
    container_port   = 90
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}

resource "aws_ecs_task_definition" "latestbuilds" {
  family = "${var.prefix}-latestbuilds"

  container_definitions = templatefile("${path.module}/files/tasks/latestbuilds.tpl", {
    cloudwatch_log_group  = aws_cloudwatch_log_group.latestbuilds.name
    cloudwatch_log_prefix = "latestbuilds"
    container_name        = var.hostname
    container_image       = var.image
    region                = var.region

    latestbuilds_htpasswd = aws_ssm_parameter.latestbuilds_htpasswd.arn
  })

  execution_role_arn = var.ecs_iam_role.arn
  task_role_arn      = aws_iam_role.latestbuilds.arn

  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  network_mode = "awsvpc"

  volume {
    name = "latestbuilds"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system.id
      transit_encryption = "ENABLED"
      root_directory     = "/"
      authorization_config {
        access_point_id = aws_efs_access_point.latestbuilds.id
        iam             = "ENABLED"
      }
    }
  }
}
