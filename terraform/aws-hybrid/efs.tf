resource "aws_efs_file_system" "main" {
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  encrypted = true

  tags = {
    Name = "service-storage"
  }
}

resource "aws_efs_mount_target" "mount" {
  for_each       = toset(module.vpc.private_subnets)
  file_system_id = aws_efs_file_system.main.id
  subnet_id      = each.key
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "maven-cache" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    uid = 200
    gid = 200
  }

  root_directory {
    path = "/maven"
    creation_info {
      owner_uid   = 200
      owner_gid   = 200
      permissions = 755
    }
  }
}

resource "aws_efs_file_system_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  policy = templatefile("./files/policies/efs_filesystem_policy.tpl", {
    access_point_arn = aws_efs_access_point.maven-cache.arn
    filesystem_arn = aws_efs_file_system.main.arn
    maven_cache_principal = aws_iam_role.maven-cache.arn
  })
}
