output "efs_access_point" {
    value = aws_efs_access_point.downloads
}

output "iam_role" {
    value = aws_iam_role.downloads
}
