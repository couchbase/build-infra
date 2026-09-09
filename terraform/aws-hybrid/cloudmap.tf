resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = var.service_discovery_domain
  description = "Jenkins worker services"
  vpc         = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "go_proxy" {
  name        = "goproxy"
  description = "goproxy"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "maven-cache" {
  name        = "maven-cache"
  description = "maven-cache"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
