data "aws_caller_identity" "current" {}

variable "datacenter_cidr" {}

locals {
  project = "gerrit"
  region  = "us-east-2"
  az      = "a"

  owner = "build-team"

  alert_email_recipient = "build-team@couchbase.com"

  instance_type = "c5.xlarge"

  backup_device  = "sde"
  data_device    = "sdf"
  scratch_device = "sdg"

  web_port      = "8080"
  redirect_port = "9090"
  git_port      = "29418"
  gerrit_url    = "https://review.couchbase.org/"

  backup_bucket_name = "cb-${local.project}.backups"

  vpc_cidr                  = "10.0.0.0/16"
  aws_instance_connect_cidr = "3.16.146.0/29"

  # If recovering from a snapshot, restore the snapshot to a volume via the
  # console/cli, and set volume_id below to the id of the restored volume.
  #
  # On `terraform apply`, the volume with volume_id will be attached to the
  # instances created by the asg and tagged with a project name so it will
  # continue to be snapshotted on a schedule
  #
  # Note: any instance provisioned by the asg will not be recreated when
  #       modifications are made. After any volume changes you *must* terminate
  #       the running instance for the changes to take effect
  volume_id = ""

  data_volume_size = 120

  # When specifying a volume_id, the initial managed volume is not automatically
  # removed. If you are restoring from a snapshot permanently, remember to set
  # retain_managed_volume to false when it is no longer required to remove the
  # redundant volume.
  retain_managed_volume = true

  # container volumes - these dirs are created in the EBS volume if not present,
  # mounted into the container under /var, and backed up by /usr/bin/gerrit-backup
  volumes = [
    "cache",
    "data",
    "db",
    "etc",
    "git",
    "index",
    "lib",
    "logs",
    "plugins",
    "static"
  ]

  data_volume_throughput           = 200
  backup_restore_volume_iops       = 3000
  backup_restore_volume_throughput = 200
}
