{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "profiledataread",
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "{{ parameter_arn }}"
        }
    ]
}
