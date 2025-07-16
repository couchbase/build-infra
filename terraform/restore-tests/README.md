# Restore Testing IAM Resources

This Terraform configuration creates all the IAM resources needed for the restore testing system.

## Resources Created

### IAM Roles (for EC2 instances)
- `_jenkins_test_role` - For Jenkins restore testing instances
- `_gerrit_test_role` - For Gerrit restore testing instances
- `_build_db_test_role` - For build-db restore testing instances

### Instance Profiles
- One instance profile for each role (same names as roles)

### IAM User (for Jenkins/CI)
- `restore-testing` - User for running restore testing jobs

### Policies
- `restore-testing-ec2-s3-access` - S3 access for EC2 instances
- `restore-testing-user-policy` - Full permissions for the restore-testing user

## State Management

This configuration uses remote state stored in S3 with DynamoDB locking:

- **State bucket**: `couchbase-terraform-state`
- **State key**: `prod/restore-testing`
- **Lock table**: `terraform_state_lock`
- **Region**: `us-east-2`

### State Migration (if upgrading from local state)

If you previously had local state and are upgrading:

```bash
cd terraform/
terraform init  # Will prompt to migrate state to S3
```

Answer "yes" when prompted to copy your existing state to the new S3 backend.

## Usage

### Deploy the infrastructure:

```bash
cd terraform/
terraform init
terraform plan  # Will prompt for bucket names
terraform apply # Will prompt again, or use saved plan
```

When prompted, enter your actual bucket names:
```
var.backup_buckets["build_db"]
  Enter a value: your-actual-build-db-backups

var.backup_buckets["gerrit"]
  Enter a value: your-actual-gerrit-backups

var.backup_buckets["jenkins"]
  Enter a value: your-actual-jenkins-backups
```

**Alternative: Use command line variables**
```bash
terraform plan -var='backup_buckets={jenkins="your-jenkins-backups",gerrit="your-gerrit-backups",build_db="your-build-db-backups"}'
```

### Get the access credentials:

```bash
# Get the access key ID
terraform output restore_testing_access_key_id

# Get the secret access key (sensitive)
terraform output -raw restore_testing_secret_access_key
```

### Configure Jenkins/CI:

Set these environment variables in your Jenkins job:
```bash
AWS_ACCESS_KEY_ID="<access_key_id_from_terraform_output>"
AWS_SECRET_ACCESS_KEY="<secret_from_terraform_output>"
AWS_DEFAULT_REGION="us-east-2"
```

## Permissions Summary

### EC2 Instance Roles
Each service role can:
- List and read from backup S3 buckets
- Write results to `restore_testing/` paths in backup buckets

### restore-testing User
The user can:
- Launch/terminate EC2 instances with restore-testing tags
- Pass the service roles to EC2 instances
- Read/delete from `restore_testing/` paths
- Get AMI parameters from SSM
- List S3 buckets for validation

## Security Features

- EC2 instances can only write to specific restore_testing paths
- Instance termination limited to instances with correct tags
- IAM role passing limited to the three service roles
- Regional restrictions for EC2 operations
- **Bucket names are parameterized** - safe for public repositories

## Public Repository Safety

This configuration is designed to be safe for public repositories:

- ✅ **No hardcoded credentials** - Access keys only in Terraform state
- ✅ **No hardcoded account IDs** - Auto-detected or parameterized
- ✅ **Parameterized bucket names** - No defaults, prompts at runtime
- ✅ **Command-line input** - Bucket names never stored in files

### For Production Use:
1. Run `terraform plan` and enter your real bucket names when prompted
2. No files need to be kept private - all sensitive data is runtime-only
3. The `.tf` files contain no sensitive defaults

## Cleanup

To remove all resources:
```bash
terraform destroy
```

**Note**: This will delete the IAM user and access keys, which will break any Jenkins jobs using those credentials.
