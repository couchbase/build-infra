output "efs_access_point" {
    value = aws_efs_access_point.latestbuilds
}

output "iam_role" {
    value = aws_iam_role.latestbuilds
}
