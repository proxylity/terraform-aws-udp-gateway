# Proxylity Destination ARN Module

This module binds AWS resource ARNs to existing Proxylity UDP Gateway destination names. It is designed to be used after a Proxylity listener has been created with named destinations that need to be associated with specific AWS resources.

## Use Case

When you create a Proxylity UDP Gateway listener, you can declare destinations by name without specifying the actual AWS resource ARNs. This module allows you to bind those destination names to specific AWS resource ARNs after the resources are created, enabling dynamic ARN association and multi-region deployments.

## Usage

```hcl
# First, create a listener with named destinations
module "proxylity_listener" {
  source = "proxylity/udp-gateway/aws"
  
  listener_name = "my-gateway"
  destinations = [
    {
      name = "s3-storage"
      description = "S3 bucket for data storage"
      # No destination_arn specified - will be bound separately
    }
  ]
}

# Then bind the ARN to the destination name
module "s3_destination_binding" {
  source = "proxylity/udp-gateway/aws//modules/proxylity_destination_arn"
  
  destination_name = "s3-storage"
  destination_arn  = aws_s3_bucket.my_bucket.arn
  
  # Optional: specify region key for multi-region setups
  ingress_region_key = "us-west-2"
  
  tags = {
    Environment = "production"
  }
}
```

## Multi-Region Example

```hcl
# Bind different ARNs per region
module "destination_us_west_2" {
  source = "proxylity/udp-gateway/aws//modules/proxylity_destination_arn"
  
  destination_name   = "regional-storage"
  destination_arn    = aws_s3_bucket.us_west_2.arn
  ingress_region_key = "us-west-2"
}

module "destination_us_east_1" {
  source = "proxylity/udp-gateway/aws//modules/proxylity_destination_arn"
  
  destination_name   = "regional-storage"
  destination_arn    = aws_s3_bucket.us_east_1.arn
  ingress_region_key = "us-east-1"
}

# Or use wildcard for all regions
module "destination_global" {
  source = "proxylity/udp-gateway/aws//modules/proxylity_destination_arn"
  
  destination_name   = "global-destination"
  destination_arn    = aws_lambda_function.handler.arn
  ingress_region_key = "*"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `destination_name` | Name of the destination to bind the ARN to | `string` | n/a | yes |
| `destination_arn` | ARN of the AWS resource to bind | `string` | n/a | yes |
| `ingress_region_key` | Region key for ingress configuration. Use "*" for all regions. | `string` | current region | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `stack_name` | The CloudFormation stack name |
| `stack_id` | The CloudFormation stack ID |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## How It Works

This module creates a CloudFormation stack with a `Custom::ProxylityUdpGatewayDestinationArn` resource that:

1. Connects to the Proxylity service using configuration from S3
2. Binds the specified AWS resource ARN to the named destination
3. Configures regional routing if `ingress_region_key` is specified

The binding is persistent and will route UDP packets received by the named destination to the specified AWS resource ARN.

## Important Notes

- The destination name must already exist in a Proxylity listener
- The AWS resource ARN must be accessible from the Proxylity service
- Regional bindings allow for optimal routing in multi-region deployments
- Use `ingress_region_key = "*"` for global destinations that should receive traffic from all regions