# Multi-region S3 delivery

Creates a UDP listener, a shared destination role trusting all three regional
Proxylity ServiceRole principals, and encrypted/versioned S3 buckets in
`us-west-2`, `us-east-1` and `eu-west-1`.

Each bucket has a separate destination ARN registration. Provider aliases are
passed statically: Terraform does not support dynamic `aws[each.value]` selection.
IAM policies are installed before registering each ARN, and registrations depend
on the actual listener's destination output.

```sh
terraform init
terraform plan -var='client_cidr=192.0.2.10/32' -out=tfplan
terraform apply tfplan
terraform output -json connection_info
terraform output -json regional_routing
```

Replace the documentation CIDR with your public source CIDR. The subscription and
customer configuration must support all three regions. Traffic is mapped by
ingress region; this example does not register a fallback for other regions.

Resources incur charges. After verifying delivery, empty all bucket versions and
delete markers before `terraform destroy`. Buckets deliberately do not enable
force-destroy. See [TESTING.md](../../TESTING.md) for live verification.
