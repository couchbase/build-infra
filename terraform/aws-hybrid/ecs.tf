resource "aws_ecs_cluster" "main" {
  name = "jenkins-ecs"
}

resource "aws_ecs_service" "go_proxy" {
  platform_version = "1.4.0"
  name             = "jenkins-go-proxy"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.go_proxy.arn
  launch_type      = "FARGATE"
  desired_count    = 1

  service_registries {
      registry_arn = aws_service_discovery_service.go_proxy.arn
  }

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.go_proxy.id]
  }
}

resource "aws_ecs_task_definition" "go_proxy" {
  family = "jenkins-go-proxy"

  container_definitions = templatefile("files/tasks/go_proxy.tpl", {
    cloudwatch_log_group  = aws_cloudwatch_log_group.go_proxy.name
    cloudwatch_log_prefix = "go-proxy"
    container_name        = "goproxy"
    container_image       = var.goproxy_image
    region                = var.region
  })

  execution_role_arn = aws_iam_role.ecs.arn
  task_role_arn      = aws_iam_role.go_proxy.arn

  requires_compatibilities = ["FARGATE"]

  cpu    = var.goproxy_cpu
  memory = var.goproxy_memory

  network_mode = "awsvpc"
}
