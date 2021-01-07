{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Resource": "${filesystem_arn}",
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${access_point_arn}"
                }
            }
        }
    ]
}
