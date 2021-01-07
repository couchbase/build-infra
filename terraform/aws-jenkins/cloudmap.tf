resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = local.private_domain
  description = local.name
  vpc         = module.vpc.vpc_id
}

# packages.couchbase.com still needs to resolve to the public cname
# NOTE: After deployment, you need to create an instance against this 
# service in Cloud Map and point it at: d1f8tw98curgp1.cloudfront.net
resource "aws_service_discovery_service" "packages" {
  name        = "packages"
  description = "packages.${local.private_domain}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "CNAME"
    }

    routing_policy = "WEIGHTED"
  }
}
