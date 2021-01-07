# What is it

VPC spread across 2 AZs with private and public subnets.

Private zone in route53 for internal name resolution, service discovery via cloud map.

Application load balancer for UI access

EFS for JENKINS_HOME with an access point and mountpoints in both AZs, data encrypted at rest and in transit

EFS for latestbuilds, nexus, proget, downloads are configured similarly

ECS cluster backed by autoscaling group of EC2 instances

Jenkins master service and task.

Profiledata service and task, data populated from SSM

Worker task generator - workers pull profiledata key from SSM and sync data from profiledata container

Latestbuilds container (currently only http)

Go proxy container

Downloads container (downloads.build.couchbase.com, used by mobile for cbdep and jadk, etc.)

Nexus container

Proget: standalone EC2 with its own autoscaling group.

A bastion instance with ssh access locked down to the creator's IP address.

# Manually configured to make jenkins working on AWS

Parameterized Remote Trigger Configurations in http://server.jenkins.couchbase.com/configure is modified so that build-from-manifest-new can trigger remote builds on mobile jenkins
from http://mobile.jenkins.couchbase.com to http://mobile.jenkins.couchbase.com:8080

# Issues

There's some ping-ponging of the security group rule which gives the bastion host ssh access to the private instances - terraform apply seems to switch it on then off then on then off etc. Not sure why, not been annoyed enough by it to prioritize fixing it yet.

Creating packages.couchbase.com endpoint is manual just now, see: https://discuss.hashicorp.com/t/how-to-register-service-instance-to-cloud-map-namespace/11384/3

# Quick Start

Change `name` in `vars.tf` to something unique, it's used as a prefix when naming various resources.

```
export AWS_ACCESS_KEY_ID=[your key]
export AWS_SECRET_ACCESS_KEY=[your secret]

terraform apply
```

You'll be able to access jenkins via the URL in the terraform output once it completes, the container is streaming its logs to a cloudwatch log group so you can get the initial password there (latestbuilds and the agents do the same with their logs)

Once everything is up, use the bastion_instance_ssh output string from the terraform output to connect to the bastion host, after it's been up a couple of minutes it'll create /efs and mount the jenkins_home and latestbuilds volumes there. Edit /efs/jenkins_home/config.xml when available and replace or add the `clouds` terraform output snippet to the clouds section.

With the config added, install the ECS plugin in Jenkins. After Jenkins is restarted, you'll be able to point jobs at the tags associated with the container tasks - you can see them all in files/jenkins/clouds.tpl, e.g `<label>master-amzn2</label>`

# Notes

When adding a new Jenkins instance module block, you'll need to:
- update files/policies/efs_access.tpl to grant access to the EFS volume
- update services_core.tf to ensure you're passing the relevant variables to templatefile("files/policies/efs_access.tpl",{})
- update services/bastion/ec2.tf to pass the EFS access point to templatefile("${path.module}/files/userdata/bastion_userinit.tpl",{})
- update services/bastion/files/userdata/bastion.userinit.tpl to mount the new Jenkins' EFS access point on the bastion host
- add variables to receive new jenkins' iam_policy, access_point and security_group to the bastion module, at services/bastion/variables.tf
- update bastion block in services_core.tf to pass those same variables to the bastion module
