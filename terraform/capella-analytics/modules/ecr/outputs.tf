output "ecr_info" {
  description = "The ECR registry ID and repository URL."
  value = {
    registry_id    = aws_ecr_repository.aws_ecr_repo.registry_id
    repository_url = aws_ecr_repository.aws_ecr_repo.repository_url
  }
}
