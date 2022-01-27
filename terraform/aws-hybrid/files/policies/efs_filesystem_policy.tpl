{
    "Version": "2012-10-17",
    "Id": "FS",
    "Statement": [
        {
            "Sid": "Access",
            "Effect": "Allow",
            "Principal": { "AWS": [
                "${maven_cache_principal}"
            ] },
            "Resource": "${filesystem_arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${access_point_arn}"
                }
            }
        }
    ]
}