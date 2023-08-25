variable "aws_region" {
  description = "AWS region where the repository is provisioned."
  type        = string
}
variable "ecr_repo_name" {
  description = "The ecr repository name."
  type        = string
}
variable "ecr_image_scan" {
  description = "Defines if the image should be scanned for vulnerabilities on push."
  type        = bool
}
variable "ecr_image_age" {
  description = "Delete images older than number of days."
  type        = number
}
variable "whitelist_ips" {
  description = "IP addresses to allow access to ecr"
  type        = list
}
variable "pull_arns" {
  description = "Arns allow to pull images from the registry"
  type        = list
}
variable "push_arns" {
  description = "Arns allow to push images to the registry"
  type        = list
}
variable "push_roles" {
  description = "Roles  allow to pull images from the registry"
  type        = list
}
