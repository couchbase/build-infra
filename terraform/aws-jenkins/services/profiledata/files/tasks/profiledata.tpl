[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 4000,
        "hostPort": 4000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${cloudwatch_log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${cloudwatch_log_prefix}"
        }
    },
    "environment": [
      {
        "name": "aws",
        "value": "true"
      }
    ],
    "secrets": [
      {
        "name": "profiledata_pubkey",
        "valueFrom": "${profiledata_pubkey}"
      },
      {
        "name": "profiledata_ssh_host_rsa_key",
        "valueFrom": "${profiledata_ssh_host_rsa_key}"
      },
      {
        "name": "profiledata_ssh_host_rsa_pubkey",
        "valueFrom": "${profiledata_ssh_host_rsa_pubkey}"
      },
      {
        "name": "profiledata_ssh_host_ed25519_key",
        "valueFrom": "${profiledata_ssh_host_ed25519_key}"
      },
      {
        "name": "profiledata_ssh_host_ed25519_pubkey",
        "valueFrom": "${profiledata_ssh_host_ed25519_pubkey}"
      },
      {
        "name": "profiledata_ssh_host_ecdsa_key",
        "valueFrom": "${profiledata_ssh_host_ecdsa_key}"
      },
      {
        "name": "profiledata_ssh_host_ecdsa_pubkey",
        "valueFrom": "${profiledata_ssh_host_ecdsa_pubkey}"
      },
      {
        "name": "profiledata_ssh_host_dsa_key",
        "valueFrom": "${profiledata_ssh_host_dsa_key}"
      },
      {
        "name": "profiledata_ssh_host_dsa_pubkey",
        "valueFrom": "${profiledata_ssh_host_dsa_pubkey}"
      },

      {
        "name": "couchbase_server_shared_m2_settings_xml",
        "valueFrom": "${couchbase_server_shared_m2_settings_xml}"
      },
      {
        "name": "couchbase_server_shared_ssh_environment",
        "valueFrom": "${couchbase_server_shared_ssh_environment}"
      },
      {
        "name": "couchbase_server_shared_gitconfig",
        "valueFrom": "${couchbase_server_shared_gitconfig}"
      },

      {
        "name": "couchbase_server_cv_linux_gitconfig",
        "valueFrom": "${couchbase_server_cv_linux_gitconfig}"
      },
      {
        "name": "couchbase_server_cv_linux_m2_settings_xml",
        "valueFrom": "${couchbase_server_cv_linux_m2_settings_xml}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_config",
        "valueFrom": "${couchbase_server_cv_linux_ssh_config}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_id_ns_codereview",
        "valueFrom": "${couchbase_server_cv_linux_ssh_id_ns_codereview}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_known_hosts",
        "valueFrom": "${couchbase_server_cv_linux_ssh_known_hosts}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_ns_buildbot_rsa",
        "valueFrom": "${couchbase_server_cv_linux_ssh_ns_buildbot_rsa}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_patch_via_gerrit_ini",
        "valueFrom": "${couchbase_server_cv_linux_ssh_patch_via_gerrit_ini}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_id_buildbot",
        "valueFrom": "${couchbase_server_cv_linux_ssh_id_buildbot}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_environment",
        "valueFrom": "${couchbase_server_cv_linux_ssh_environment}"
      },
      {
        "name": "couchbase_server_cv_linux_ssh_buildbot_id_dsa",
        "valueFrom": "${couchbase_server_cv_linux_ssh_buildbot_id_dsa}"
      },

      {
        "name": "couchbase_server_build_linux_gitconfig",
        "valueFrom": "${couchbase_server_build_linux_gitconfig}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_config",
        "valueFrom": "${couchbase_server_build_linux_ssh_config}"
      },
      {
        "name": "couchbase_server_build_linux_gpg_rpm_signing",
        "valueFrom": "${couchbase_server_build_linux_gpg_rpm_signing}"
      },
      {
        "name": "couchbase_server_build_linux_m2_settings_xml",
        "valueFrom": "${couchbase_server_build_linux_m2_settings_xml}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_environment",
        "valueFrom": "${couchbase_server_build_linux_ssh_environment}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_id_buildbot",
        "valueFrom": "${couchbase_server_build_linux_ssh_id_buildbot}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_id_cb_robot",
        "valueFrom": "${couchbase_server_build_linux_ssh_id_cb_robot}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_id_ns_codereview",
        "valueFrom": "${couchbase_server_build_linux_ssh_id_ns_codereview}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_known_hosts",
        "valueFrom": "${couchbase_server_build_linux_ssh_known_hosts}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_notarizer_token",
        "valueFrom": "${couchbase_server_build_linux_ssh_notarizer_token}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_ns_buildbot_rsa",
        "valueFrom": "${couchbase_server_build_linux_ssh_ns_buildbot_rsa}"
      },
      {
        "name": "couchbase_server_build_linux_ssh_patch_via_gerrit_ini",
        "valueFrom": "${couchbase_server_build_linux_ssh_patch_via_gerrit_ini}"
      },

      {
        "name": "couchbase_server_cv_windows_gitconfig",
        "valueFrom": "${couchbase_server_cv_windows_gitconfig}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_buildbot_id_dsa",
        "valueFrom": "${couchbase_server_cv_windows_ssh_buildbot_id_dsa}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_config",
        "valueFrom": "${couchbase_server_cv_windows_ssh_config}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_config_org",
        "valueFrom": "${couchbase_server_cv_windows_ssh_config_org}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_environment",
        "valueFrom": "${couchbase_server_cv_windows_ssh_environment}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_id_ns_codereview",
        "valueFrom": "${couchbase_server_cv_windows_ssh_id_ns_codereview}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_id_rsa",
        "valueFrom": "${couchbase_server_cv_windows_ssh_id_rsa}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_known_hosts",
        "valueFrom": "${couchbase_server_cv_windows_ssh_known_hosts}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_ns_buildbot_rsa",
        "valueFrom": "${couchbase_server_cv_windows_ssh_ns_buildbot_rsa}"
      },
      {
        "name": "couchbase_server_cv_windows_ssh_patch_via_gerrit_ini",
        "valueFrom": "${couchbase_server_cv_windows_ssh_patch_via_gerrit_ini}"
      },

      {
        "name": "couchbase_server_windows_config",
        "valueFrom": "${couchbase_server_windows_config}"
      },
      {
        "name": "couchbase_server_windows_authorized_keys",
        "valueFrom": "${couchbase_server_windows_authorized_keys}"
      },

      {
        "name": "couchbase_server_windows_environment",
        "valueFrom": "${couchbase_server_windows_environment}"
      },
      {
        "name": "couchbase_server_windows_known_hosts",
        "valueFrom": "${couchbase_server_windows_known_hosts}"
      }
    ]
  }
]
