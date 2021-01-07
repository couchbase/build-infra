[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${jenkins_ui_port},
        "hostPort": ${jenkins_ui_port}
      },
      {
        "containerPort": ${jenkins_jnlp_port},
        "hostPort": ${jenkins_jnlp_port}
      }
    ],
    "mountPoints": [
      {
          "sourceVolume": "jenkins_home",
          "containerPath": "/var/jenkins_home",
          "readOnly": false
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${cloudwatch_log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${cloudwatch_log_prefix}"
        }
    }
  }
]
