##########
# Shared #
##########
resource "aws_ssm_parameter" "couchbase_server_shared_m2_settings_xml" {
  name  = "${var.prefix}-couchbase_server_shared_m2_settings_xml"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/shared/.m2/settings.xml")
}

resource "aws_ssm_parameter" "couchbase_server_shared_ssh_environment" {
  name  = "${var.prefix}-couchbase_server_shared_ssh_environment"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/shared/.ssh/environment")
}

resource "aws_ssm_parameter" "couchbase_server_shared_gitconfig" {
  name  = "${var.prefix}-couchbase_server_shared_gitconfig"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/shared/.gitconfig")
}


############
# Linux CV #
############
resource "aws_ssm_parameter" "couchbase_server_cv_linux_gitconfig" {
  name  = "${var.prefix}-couchbase_server_cv_linux_gitconfig"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.gitconfig")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_m2_settings_xml" {
  name  = "${var.prefix}-couchbase_server_cv_linux_m2_settings_xml"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.m2/settings.xml")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_config" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_config"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/config")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_id_ns_codereview" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_id_ns_codereview"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/id_ns-codereview")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_known_hosts" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_known_hosts"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/known_hosts")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_ns_buildbot_rsa" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_ns_buildbot_rsa"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/ns-buildbot.rsa")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_patch_via_gerrit_ini" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_patch_via_gerrit_ini"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/patch_via_gerrit.ini")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_id_buildbot" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_id_buildbot"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/id_buildbot")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_environment" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_environment"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/environment")
}

resource "aws_ssm_parameter" "couchbase_server_cv_linux_ssh_buildbot_id_dsa" {
  name  = "${var.prefix}-couchbase_server_cv_linux_ssh_buildbot_id_dsa"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/linux/.ssh/buildbot_id_dsa")
}


###############
# Linux Build #
###############
resource "aws_ssm_parameter" "couchbase_server_build_linux_gitconfig" {
  name  = "${var.prefix}-couchbase_server_build_linux_gitconfig"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.gitconfig")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_config" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_config"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/config")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_gpg_rpm_signing" {
  name  = "${var.prefix}-couchbase_server_build_linux_gpg_rpm_signing"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.gpg/rpm_signing")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_m2_settings_xml" {
  name  = "${var.prefix}-couchbase_server_build_linux_m2_settings_xml"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.m2/settings.xml")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_environment" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_environment"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/environment")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_id_buildbot" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_id_buildbot"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/id_buildbot")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_id_cb_robot" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_id_cb_robot"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/id_cb-robot")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_id_ns_codereview" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_id_ns_codereview"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/id_ns-codereview")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_known_hosts" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_known_hosts"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/known_hosts")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_notarizer_token" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_notarizer_token"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/notarizer_token")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_ns_buildbot_rsa" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_ns_buildbot_rsa"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/ns-buildbot.rsa")
}

resource "aws_ssm_parameter" "couchbase_server_build_linux_ssh_patch_via_gerrit_ini" {
  name  = "${var.prefix}-couchbase_server_build_linux_ssh_patch_via_gerrit_ini"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/build/linux/.ssh/patch_via_gerrit.ini")
}


#################
# Windows Build #
#################
resource "aws_ssm_parameter" "couchbase_server_windows_config" {
  name  = "${var.prefix}-couchbase_server_windows_config"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/windows/config")
}

resource "aws_ssm_parameter" "couchbase_server_windows_authorized_keys" {
  name  = "${var.prefix}-couchbase_server_windows_authorized_keys"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/windows/authorized_keys")
}

resource "aws_ssm_parameter" "couchbase_server_windows_environment" {
  name  = "${var.prefix}-couchbase_server_windows_environment"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/windows/environment")
}

resource "aws_ssm_parameter" "couchbase_server_windows_known_hosts" {
  name  = "${var.prefix}-couchbase_server_windows_known_hosts"
  type  = "SecureString"
  tier  = "Advanced"
  value = file("~/aws-ssh/couchbase-server/windows/known_hosts")
}


##############
# Windows CV #
##############
resource "aws_ssm_parameter" "couchbase_server_cv_windows_gitconfig" {
  name  = "${var.prefix}-couchbase_server_cv_windows_gitconfig"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.gitconfig")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_buildbot_id_dsa" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_buildbot_id_dsa"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/buildbot_id_dsa")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_config" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_config"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/config")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_config_org" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_config_org"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/config.org")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_environment" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_environment"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/environment")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_id_ns_codereview" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_id_ns_codereview"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/id_ns-codereview")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_id_rsa" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_id_rsa"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/id_rsa")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_known_hosts" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_known_hosts"
  type  = "SecureString"
  tier  = "Advanced"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/known_hosts")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_ns_buildbot_rsa" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_ns_buildbot_rsa"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/ns-buildbot.rsa")
}

resource "aws_ssm_parameter" "couchbase_server_cv_windows_ssh_patch_via_gerrit_ini" {
  name  = "${var.prefix}-couchbase_server_cv_windows_ssh_patch_via_gerrit_ini"
  type  = "SecureString"
  value = file("~/aws-ssh/couchbase-server/cv/windows/.ssh/patch_via_gerrit.ini")
}


##############
# Client Key #
##############
resource "aws_ssm_parameter" "profiledata_key" {
  name  = "${var.prefix}-profiledata-key"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata")
}

resource "aws_ssm_parameter" "profiledata_pubkey" {
  name  = "${var.prefix}-profiledata-pubkey"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata.pub")
}


#############
# Host Keys #
#############
resource "aws_ssm_parameter" "profiledata_ssh_host_rsa_pubkey" {
  name  = "${var.prefix}-profiledata_ssh_host_rsa_pubkey"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_rsa_key.pub")
}

resource "aws_ssm_parameter" "profiledata_ssh_host_rsa_key" {
  name  = "${var.prefix}-profiledata_ssh_host_rsa_key"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_rsa_key")
}

resource "aws_ssm_parameter" "profiledata_ssh_host_ed25519_key" {
  name  = "${var.prefix}-profiledata_ssh_host_ed25519_key"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_ed25519_key")
}

resource "aws_ssm_parameter" "profiledata_ssh_host_ed25519_pubkey" {
  name  = "${var.prefix}-profiledata_ssh_host_ed25519_pubkey"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_ed25519_key.pub")
}

resource "aws_ssm_parameter" "profiledata_ssh_host_ecdsa_key" {
  name  = "${var.prefix}-profiledata_ssh_host_ecdsa_key"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_ecdsa_key")
}

resource "aws_ssm_parameter" "profiledata_ssh_host_ecdsa_pubkey" {
  name  = "${var.prefix}-profiledata_ssh_host_ecdsa_pubkey"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_ecdsa_key.pub")
}

resource "aws_ssm_parameter" "profiledata_ssh_host_dsa_key" {
  name  = "${var.prefix}-profiledata_ssh_host_dsa_key"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_dsa_key")
}

resource "aws_ssm_parameter" "profiledata_ssh_host_dsa_pubkey" {
  name  = "${var.prefix}-profiledata_ssh_host_dsa_pubkey"
  type  = "SecureString"
  value = file("~/aws-ssh/profiledata_ssh_host_dsa_key.pub")
}
