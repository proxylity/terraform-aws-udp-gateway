# Testing the Proxylity Terraform Module

This guide explains how to test and deploy the example configurations.

## Prerequisites

### 1. AWS CLI Configuration
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### 2. Terraform Installation
```bash
# Install Terraform (version >= 1.0)
# Visit https://terraform.io/downloads for installation instructions
terraform version
```

### 3. AWS Permissions
Ensure your AWS credentials have permissions for:
- IAM (roles, policies)
- S3 (buckets, objects)
- CloudFormation (stacks)
- Access to Proxylity configuration buckets

## Testing Simple Example

### 1. Navigate to Simple Example
```bash
cd examples/simple
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review the Plan
```bash
terraform plan
```

### 4. Deploy
```bash
terraform apply
```

### 5. Test UDP Gateway
```bash
# Get connection info from outputs
terraform output connection_info

# Test UDP connection (replace with actual values from output)
echo "test packet" | nc -u your-domain.proxylity.com 12345
```

### 6. Cleanup
```bash
terraform destroy
```

## Testing Multi-Region Example

### 1. Navigate to Multi-Region Example
```bash
cd examples/multi-region
```

### 2. Configure Multiple Regions
Ensure AWS credentials work in all three regions:
```bash
# Test access to all regions
aws sts get-caller-identity --region us-west-2
aws sts get-caller-identity --region us-east-1
aws sts get-caller-identity --region eu-west-1
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review the Plan
```bash
terraform plan
```

### 5. Deploy Infrastructure
```bash
# Deploy all resources
terraform apply

# Or deploy incrementally
terraform apply -target=module.udp_gateway
terraform apply -target=module.regional_infrastructure
```

### 6. Verify Regional Resources
```bash
# Check outputs
terraform output regional_buckets
terraform output regional_routing

# Verify S3 buckets exist
aws s3 ls | grep proxylity-udp-data

# Check IAM role
aws iam get-role --role-name $(terraform output -raw iam_role | jq -r '.name')
```

### 7. Test Regional Routing
```bash
# Get UDP endpoint
ENDPOINT=$(terraform output -json connection_info | jq -r '.endpoint')

# Send test packets (they should route to different regional buckets based on source)
echo "test from us-west-2" | nc -u $ENDPOINT
```

### 8. Monitor S3 Storage
```bash
# Check for packet data in regional buckets
aws s3 ls s3://$(terraform output -json regional_buckets | jq -r '."us-west-2".name')
aws s3 ls s3://$(terraform output -json regional_buckets | jq -r '."us-east-1".name')
aws s3 ls s3://$(terraform output -json regional_buckets | jq -r '."eu-west-1".name')
```

### 9. Cleanup
```bash
# Remove all resources
terraform destroy

# Or remove incrementally
terraform destroy -target=module.regional_infrastructure
terraform destroy -target=module.udp_gateway
```

## Troubleshooting

### Common Issues

#### 1. Proxylity Configuration Access
```bash
# Error: "Access denied to s3://proxylity-config-..."
# Solution: Ensure your AWS account is set up with Proxylity

# Check if configuration bucket is accessible
aws s3 ls s3://proxylity-config-us-west-2/$(aws sts get-caller-identity --query Account --output text)/
```

#### 2. IAM Permission Errors
```bash
# Error: "User: ... is not authorized to perform: iam:CreateRole"
# Solution: Ensure your AWS user/role has IAM permissions

# Required IAM permissions:
# - iam:CreateRole
# - iam:AttachRolePolicy
# - iam:PutRolePolicy
# - cloudformation:CreateStack
# - s3:CreateBucket
```

#### 3. CloudFormation Stack Failures
```bash
# Check CloudFormation events
aws cloudformation describe-stack-events --stack-name proxylity-s3-role-XXXX

# Check stack status
aws cloudformation describe-stacks --stack-name proxylity-s3-role-XXXX
```

#### 4. Module Not Found
```bash
# Error: "Module not found"
# Solution: Ensure you're in the correct directory

pwd  # Should be in examples/simple or examples/multi-region
ls   # Should see main.tf, variables.tf, etc.
```

## Validation Scripts

### Simple Validation
```bash
#!/bin/bash
cd examples/simple
terraform init -upgrade
terraform validate
terraform plan -out=tfplan
echo "Simple example validation: PASSED"
```

### Multi-Region Validation
```bash
#!/bin/bash
cd examples/multi-region
terraform init -upgrade
terraform validate
terraform plan -out=tfplan
echo "Multi-region example validation: PASSED"
```

### Full Test Suite
```bash
#!/bin/bash
echo "=== Testing Proxylity Terraform Module ==="

# Test simple example
echo "Testing simple example..."
cd examples/simple
terraform init -upgrade
terraform validate
terraform plan -detailed-exitcode

# Test multi-region example
echo "Testing multi-region example..."
cd ../multi-region
terraform init -upgrade
terraform validate
terraform plan -detailed-exitcode

echo "=== All tests completed ==="
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: Test Terraform Module
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Test Simple Example
        run: |
          cd examples/simple
          terraform init
          terraform validate
          terraform plan
      
      - name: Test Multi-Region Example
        run: |
          cd examples/multi-region
          terraform init
          terraform validate
          terraform plan
```

## Cost Considerations

### Simple Example
- CloudFormation stacks: Free
- S3 buckets: ~$0.023/month per bucket
- Proxylity UDP Gateway: Per usage pricing

### Multi-Region Example
- 3 S3 buckets across regions: ~$0.069/month
- IAM role: Free
- Data transfer: Variable based on usage

Remember to run `terraform destroy` after testing to avoid unnecessary charges!