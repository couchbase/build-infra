[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 22,
        "hostPort": 22
      },
      {
        "containerPort": 80,
        "hostPort": 80
      },
      {
        "containerPort": 90,
        "hostPort": 90
      }
    ],
    "mountPoints": [
      {
          "sourceVolume": "latestbuilds",
          "containerPath": "/usr/share/nginx/html",
          "readOnly": true
      },
      {
          "sourceVolume": "latestbuilds",
          "containerPath": "/data",
          "readOnly": false
      }
    ],
    "secrets": [
      {
        "name": "htpasswd",
        "valueFrom": "${latestbuilds_htpasswd}"
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
