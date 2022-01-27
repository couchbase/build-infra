variable "region" { default = "us-east-2" }

variable "aws_instance_connect_cidr" { default = "3.16.146.0/29" }

variable "datacenter_cidr" {}

variable "service_discovery_domain" { default = "build.couchbase.com" }

variable "environments" {
    default = [
        "analytics",
        "cv",
        "server",
        "test"
    ]
}

variable "goproxy_image" { default = "gomods/athens:v0.10.0" }
variable "goproxy_memory" { default = 4096 }
variable "goproxy_cpu" { default = 1024}

variable "maven-cache_image" { default = "sonatype/nexus3:3.37.3" }
variable "maven-cache_memory" { default = 4096 }
variable "maven-cache_cpu" { default = 1024}
