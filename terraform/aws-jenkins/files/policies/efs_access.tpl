{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${analytics_jenkins_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${analytics_jenkins_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${cv_jenkins_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${cv_jenkins_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${server_jenkins_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${server_jenkins_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${mobile_jenkins_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${mobile_jenkins_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${nexus_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${nexus_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${proget_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${proget_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${downloads_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${downloads_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ${latestbuilds_principals}
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${latestbuilds_access_point_arn}"
                }
            },
            "Resource": "${filesystem_arn}"
        }
    ]
}
