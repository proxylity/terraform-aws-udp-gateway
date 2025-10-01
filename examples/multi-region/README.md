# Multi-Region Proxylity UDP Gateway Example

This example demonstrates how to create a Proxylity UDP Gateway with regional S3 destinations across multiple AWS regions for optimal latency and data residency.

## Architecture

```
UDP Traffic → Proxylity Listener (us-west-2) 
                     ↓
                 Destination: "regional-s3-storage" (no ARNs initially)
                     ↓
    Regional destination_arn modules bind regional S3 buckets:
                     ├─ us-west-2 → S3 bucket (+ IAM policy)
                     ├─ us-east-1 → S3 bucket (+ IAM policy)
                     └─ eu-west-1 → S3 bucket (+ IAM policy)
                     
    Proxylity automatically updates the destination with regional routing!
```

## Features Demonstrated

- **Clean separation**: Listener creates destination names, regions bind ARNs separately
- **Regional infrastructure**: S3 bucket + IAM policy + destination ARN binding per region
- **Automatic routing**: Proxylity updates listener when destination_arn resources are created
- **Scalable pattern**: Easy to add/remove regions independently

## Resources Created

- UDP Gateway Listener in us-west-2 with destination name "regional-s3-storage"
- Per region (us-west-2, us-east-1, eu-west-1):
  - S3 bucket for packet storage
  - IAM policy granting bucket access to global role
  - Destination ARN binding that links the bucket to the destination name
- Global IAM role for Proxylity service

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Cleanup

```bash
terraform destroy
```

Note: Ensure you have AWS credentials configured for all three regions.