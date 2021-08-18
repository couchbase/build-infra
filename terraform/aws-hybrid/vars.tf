variable "region" { default = "us-east-2" }

variable "aws_instance_connect_cidr" { default = "3.16.146.0/29" }

variable "datacenter_cidr" {}

variable "service_discovery_domain" { default = "build.couchbase.com" }

variable "goproxy_image" { default = "gomods/athens:v0.10.0" }
variable "goproxy_memory" { default = 4096 }
variable "goproxy_cpu" { default = 1024}
