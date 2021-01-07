variable "prefix" {}

variable "hostname" {}
variable "subdomain" {}
variable "domain" {}

variable "efs_security_group" {}
variable "dns_namespace" {}
variable "lb_stopped" {}

variable "images" {}

locals {
  fqdn = "${var.hostname}.${var.subdomain}.${var.domain}"
}

variable "private_key" {}

variable "profiledata_key" {}
variable "image" {}
variable "region" {}
variable "vpc_id" {}
variable "ecs_cluster" {}
variable "ecs_task_runner_arn" {}
variable "efs_file_system" {}
variable "ecs_execution_role" {}
variable "ecs_role" {}

variable "ui_port" {
  type    = number
  default = 8080
}

variable "jnlp_port" {
  type    = number
  default = 50000
}

variable "master_cpu" {
  default = 1024
  type    = number
}

variable "master_memory" {
  default = 4096
  type    = number
}

variable "worker_cpu" {
  default = 1024
  type    = number
}

variable "worker_memory" {
  default = 4096
  type    = number
}

variable "context" {
  default = "EC2"
  type    = string
}

variable "stopped" {
  default = false
  type    = bool
}

variable "private_subnets" {
  type = list(string)
}

variable "private_subnets_cidr_blocks" {}

variable "public_subnets" {
  type = list(string)
}

variable "bastion_security_group" {}