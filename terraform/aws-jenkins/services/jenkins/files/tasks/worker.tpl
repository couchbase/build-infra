[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "essential": true,
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
      },
      {
        "name": "NODE_CLASS",
        "value": "${node_class}"
      },
      {
        "name": "NODE_PRODUCT",
        "value": "${node_product}"
      }
    ],
    "secrets": [
      {
        "name": "profiledata_key",
        "valueFrom": "${profiledata_key_arn}"
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "dockersock",
        "containerPath": "/var/run/docker.sock"
      }
    ]
  }
]
