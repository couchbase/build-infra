data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "profiledata" {
  name               = "${var.prefix}-profiledata"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "profiledata_ssm" {
  role       = var.ecs_iam_role.name
  policy_arn = aws_iam_policy.profiledata_ssm.arn
}

resource "aws_iam_policy" "profiledata_ssm" {
  name = "_${var.prefix}-profiledata-ssm"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ],
        "Resource": [
          "${aws_ssm_parameter.profiledata_pubkey.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_rsa_key.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_rsa_pubkey.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_ed25519_key.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_ed25519_pubkey.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_ecdsa_key.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_ecdsa_pubkey.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_dsa_key.arn}",
          "${aws_ssm_parameter.profiledata_ssh_host_dsa_pubkey.arn}",
          "${aws_ssm_parameter.couchbase_server_shared_m2_settings_xml.arn}",
          "${aws_ssm_parameter.couchbase_server_shared_ssh_environment.arn}",
          "${aws_ssm_parameter.couchbase_server_shared_gitconfig.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_config.arn}",

          "${aws_ssm_parameter.couchbase_server_build_linux_gpg_rpm_signing.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_m2_settings_xml.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_gitconfig.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_config.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_environment.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_id_buildbot.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_id_cb_robot.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_id_ns_codereview.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_known_hosts.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_notarizer_token.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_ns_buildbot_rsa.arn}",
          "${aws_ssm_parameter.couchbase_server_build_linux_ssh_patch_via_gerrit_ini.arn}",

          "${aws_ssm_parameter.couchbase_server_cv_linux_gitconfig.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_m2_settings_xml.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_config.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_id_ns_codereview.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_known_hosts.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_ns_buildbot_rsa.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_patch_via_gerrit_ini.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_id_buildbot.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_environment.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_linux_ssh_buildbot_id_dsa.arn}",

          "${aws_ssm_parameter.couchbase_server_cv_windows_gitconfig.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_buildbot_id_dsa.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_config.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_config_org.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_environment.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_id_ns_codereview.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_id_rsa.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_known_hosts.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_ns_buildbot_rsa.arn}",
          "${aws_ssm_parameter.couchbase_server_cv_windows_ssh_patch_via_gerrit_ini.arn}",

          "${aws_ssm_parameter.couchbase_server_windows_config.arn}",
          "${aws_ssm_parameter.couchbase_server_windows_authorized_keys.arn}",
          "${aws_ssm_parameter.couchbase_server_windows_environment.arn}",
          "${aws_ssm_parameter.couchbase_server_windows_known_hosts.arn}"
        ]
      }
    ]
}
EOF
}
