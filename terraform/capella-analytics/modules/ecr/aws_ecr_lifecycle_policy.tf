#setup image expiration in ecr
resource "aws_ecr_lifecycle_policy" "aws_ecr_lifecycle" {
  count = var.ecr_image_age > 0 ? 1 : 0
  repository = aws_ecr_repository.aws_ecr_repo.name
  policy = jsonencode({
    "rules" : [
      {
        "description" : "Delete images older than ${var.ecr_image_age} days.",
        "rulePriority" : 1,
        "selection" : {
          "tagStatus" : "any",
          "countType" : "sinceImagePushed",
          "countUnit" : "days",
          "countNumber" : var.ecr_image_age
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}
