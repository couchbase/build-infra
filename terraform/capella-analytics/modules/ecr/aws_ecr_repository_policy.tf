# Apply registry policy to ecr
resource "aws_ecr_repository_policy" "aws_ecr_registry_policy" {
  repository = aws_ecr_repository.aws_ecr_repo.name
  policy = jsonencode({
    "Statement": [
      {
        "Sid": "Datacenter Read",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages",
          "ecr:ListTagsForResource"
        ]
        "Condition": {
          "IpAddress": {
            "aws:SourceIp": var.whitelist_ips
          }
        }
      },
      {
        "Sid": "Read Access",
        "Effect": "Allow",
        "Principal": {
          "AWS": var.pull_arns
        },
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages",
          "ecr:ListTagsForResource"
        ]
      },
      {
        "Sid": "Write Access",
        "Effect": "Allow",
        "Principal": {
          "AWS": var.push_arns
        },
        "Action": [
          "ecr:DescribeImageScanFindings",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetRepositoryPolicy",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      },
      {
        "Sid": "EC2 Write Access",
        "Effect": "Allow",
        "Principal": {
          "AWS": var.push_roles
        },
        "Action": [
          "ecr:DescribeImageScanFindings",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetRepositoryPolicy",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}
