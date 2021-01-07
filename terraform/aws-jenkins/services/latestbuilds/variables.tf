variable "prefix" {}
variable "vpc_id" {}
variable "private_subnets_cidr_blocks" {}
variable "private_subnets" {}
variable "efs_file_system" {}
variable "ecs_execution_role" {}
variable "ecs_cluster" {}
variable "hostname" {}
variable "subdomain" {}
variable "domain" {}
variable "image" {}
variable "region" {}
variable "memory" {}
variable "cpu" {}
variable "dns_namespace" {}
variable "context" {}
variable "stopped" {}
variable "efs_security_group" {}
variable "bastion_security_group" {}

variable "ui_port" {
  type    = number
  default = 80
}
variable "lb_stopped" {}

variable "public_subnets" {
    type = list(string)
}
variable "ecs_iam_role" {}
