resource "aws_efs_access_point" "nexus" {
  file_system_id = var.efs_file_system.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/nexus/sonatype-work/nexus"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 755
    }
  }
}
