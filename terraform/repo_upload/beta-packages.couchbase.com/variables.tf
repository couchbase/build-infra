variable "subdomain" { default = "beta-packages" }
variable "domain" { default = "couchbase.com" }

variable "cloudfront_price_class" { default = "PriceClass_200" }

variable "geo_restriction_blacklist" {
  default = [
    "CD", # Congo
    "CI", # Cote D'Ivoire
    "CU", # Cuba
    "IR", # Iran
    "IQ", # Iraq
    "KP", # DPRK
    "LR", # Liberia
    "MM", # Myanmar
    "SD", # Sudan
    "SY", # Syria
    "ZW", # Zimbabwe
  ]
}

variable "log_buckets" {
    type = map
    default = {
        s3         = "s3-logs.couchbase.com"
        cloudfront = "cblog-prod"
    }
}
