data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_instance" "bastion" {
  count = var.stopped ? 0 : 1
  ami           = data.aws_ami.amzn2.image_id
  instance_type = var.instance_type
  subnet_id     = var.public_subnets[0]
  key_name      = "${var.prefix}-robot"
  user_data = templatefile("${path.module}/files/userdata/bastion_userinit.tpl", {
    analytics_jenkins_accesspoint = var.analytics_jenkins_access_point.id
    cv_jenkins_accesspoint        = var.cv_jenkins_access_point.id
    server_jenkins_accesspoint    = var.server_jenkins_access_point.id
    mobile_jenkins_accesspoint    = var.mobile_jenkins_access_point.id
    nexus_accesspoint             = var.nexus_access_point.id
    downloads_accesspoint         = var.downloads_access_point.id
    latestbuilds_accesspoint      = var.latestbuilds_access_point.id
    proget_accesspoint            = var.proget_access_point.id
    filesystem                    = var.efs_file_system.id
  })
  iam_instance_profile = aws_iam_instance_profile.bastion.id
  vpc_security_group_ids = [
    aws_security_group.bastion.id,
    var.server_jenkins_security_group.id,
    var.cv_jenkins_security_group.id,
    var.mobile_jenkins_security_group.id
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "true"
  }

  tags = {
    Name = "${var.prefix}-bastion"
  }
}
