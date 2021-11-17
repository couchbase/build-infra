{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:CreateMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:ListMultipartUploadParts",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::${bucket}",
                "arn:aws:s3:::${bucket}/*"
            ]
        },
        {
            "Sid": "AttachDetach",
            "Effect": "Allow",
            "Action": [
                "ec2:DetachVolume",
                "ec2:AttachVolume"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ec2:*:*:volume/*"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "ec2:ResourceTag/Project": "gerrit",
                    "ec2:ResourceTag/Purpose": "backup-restore"
                }
            }
        },
        {
            "Sid": "WaitVolume",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSnapshots",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CreateVolume",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume",
                "ec2:CreateTags"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DeleteVolume",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "ForAllValues:StringEquals": {
                    "ec2:ResourceTag/Project": "gerrit",
                    "ec2:ResourceTag/Purpose": "backup-restore"
                }
            }
        }
    ]
}
