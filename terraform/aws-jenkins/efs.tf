resource "aws_efs_file_system" "main" {
  creation_token = "${local.name}-storage"
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  encrypted = true

  tags = {
    Name = "${local.name}-storage"
  }
}

resource "aws_efs_mount_target" "main" {
  count          = 2
  file_system_id = aws_efs_file_system.main.id
  subnet_id      = module.vpc.private_subnets[count.index]
  security_groups = [
    aws_security_group.efs.id
  ]
}
