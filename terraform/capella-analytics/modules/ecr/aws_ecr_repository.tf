# Resource to create ecr repo
# "IMMUTABLE":
#   prevents tags from overwritten
# scan_on_push:
#   scan via open-source Clair project
resource "aws_ecr_repository" "aws_ecr_repo" {
  name                 = "${var.ecr_repo_name}"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = var.ecr_image_scan
  }
}
