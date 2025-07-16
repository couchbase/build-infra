# Couchbase Service Restore Testing

Automated validation system for testing backup restoration of Couchbase infrastructure services (Jenkins, Gerrit, and build-db). This system spins up AWS EC2 instances, restores services from S3 backups, and validates functionality through UI testing.

## Overview

The restore testing system supports three service types:
- **Jenkins instances** (server_jenkins, analytics_jenkins, cv_jenkins, mobile_jenkins, sdk_jenkins)
- **Gerrit** (gerrit)
- **Couchbase Server** (build-db)

Each test:
1. Launches an EC2 instance with appropriate IAM permissions
2. Downloads backup files from S3
3. Restores the service using Docker Compose
4. Captures UI screenshots for visual validation
5. Uploads screenshots and status to S3
6. Terminates the instance

## Architecture

```
go.sh (orchestrator)
├── Validates S3 bucket structure
├── Generates service-specific userdata script
├── Launches EC2 instance
├── Monitors validation completion
└── Retrieves results

src/userdata-template.sh (template)
├── Common setup and utility functions
├── Docker and screenshot infrastructure
└── Service-specific function injection

src/{jenkins,gerrit,build-db}.sh (service modules)
├── Download functions
├── Extraction functions
├── Configuration functions
└── Validation functions
```

## Prerequisites

### AWS Setup

**Option 1: Use Terraform (Recommended)**
```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your real bucket names
terraform init && terraform apply
```

**Option 2: Manual Setup**
1. **IAM Instance Profiles** with S3 access:
   - `_jenkins_test_role`
- `_gerrit_test_role`
- `_build_db_test_role`

2. **IAM Policy Example** (for build-db):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": "arn:aws:s3:::build-db.backups"
        },
        {
            "Sid": "AllowReadAccessToBackups",
            "Effect": "Allow",
            "Action": ["s3:GetObject"],
            "Resource": "arn:aws:s3:::build-db.backups/*"
        },
        {
            "Sid": "AllowWriteAccessToRestores",
            "Effect": "Allow",
            "Action": ["s3:PutObject"],
            "Resource": "arn:aws:s3:::build-db.backups/restore_testing/*"
        }
    ]
}
```

### Local Dependencies
- AWS CLI configured with appropriate credentials
- `envsubst` (part of gettext package)
- `awk` and standard Unix utilities

## Usage

### Required Environment Variables

```bash
export SERVICE="server_jenkins"              # Service to test
export S3_BUCKET="cb-jenkins.backups"        # S3 bucket containing backups
export SECURITY_GROUP_ID="sg-xxxxxxxxxx"     # Security group allowing HTTP access
export SUBNET_ID="subnet-xxxxxxxxxx"         # Public subnet ID
export VPC_ID="vpc-xxxxxxxxxx"               # VPC ID
```

### Optional Environment Variables

```bash
export SSH_KEY_NAME="my-key-pair"             # SSH key for instance access (debugging)
```

### Basic Usage

```bash
# Test Jenkins server backup restoration
export SERVICE="server_jenkins"
export S3_BUCKET="cb-jenkins.backups"
export SECURITY_GROUP_ID="sg-12345678"
export SUBNET_ID="subnet-87654321"
export VPC_ID="vpc-abcdef12"

./go.sh
```

### Help

```bash
./go.sh --help
```

## Supported Services

### Jenkins Services
- `server_jenkins`
- `analytics_jenkins`
- `cv_jenkins`
- `mobile_jenkins`
- `sdk_jenkins`

**Backup Structure**: `s3://bucket/service_name/jenkins_backup.{Mon|Tue|Wed|Thu|Fri|Sat|Sun}.tar.gz`

**Screenshot**: Captures Jenkins dashboard after disabling Okta authentication

### Gerrit
- `gerrit` - Code review system

**Backup Structure**: `s3://bucket/backup-YYYYMMDD.tgz` (weekly Saturday backups)

**Screenshot**: Captures Gerrit dashboard

### Couchbase Server (build-db)
- `build-db` - Build database

**Backup Structure**:
```
s3://bucket/
├── backups/
│   ├── YYYY-MM-DDTHH_MM_SS.SSSSSSSSZ/  # Timestamp directories
│   ├── backup-meta.json
│   ├── .info
│   ├── README.md
│   └── .backup
└── logs/
```

**Validation & Screenshot**:
1. Restores data using `cbbackupmgr`
2. Validates 1M+ items restored across restored buckets
3. Captures Buckets page after authentication

## Jenkins Integration

For use in Jenkins jobs, configure the backup bucket names:

```bash
# Example Jenkins job configuration
case "${SERVICE}" in
    *_jenkins)
        export S3_BUCKET="your-jenkins-backup-bucket"
        ;;
    gerrit)
        export S3_BUCKET="your-gerrit-backup-bucket"
        ;;
    build-db)
        export S3_BUCKET="your-build-db-backup-bucket"
        ;;
    *)
        echo "ERROR: Unknown service: ${SERVICE}"
        exit 1
        ;;
esac

# Then run the restore testing
./go.sh
```

This approach:
- **Keeps bucket names in Jenkins configuration** (not in public repo)
- **Auto-detects IAM roles** based on service type
- **Simplifies configuration** - only bucket names need to be set

## Backup Detection

### Jenkins & Gerrit
- **Jenkins**: Uses previous day's backup (e.g., `jenkins_backup.Mon.tar.gz` for Tuesday runs)
- **Gerrit**: Uses previous Saturday's backup (e.g., `backup-20250712.tgz`)

### Couchbase Server
- Automatically detects latest backup timestamp directory
- Extracts version from `.restrictions.json` for container compatibility
- Downloads complete cbbackupmgr archive structure

## Instance Types

- **Jenkins/Gerrit**: `c6g.2xlarge` (8 vCPU, 16 GB RAM)
- **Couchbase/build-db**: `c6g.4xlarge` (16 vCPU, 32 GB RAM) - for memory-intensive restoration

## Output

Results are uploaded to the same S3 bucket the backups live in under `restore_testing/{service}/`:

```
s3://bucket/restore_testing/server_jenkins/
├── 2025-07-16-09-30-15-server_jenkins-screenshot.jpg
└── 2025-07-16-09-30-15-server_jenkins-status.txt
```

**Status**: `SUCCESS` or `FAILURE`

**Screenshot**: Full-page screenshot of validated service UI

## Troubleshooting

### Debugging

1. **SSH Access**: Set `SSH_KEY_NAME` environment variable to access EC2 instance
2. **Manual Validation**: Instance remains running during validation window

### Version Compatibility

- **Couchbase**: Automatically detects backup version from `.restrictions.json`
- **Jenkins**: Extracts version from `updates/default.json` in backup
- **Gerrit**: Fetches current version from build-infra repository

## Development

### Adding New Services

1. Create `src/new-service.sh` with required functions:
   - `download_backup()`
   - `extract_backup()`
   - `configure_service()`
   - `service_main()`

2. Update service detection logic in `go.sh`

3. Add S3 bucket validation for new service structure

4. Create appropriate IAM instance profile
