resource "aws_cloudwatch_log_group" "zz_lightweight" {
  name              = "/${var.prefix}/${var.jenkins_name}/zz-lightweight"
  retention_in_days = 7
}

resource "aws_security_group" "zz_lightweight" {
  name        = "${var.prefix}-${var.jenkins_name}-zz-lightweight"
  vpc_id      = var.vpc_id

  ingress {
    description = "App"
    from_port   = 22
    to_port     = 22
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
    Name = "${var.prefix}-${var.jenkins_name}-zz-lightweight"
  }
}

resource "aws_ecs_service" "zz_lightweight" {
  count = (var.jenkins_name == "server" || var.jenkins_name == "cv" || var.jenkins_name == "mobile" ) ? 1 : 0
  # LATEST isn't most recent, need to specify platform_version to mount EFS on Fargate
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
  platform_version = var.context == "EC2" ? "" : "1.4.0"
  name             = "${var.prefix}-${var.jenkins_name}-zz-lightweight"
  cluster          = var.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.zz_lightweight.arn
  launch_type      = var.context
  desired_count    = var.stopped ? 0 : 1

  network_configuration {
    subnets          = var.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.zz_lightweight.id]
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}

resource "aws_ecs_task_definition" "zz_lightweight" {
  family = "${var.prefix}-${var.jenkins_name}-zz-lightweight"

  container_definitions = templatefile("${path.module}/files/tasks/zz_lightweight.tpl", {
    cloudwatch_log_group  = aws_cloudwatch_log_group.zz_lightweight.name
    cloudwatch_log_prefix = "zz-lightweight"
    master_url            = var.master_url
    jenkins_name          = var.jenkins_name
    jenkins_user          = aws_ssm_parameter.jenkins_user.arn
    jenkins_password      = aws_ssm_parameter.jenkins_password.arn
    container_name        = var.hostname
    container_image       = var.image
    region                = var.region
    profiledata_key_arn   = var.profiledata_key.arn
    node_class            = "build"
    node_product          = "couchbase-server"
  })

  execution_role_arn = var.ecs_role.arn
  task_role_arn      = aws_iam_role.zz_lightweight.arn

  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  network_mode = "awsvpc"
}
