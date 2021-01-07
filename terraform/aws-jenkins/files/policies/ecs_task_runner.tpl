{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect":"Allow",
            "Action":"iam:PassRole",
            "Resource": ${roles}
        },
        {
            "Sid": "ecs1",
            "Action": [
                "ecs:RegisterTaskDefinition",
                "ecs:DeregisterTaskDefinition",
                "ecs:DescribeContainerInstances",
                "ecs:ListClusters",
                "ecs:ListTaskDefinitions",
                "ecs:DescribeTaskDefinition",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:Submit*",
                "ecs:StartTask"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Sid": "ecs2",
            "Action": [
                "ecs:StopTask",
                "ecs:ListContainerInstances",
                "ecs:DescribeClusters"
            ],
            "Effect": "Allow",
            "Resource": "${cluster_arn}"
        },
        {
            "Sid": "ecs3",
            "Action": [
                "ecs:RunTask"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:ecs:${region}:${account}:task-definition/*"
        },
        {
            "Sid": "ecs4",
            "Action": [
                "ecs:StopTask",
		        "ecs:DescribeTasks"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:ecs:${region}:${account}:task/*"
        }
    ]
}
