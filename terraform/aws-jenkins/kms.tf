resource "aws_kms_key" "main" {
  description             = local.name
  deletion_window_in_days = 10
  tags = {
    Name = local.name
  }
}
