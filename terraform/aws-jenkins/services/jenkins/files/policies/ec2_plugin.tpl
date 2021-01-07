{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Sid": "ec2",
           "Effect": "Allow",
           "Action": [
               "ec2:DescribeInstances",
               "ec2:TerminateInstances",
               "ec2:RequestSpotInstances",
               "ec2:DeleteTags",
               "ec2:CreateTags",
               "ec2:DescribeRegions",
               "ec2:RunInstances",
               "ec2:DescribeSpotInstanceRequests",
               "ec2:StopInstances",
               "ec2:DescribeSecurityGroups",
               "ec2:GetConsoleOutput",
               "ec2:DescribeSpotPriceHistory",
               "ec2:DescribeImages",
               "ec2:CancelSpotInstanceRequests",
               "ec2:GetPasswordData",
               "iam:PassRole",
               "ec2:StartInstances",
               "ec2:DescribeAvailabilityZones",
               "ec2:DescribeSubnets",
               "ec2:DescribeKeyPairs"
           ],
           "Resource": "*"
       }
   ]
}
