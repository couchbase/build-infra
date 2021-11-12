# Gerrit

## Overview

This config describes an EC2 autoscaling group with dockerized instance and a containerised workload inside its own VPC, using an EBS volume for data, DLM for hourly snapshots (1 week retention) and weekly backups to s3.

The instance has an attached security group which allows unrestricted egress and unrestricted ingress on ssh and gerrit web and ssh ports. An instance policy is connected to the hosts which grants them access to read and write to/from backup bucket, attach/detach/poll EBS volume, pull secrets from ssm, and publish SNS messages.

At launch, the host:
 - installs docker and iptables-services
 - configures iptables to drop metadata access for containers
 - creates a mountpoint and fstab entry for mounting the ebs volume
 - initialises the ebs volume if required, mounts it and creates the directories the volumes will live in (setting the owner/group in the process, rather than letting docker create them with root:root as the owner)
 - creates backup/restore helper scripts
 - schedules a nightly backup
 - starts the container

## Helper Scripts

A number of helper scripts are created when the instance is provisioned, these are:

- `gerrit-start`: Ensures volume mount dirs exist and are owned by the correct user, and starts the container
- `gerrit-get-secrets`: Retrieves secrets from parameter store
- `gerrit-list-backups`: Reads a list of backup filenames present in the backup bucket
- `gerrit-attach-data-volume`: Detaches EBS volume from any host it is connected to (e.g. an instance on the way out) and attaches to the current instance.
- `gerrit-backup`: Backs up gerrit data
- `gerrit-restore`: Restores gerrit data from a given key in the backup bucket
