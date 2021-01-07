resource "aws_service_discovery_service" "jenkins_master" {
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
