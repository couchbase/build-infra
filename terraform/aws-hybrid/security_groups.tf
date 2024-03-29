resource "aws_security_group" "allow_ssh" {
  name        = "jenkins_ec2_allow_ssh"
  description = "Allows SSH access on 22 and 4000"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Host access via instance connect "
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_instance_connect_cidr]
  }

  ingress {
    description = "Container access direct from datacenter"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.datacenter_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name     = "jenkins_ec2_allow_ssh"
    Owner    = "build-team"
    Consumer = "jenkins-worker"
  }
}

resource "aws_security_group" "go_proxy" {
  name   = "jenkins-go-proxy"
  vpc_id = module.vpc.vpc_id

  ingress {
    description     = "App"
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jenkins-go-proxy"
  }
}

resource "aws_security_group" "maven-cache" {
  name   = "jenkins-maven-cache"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    security_groups = [aws_security_group.allow_ssh.id, aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jenkins-maven-cache"
  }
}

resource "aws_security_group" "efs" {
  name        = "jenkins-efs"
  description = "Allow efs access for nexus container"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.maven-cache.id, aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "jenkins_efs"
    Owner    = "build-team"
    Consumer = "jenkins-worker"
  }
}

resource "aws_security_group" "bastion" {
  name        = "jenkins-ecs-ssh-bastion"
  description = "maven+efs access"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name     = "jenkins_ecs-ssh-bastion"
    Owner    = "build-team"
    Consumer = "jenkins-worker"
  }
}
