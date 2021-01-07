resource "aws_ecs_service" "profiledata" {
  # LATEST isn't most recent, need to specify platform_version to mount EFS on Fargate
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
  platform_version = var.context == "EC2" ? "" : "1.4.0"
  name             = "${var.prefix}-profiledata"
  cluster          = var.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.profiledata.arn
  launch_type      = var.context
  desired_count    = var.stopped ? 0 : 1

  service_registries {
    registry_arn = aws_service_discovery_service.profiledata.arn
  }

  network_configuration {
    subnets          = var.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.profiledata.id]
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}

resource "aws_ecs_task_definition" "profiledata" {
  family = "${var.prefix}-profiledata"

  container_definitions = templatefile("${path.module}/files/tasks/profiledata.tpl", {
    cloudwatch_log_group  = aws_cloudwatch_log_group.profiledata.name
    cloudwatch_log_prefix = "profiledata"
    container_name        = var.hostname
    container_image       = var.image
    region                = var.region
    # Client ssh pub key
    profiledata_pubkey = aws_ssm_parameter.profiledata_pubkey.arn
    # Host keys
    profiledata_ssh_host_rsa_key        = aws_ssm_parameter.profiledata_ssh_host_rsa_key.arn
    profiledata_ssh_host_rsa_pubkey     = aws_ssm_parameter.profiledata_ssh_host_rsa_pubkey.arn
    profiledata_ssh_host_ed25519_key    = aws_ssm_parameter.profiledata_ssh_host_ed25519_key.arn
    profiledata_ssh_host_ed25519_pubkey = aws_ssm_parameter.profiledata_ssh_host_ed25519_pubkey.arn
    profiledata_ssh_host_ecdsa_key      = aws_ssm_parameter.profiledata_ssh_host_ecdsa_key.arn
    profiledata_ssh_host_ecdsa_pubkey   = aws_ssm_parameter.profiledata_ssh_host_ecdsa_pubkey.arn
    profiledata_ssh_host_dsa_key        = aws_ssm_parameter.profiledata_ssh_host_dsa_key.arn
    profiledata_ssh_host_dsa_pubkey     = aws_ssm_parameter.profiledata_ssh_host_dsa_pubkey.arn
    # Config files
    couchbase_server_shared_ssh_environment  = aws_ssm_parameter.couchbase_server_shared_ssh_environment.arn
    couchbase_server_shared_gitconfig        = aws_ssm_parameter.couchbase_server_shared_gitconfig.arn
    couchbase_server_shared_m2_settings_xml      = aws_ssm_parameter.couchbase_server_shared_m2_settings_xml.arn
    couchbase_server_cv_linux_ssh_config     = aws_ssm_parameter.couchbase_server_cv_linux_ssh_config.arn
    couchbase_server_windows_config          = aws_ssm_parameter.couchbase_server_windows_config.arn
    couchbase_server_windows_authorized_keys = aws_ssm_parameter.couchbase_server_windows_authorized_keys.arn
    couchbase_server_windows_environment     = aws_ssm_parameter.couchbase_server_windows_environment.arn
    couchbase_server_windows_known_hosts     = aws_ssm_parameter.couchbase_server_windows_known_hosts.arn
    # Build Linux
    couchbase_server_build_linux_gpg_rpm_signing   = aws_ssm_parameter.couchbase_server_build_linux_gpg_rpm_signing.arn
    couchbase_server_build_linux_m2_settings_xml   = aws_ssm_parameter.couchbase_server_build_linux_m2_settings_xml.arn
    couchbase_server_build_linux_gitconfig   = aws_ssm_parameter.couchbase_server_build_linux_gitconfig.arn
    couchbase_server_build_linux_ssh_config  = aws_ssm_parameter.couchbase_server_build_linux_ssh_config.arn
    couchbase_server_build_linux_ssh_environment  = aws_ssm_parameter.couchbase_server_build_linux_ssh_environment.arn
    couchbase_server_build_linux_ssh_id_buildbot  = aws_ssm_parameter.couchbase_server_build_linux_ssh_id_buildbot.arn
    couchbase_server_build_linux_ssh_id_cb_robot  = aws_ssm_parameter.couchbase_server_build_linux_ssh_id_cb_robot.arn
    couchbase_server_build_linux_ssh_id_ns_codereview  = aws_ssm_parameter.couchbase_server_build_linux_ssh_id_ns_codereview.arn
    couchbase_server_build_linux_ssh_known_hosts  = aws_ssm_parameter.couchbase_server_build_linux_ssh_known_hosts.arn
    couchbase_server_build_linux_ssh_notarizer_token  = aws_ssm_parameter.couchbase_server_build_linux_ssh_notarizer_token.arn
    couchbase_server_build_linux_ssh_ns_buildbot_rsa  = aws_ssm_parameter.couchbase_server_build_linux_ssh_ns_buildbot_rsa.arn
    couchbase_server_build_linux_ssh_patch_via_gerrit_ini  = aws_ssm_parameter.couchbase_server_build_linux_ssh_patch_via_gerrit_ini.arn
    # CV Linux
    couchbase_server_cv_linux_gitconfig   = aws_ssm_parameter.couchbase_server_cv_linux_gitconfig.arn
    couchbase_server_cv_linux_m2_settings_xml   = aws_ssm_parameter.couchbase_server_cv_linux_m2_settings_xml.arn
    couchbase_server_cv_linux_ssh_config   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_config.arn
    couchbase_server_cv_linux_ssh_id_ns_codereview   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_id_ns_codereview.arn
    couchbase_server_cv_linux_ssh_known_hosts   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_known_hosts.arn
    couchbase_server_cv_linux_ssh_ns_buildbot_rsa   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_ns_buildbot_rsa.arn
    couchbase_server_cv_linux_ssh_patch_via_gerrit_ini   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_patch_via_gerrit_ini.arn
    couchbase_server_cv_linux_ssh_id_buildbot   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_id_buildbot.arn
    couchbase_server_cv_linux_ssh_environment   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_environment.arn
    couchbase_server_cv_linux_ssh_buildbot_id_dsa   = aws_ssm_parameter.couchbase_server_cv_linux_ssh_buildbot_id_dsa.arn
    # CV Windows
    couchbase_server_cv_windows_gitconfig            = aws_ssm_parameter.couchbase_server_cv_windows_gitconfig.arn
    couchbase_server_cv_windows_ssh_known_hosts            = aws_ssm_parameter.couchbase_server_cv_windows_ssh_known_hosts.arn
    couchbase_server_cv_windows_ssh_buildbot_id_dsa  = aws_ssm_parameter.couchbase_server_cv_windows_ssh_buildbot_id_dsa.arn
    couchbase_server_cv_windows_ssh_config               = aws_ssm_parameter.couchbase_server_cv_windows_ssh_config.arn
    couchbase_server_cv_windows_ssh_config_org           = aws_ssm_parameter.couchbase_server_cv_windows_ssh_config_org.arn
    couchbase_server_cv_windows_ssh_environment          = aws_ssm_parameter.couchbase_server_cv_windows_ssh_environment.arn
    couchbase_server_cv_windows_ssh_id_ns_codereview     = aws_ssm_parameter.couchbase_server_cv_windows_ssh_id_ns_codereview.arn
    couchbase_server_cv_windows_ssh_id_rsa               = aws_ssm_parameter.couchbase_server_cv_windows_ssh_id_rsa.arn
    couchbase_server_cv_windows_ssh_ns_buildbot_rsa      = aws_ssm_parameter.couchbase_server_cv_windows_ssh_ns_buildbot_rsa.arn
    couchbase_server_cv_windows_ssh_patch_via_gerrit_ini = aws_ssm_parameter.couchbase_server_cv_windows_ssh_patch_via_gerrit_ini.arn
  })
  execution_role_arn = var.ecs_iam_role.arn
  task_role_arn      = aws_iam_role.profiledata.arn

  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  network_mode = "awsvpc"
}
