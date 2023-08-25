variable "ecr_image_age" {
  description = <<EOF
    Delete images older than number of days.
    For production ecr, Enter "0" to disable lifecycle policy.
    For dev ecr, it is desired to keep images for "60" days.
  EOF
  type        = number
}
