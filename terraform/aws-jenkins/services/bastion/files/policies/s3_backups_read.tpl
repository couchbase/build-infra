{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "s3",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::cb-jenkins.backups",
                "arn:aws:s3:::cb-jenkins.backups/*"
            ]
        }
    ]
}
