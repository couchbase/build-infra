# Jenkins Restore Test

This script carries out a number of actions to validate a Jenkins backup can
be restored without issue. It:

- Launches a new instance which:
  - Downloads the previous day's backup file from s3 and extracts its contents
  - Modifies config.xml to disable auth
  - Starts a container on an internal-only network with a healthcheck
  - Waits for Jenkins to come up and for its healthcheck to pass
  - Runs a playwright container on the same internal-only network to grab a
    screenshot of the Jenkins UI
  - Upload a status file along with the screenshot to an S3 bucket
- Back on the host instance, the script is polling the S3 bucket waiting for
  the success + screenshot files to appear:
  - If the files appear, they are downloaded locally and removed from S3
  - If the files do not appear within a set time, the job fails

It should be called with the relevant info present in the environment,
specifically:

- ROLE
- S3_BUCKET
- SECURITY_GROUP_ID
- SUBNET_ID
- VPC_ID

The script should be invoked with `./go.sh [instance]` where `[instance]`
is the jenkins instance you aim to restore. For debugging purposes you
can provide an additional arg containing the name of a key held in aws.
e.g. to test cv's backup, and ensure the instance running the restore
can be logged into by `homer`, run `./go.sh cv homer`
