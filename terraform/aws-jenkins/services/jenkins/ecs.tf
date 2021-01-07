
resource "aws_ecs_task_definition" "jenkins_master" {
  family = "${var.prefix}-${var.hostname}-master"

  container_definitions = templatefile("${path.module}/files/tasks/jenkins_master.tpl", {
    jenkins_ui_port       = var.ui_port
    jenkins_jnlp_port     = var.jnlp_port
    cloudwatch_log_group  = aws_cloudwatch_log_group.jenkins_master.name
    cloudwatch_log_prefix = var.prefix
    container_name        = var.hostname
    container_image       = var.image
    region                = var.region
  })

  execution_role_arn = var.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.jenkins_master.arn

  requires_compatibilities = ["FARGATE"]

  cpu    = var.master_cpu
  memory = var.master_memory

  network_mode = "awsvpc"

  volume {
    name = "jenkins_home"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system.id
      transit_encryption = "ENABLED"
      root_directory     = "/"
      authorization_config {
        access_point_id = aws_efs_access_point.jenkins_home.id
        iam             = "ENABLED"
      }
    }
  }
}

# We need a delay between creating the LB listener and creating the service or terraform will error out
# and need to be applied twice.
resource "time_sleep" "wait_10_seconds" {
  depends_on      = [aws_lb_listener_rule.jenkins_master]
  create_duration = "10s"
}

resource "aws_ecs_service" "jenkins_master" {
  depends_on = [time_sleep.wait_10_seconds]
  # LATEST isn't most recent, need to specify platform_version to mount EFS on Fargate
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
  platform_version = var.context == "EC2" ? "" : "1.4.0"
  name             = "${var.prefix}-${var.hostname}-master"
  cluster          = var.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.jenkins_master.arn
  launch_type      = var.context
  desired_count    = var.stopped ? 0 : 1

  service_registries {
    registry_arn = aws_service_discovery_service.jenkins_master.arn
  }

  network_configuration {
    subnets          = var.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.jenkins_master.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.jenkins_master.arn
    container_name   = var.hostname
    container_port   = var.ui_port
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}
