[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8081,
        "hostPort": 8081
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
    "mountPoints": [
        {
            "containerPath": "/nexus-data",
            "sourceVolume": "service-storage"
        }
    ],
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -s -o /dev/null -m 5 http://127.0.0.1:8081/service/rest/v1/status"],
      "interval": 30,
      "timeout": 10,
      "retries": 5,
      "startPeriod": 300
    }
  }
]
