data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "maven_cache_ecs_assume" {
  name               = "${var.prefix}-maven-cache-ecs-assume"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "maven_cache_ecs_assume" {
  role       = aws_iam_role.maven_cache_ecs_assume.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "maven_cache_ssm" {
  role       = aws_iam_role.maven_cache_ecs_assume.name
  policy_arn = aws_iam_policy.maven_cache_ssm.arn
}

resource "aws_iam_policy" "maven_cache_ssm" {
  name = "_${var.prefix}-maven-cache-ssm"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        "Resource": [
          "${aws_ssm_parameter.archiva_password.arn}"
        ]
      }
    ]
}
EOF
}

resource "aws_cloudwatch_log_group" "maven_cache" {
  name              = "/${var.prefix}/maven-cache"
  retention_in_days = 7
}

resource "aws_service_discovery_service" "maven_cache" {
  name        = "${var.hostname}.${var.subdomain}"
  description = "${var.hostname}.${var.subdomain}.${var.domain}"

  dns_config {
    namespace_id = var.dns_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_security_group" "maven_cache" {
  name        = "${var.prefix}-maven-cache"
  vpc_id      = var.vpc_id

  ingress {
    description = "App"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = var.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-maven-cache"
  }
}

resource "aws_ecs_service" "maven_cache" {
  # LATEST isn't most recent, need to specify platform_version to mount EFS on Fargate
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
  platform_version = var.context == "EC2" ? "" : "1.4.0"
  name             = "${var.prefix}-maven-cache"
  cluster          = var.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.maven_cache.arn
  launch_type      = var.context
  desired_count    = var.stopped ? 0 : 1

  service_registries {
    registry_arn = aws_service_discovery_service.maven_cache.arn
  }

  network_configuration {
    subnets          = var.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.maven_cache.id]
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}

resource "aws_ecs_task_definition" "maven_cache" {
  family = "${var.prefix}-maven-cache"

  container_definitions = templatefile("${path.module}/files/tasks/maven_cache.tpl", {
    cloudwatch_log_group  = aws_cloudwatch_log_group.maven_cache.name
    cloudwatch_log_prefix = "maven-cache"
    archiva_password      = aws_ssm_parameter.archiva_password.arn
    container_name        = var.hostname
    container_image       = var.image
    region                = var.region
  })

  execution_role_arn = aws_iam_role.maven_cache_ecs_assume.arn

  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  network_mode = "awsvpc"
}
