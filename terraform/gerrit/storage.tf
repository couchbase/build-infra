resource "aws_ebs_volume" "main" {
  count             = local.retain_managed_volume ? 1 : 0
  availability_zone = "${local.region}${local.az}"
  size              = local.data_volume_size
  type              = "gp3"
  throughput        = local.data_volume_throughput
  tags = {
    Name    = "${local.project}-data"
    Project = local.project
  }
}

resource "aws_ec2_tag" "project" {
  # If we're restoring from a snapshot, we need to make sure
  # the restored volume has the project tag so it's backed up
  # by our data lifecycle policy (dlm.tf)
  count       = local.volume_id != "" ? 1 : 0
  resource_id = local.volume_id
  key         = "Project"
  value       = local.project
}

resource "aws_ec2_tag" "name" {
  count       = local.volume_id != "" ? 1 : 0
  resource_id = local.volume_id
  key         = "Name"
  value       = "${local.project}-data"
}
