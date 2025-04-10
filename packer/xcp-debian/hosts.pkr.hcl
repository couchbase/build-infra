# Update this to add additional XCP hosts as necessary. Note that the
# "default_sr" here is where the template will be stored, and so should
# usually be "Local storage" rather than one of the VMStore SRs.

locals {
    xcp_info = {
        "xcp-s335" = {
            "hostname"   = "172.23.112.22"
            "username"   = "root"
            "default_sr" = "Local storage"
            "network"    = "Pool-wide network associated with eth2"
        }
        "xcp-s834" = {
            "hostname"   = "172.23.96.155"
            "username"   = "root"
            "default_sr" = "VMStore"
            "network"    = "Pool-wide network associated with eth4"
            base_template_name = "Debian Jessie 8.0"
        }
        "xcp-se10" = {
            "hostname"   = "172.23.112.10"
            "username"   = "root"
            "default_sr" = "Local storage"
            "network"    = "Pool-wide network associated with eth2"
        }
        "xcp-se27" = {
            "hostname"   = "172.23.110.75"
            "username"   = "root"
            "default_sr" = "Local storage"
            "network"    = "Pool-wide network associated with eth2"
        }
        "xcp-se29" = {
            "hostname"   = "172.23.112.26"
            "username"   = "root"
            "default_sr" = "Local storage"
            "network"    = "Pool-wide network associated with eth2"
        }
        "xcp-sf25" = {
            "hostname"   = "172.23.124.111"
            "username"   = "root"
            "default_sr" = "Local storage"
            "network"    = "Pool-wide network associated with eth2"
        }
        "xcp-sf36" = {
            "hostname"   = "172.23.124.101"
            "username"   = "root"
            "default_sr" = "Local storage"
            "network"    = "Pool-wide network associated with eth2"
        }
    }
}
