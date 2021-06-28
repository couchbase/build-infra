resource "aws_security_group" "allow_ssh" {
  name        = "jenkins_ec2_allow_ssh"
  description = "Allows SSH access on 22 and 4000"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Host access via instance connect "
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ var.aws_instance_connect_cidr ]
  }

  ingress {
    description      = "Container access direct from datacenter"
    from_port        = 4000
    to_port          = 4000
    protocol         = "tcp"
    cidr_blocks      = [ var.datacenter_cidr ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "jenkins_ec2_allow_ssh"
    Owner = "build-team"
    Consumer = "jenkins-worker"
  }
}
