resource "aws_ssm_parameter" "authorized_keys" {
  name  = "gerrit__.ssh__authorized_keys"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/authorized_keys")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
resource "aws_ssm_parameter" "config" {
  name  = "gerrit__.ssh__config"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/config")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
resource "aws_ssm_parameter" "id_dsa" {
  name  = "gerrit__.ssh__id_dsa"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/id_dsa")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
resource "aws_ssm_parameter" "id_dsa_Ceej" {
  name  = "gerrit__.ssh__id_dsa_Ceej"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/id_dsa_Ceej")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
resource "aws_ssm_parameter" "id_dsa_Ceej_pub" {
  name  = "gerrit__.ssh__id_dsa_Ceej.pub"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/id_dsa_Ceej.pub")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
resource "aws_ssm_parameter" "id_dsa_pub" {
  name  = "gerrit__.ssh__id_dsa.pub"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/id_dsa.pub")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
resource "aws_ssm_parameter" "id_github_ns-codereview" {
  name  = "gerrit__.ssh__id_github_ns-codereview"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/id_github_ns-codereview")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
resource "aws_ssm_parameter" "id_github_ns-codereview_pub" {
  name  = "gerrit__.ssh__id_github_ns-codereview.pub"
  type  = "SecureString"
  value = file("~/aws-ssh/gerrit/.ssh/id_github_ns-codereview.pub")
  tags = {
    Owner    = local.owner
    Consumer = local.project
    Encoding = "none"
  }
}
