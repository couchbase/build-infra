[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "essential": true,
    "command": ["swarm"],
    "portMappings": [
      {
        "containerPort": 22,
        "hostPort": 22
      }
    ],
    "environment": [
      {
        "name": "JENKINS_MASTER",
        "value": "${master_url}"
      },
      {
        "name": "JENKINS_SLAVE_LABELS",
        "value": "zz-lightweight ${jenkins_name}-zz-lightweight zz-${jenkins_name}-lightweight"
      },
      {
        "name": "JENKINS_SLAVE_NAME",
        "value": "aws-zz-lightweight"
      },
      {
        "name": "AGENT_MODE",
        "value": "normal"
      },
      {
        "name": "JENKINS_SLAVE_EXECUTORS",
        "value": "10"
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
        "name": "jenkins_user",
        "valueFrom": "${jenkins_user}"
      },
      {
        "name": "jenkins_password",
        "valueFrom": "${jenkins_password}"
      },
      {
        "name": "profiledata_key",
        "valueFrom": "${profiledata_key_arn}"
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
