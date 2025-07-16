variable "aws_region" {
  description = "AWS region for restore testing resources"
  type        = string
  default     = "us-east-2"
}

variable "backup_buckets" {
  description = "Map of service types to their backup S3 bucket names"
  type = map(string)
  # No default - will prompt at command line for security
}

variable "aws_account_id" {
  description = "AWS Account ID (leave empty to auto-detect)"
  type        = string
  default     = ""
}
