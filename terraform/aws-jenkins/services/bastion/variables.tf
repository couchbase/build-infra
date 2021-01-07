variable "prefix" {}
variable "vpc_id" {}
variable "stopped" {}
variable "instance_type" {}
variable "public_subnets" {}
variable "ssh_key_path" {}
variable "efs_security_group" {}
variable "efs_file_system" {}

variable "latestbuilds_access_point" {}
variable "proget_access_point" {}
variable "nexus_access_point" {}
variable "downloads_access_point" {}

variable "analytics_jenkins_iam_policy" {}
variable "analytics_jenkins_access_point" {}
variable "analytics_jenkins_security_group" {}

variable "cv_jenkins_iam_policy" {}
variable "cv_jenkins_access_point" {}
variable "cv_jenkins_security_group" {}

variable "server_jenkins_iam_policy" {}
variable "server_jenkins_access_point" {}
variable "server_jenkins_security_group" {}

variable "mobile_jenkins_iam_policy" {}
variable "mobile_jenkins_access_point" {}
variable "mobile_jenkins_security_group" {}
