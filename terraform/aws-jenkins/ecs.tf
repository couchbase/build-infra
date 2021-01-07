resource "aws_ecs_cluster" "main" {
  name               = local.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }
}

resource "aws_ecs_capacity_provider" "main" {
  name = aws_autoscaling_group.master.name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.master.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
