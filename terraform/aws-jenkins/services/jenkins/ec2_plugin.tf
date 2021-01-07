# Post deployment, it's necessary to generate an access key for this user manually
# and use to configure the jenkins plugin
resource "aws_iam_user" "ec2_plugin" {
  name = "${var.prefix}-${var.hostname}-ec2_plugin"
  path = "/system/"
}

resource "aws_iam_user_policy_attachment" "ec2_plugin" {
  user       = aws_iam_user.ec2_plugin.name
  policy_arn = aws_iam_policy.ec2_plugin.arn
}

resource "aws_iam_role" "ec2_plugin" {
  name               = "${var.prefix}-${var.hostname}-ec2_plugin"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_policy" "ec2_plugin" {
  name   = "_${var.prefix}-${var.hostname}-ec2-plugin"
  policy = file("${path.module}/files/policies/ec2_plugin.tpl")
}

resource "aws_iam_role_policy_attachment" "ec2_plugin" {
  role       = aws_iam_role.ec2_plugin.name
  policy_arn = aws_iam_policy.ec2_plugin.arn
}

resource "aws_iam_role_policy_attachment" "ec2_plugin_ssm" {
  role = aws_iam_role.ec2_plugin.name
  policy_arn = aws_iam_policy.worker_ssm.arn
}

resource "aws_iam_instance_profile" "ec2_plugin_worker" {
  name = "${var.prefix}-${var.hostname}-ec2-plugin-worker"
  role = aws_iam_role.ec2_plugin.name
}


resource "aws_security_group" "ec2_worker" {
  name        = "${var.prefix}-${var.hostname}-ec2-worker"
  description = "EC2 worker"
  vpc_id      = var.vpc_id

  ingress {
    description     = "RDP"
    from_port       = 3389
    to_port         = 3389
    protocol        = "TCP"
    security_groups = [var.bastion_security_group.id]
  }
  ingress {
    description     = "WinRM"
    from_port       = 5985
    to_port         = 5985
    protocol        = "TCP"
    security_groups = [aws_security_group.jenkins_master.id]
  }
  ingress {
    description     = "CIFS to receive slave.jar"
    from_port       = 445
    to_port         = 445
    protocol        = "TCP"
    security_groups = [aws_security_group.jenkins_master.id]
  }
  ingress {
    description     = "SSH for agent initialisation"
    from_port       = 22
    to_port         = 22
    protocol        = "TCP"
    security_groups = [aws_security_group.jenkins_master.id]
  }
  egress {
    description = "external"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-${var.hostname}-ec2-worker"
  }
}
