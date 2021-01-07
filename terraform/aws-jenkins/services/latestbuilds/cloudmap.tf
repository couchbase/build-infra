resource "aws_service_discovery_service" "latestbuilds" {
  name        = "${var.hostname}.${var.subdomain}"
  description = "${var.hostname}.${var.subdomain}.${var.domain}"

  dns_config {
    namespace_id = var.dns_namespace.id

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

resource "aws_service_discovery_service" "cnt_s231" {
  name        = "cnt-s231.sc"
  description = "latestbuilds - alt name"

  dns_config {
    namespace_id = var.dns_namespace.id

    dns_records {
      ttl  = 10
      type = "CNAME"
    }

    routing_policy = "WEIGHTED"
  }
}
