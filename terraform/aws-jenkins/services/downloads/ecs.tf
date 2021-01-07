resource "aws_ecs_service" "downloads" {
  platform_version = var.context == "EC2" ? "" : "1.4.0"
  name             = "${var.prefix}-downloads"
  cluster          = var.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.downloads.arn
  launch_type      = var.context
  desired_count    = var.stopped ? 0 : 1

  service_registries {
      registry_arn = aws_service_discovery_service.downloads.arn
  }

  network_configuration {
    subnets          = var.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.downloads.id]
  }
}

resource "aws_ecs_task_definition" "downloads" {
  family = "${var.prefix}-downloads"

  container_definitions = templatefile("${path.module}/files/tasks/downloads.tpl", {
    cloudwatch_log_group  = aws_cloudwatch_log_group.downloads.name
    cloudwatch_log_prefix = "downloads"
    container_name        = var.hostname
    container_image       = var.image
    region                = var.region
  })

  execution_role_arn = var.ecs_execution_role.arn #ecs
  task_role_arn      = aws_iam_role.downloads.arn

  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  network_mode = "awsvpc"

  volume {
    name = "downloads"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system.id
      transit_encryption = "ENABLED"
      root_directory     = "/"
      authorization_config {
        access_point_id = aws_efs_access_point.downloads.id
        iam             = "ENABLED"
      }
    }
  }
}
