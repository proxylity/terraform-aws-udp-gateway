#!/bin/bash
# Quick test script for simple example

set -e

echo "=== Testing Simple Proxylity Example ==="

# Check if we're in the right directory
if [[ ! -f "main.tf" ]]; then
    echo "Error: main.tf not found. Run this script from examples/simple directory."
    exit 1
fi

echo "1. Initializing Terraform..."
terraform init -upgrade

echo "2. Validating configuration..."
terraform validate

echo "3. Formatting check..."
terraform fmt -check

echo "4. Creating plan..."
terraform plan -out=tfplan

echo "5. Showing plan summary..."
terraform show -json tfplan | jq '.planned_values.root_module.resources | length'

echo "✅ Simple example validation completed successfully!"
echo ""
echo "To deploy:"
echo "  terraform apply tfplan"
echo ""
echo "To cleanup:"
echo "  terraform destroy"