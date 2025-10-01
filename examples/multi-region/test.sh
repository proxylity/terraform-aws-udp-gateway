#!/bin/bash
# Quick test script for multi-region example

set -e

echo "=== Testing Multi-Region Proxylity Example ==="

# Check if we're in the right directory
if [[ ! -f "main.tf" ]]; then
    echo "Error: main.tf not found. Run this script from examples/multi-region directory."
    exit 1
fi

echo "1. Checking AWS access to all regions..."
aws sts get-caller-identity --region us-west-2 > /dev/null
aws sts get-caller-identity --region us-east-1 > /dev/null  
aws sts get-caller-identity --region eu-west-1 > /dev/null
echo "   ✅ All regions accessible"

echo "2. Initializing Terraform..."
terraform init -upgrade

echo "3. Validating configuration..."
terraform validate

echo "4. Formatting check..."
terraform fmt -check

echo "5. Creating plan..."
terraform plan -out=tfplan

echo "6. Showing plan summary..."
terraform show -json tfplan | jq '.planned_values.root_module | {
  resources: (.resources | length),
  child_modules: (.child_modules | length)
}'

echo "✅ Multi-region example validation completed successfully!"
echo ""
echo "To deploy:"
echo "  terraform apply tfplan"
echo ""
echo "To test regional routing:"
echo "  ENDPOINT=\$(terraform output -raw connection_info | jq -r '.endpoint')"
echo "  echo 'test packet' | nc -u \$ENDPOINT"
echo ""
echo "To cleanup:"
echo "  terraform destroy"