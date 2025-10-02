# Proxylity Terraform Provider

This Terraform module provides resources for managing Proxylity UDP Gateway listeners and destination ARNs through CloudFormation custom resources.

## Version

Current version: **1.0.0**

## Installation

### Using Terraform Registry (Recommended)

```hcl
module "proxylity_listener" {
  source  = "proxylity/udp-gateway/aws"
  version = "~> 1.0"
  
  listener_name = "my-udp-gateway"
  protocols = ["udp"]
  # ... other configuration
}
```

### Using Git Tags

```hcl
module "proxylity_listener" {
  source = "git::https://github.com/proxylity/terraform-aws-udp-gateway.git?ref=v1.0.0"
  
  listener_name = "my-udp-gateway"
  protocols = ["udp"]
  # ... other configuration
}
```

### Using Local Path (Development)

```hcl
module "proxylity_listener" {
  source = "./path/to/proxylity-terraform-provider"
  
  listener_name = "my-udp-gateway"
  protocols = ["udp"]
  # ... other configuration
}
```

## Resources

- **Proxylity Listener** (`proxylity_listener`): Creates a UDP gateway listener with destinations
- **Proxylity Destination ARN** (`proxylity_destination_arn`): Binds AWS ARNs to destination names for existing listeners

## Module Structure

- Root module: Creates Proxylity listeners
- `modules/proxylity_destination_arn/`: Standalone module for binding destination ARNs

## Configuration Requirements

**IMPORTANT**: This module uses Proxylity's S3-based configuration system. Ensure that:

1. **S3 Configuration Access**: Your AWS account has access to the Proxylity configuration bucket:
   - `s3://proxylity-config-${AWS::Region}/${AWS::AccountId}/customer-config.json`

2. **IAM Permissions**: Your Terraform execution role has the necessary permissions to:
   - Read from the Proxylity S3 configuration bucket
   - Create and manage CloudFormation stacks
   - Access the Proxylity Lambda service tokens

3. **Region Support**: Ensure Proxylity is available in your target AWS region

The module automatically retrieves ServiceToken and ApiKey values from the region and account-specific S3 configuration maintained by Proxylity.

## Usage

### Basic Listener Creation

```hcl
module "proxylity_listener" {
  source = "./path/to/proxylity-terraform-provider"
  
  listener_name = "my-udp-gateway"
  protocols = ["udp"]
  client_restrictions = []
  
  # Inline destination declarations
  destinations = [
    {
      name = "lambda-destination"
      description = "Lambda function for packet processing"
      destination_arn = "arn:aws:lambda:us-west-2:123456789012:function:packet-handler"
      role = {
        role_arn = "arn:aws:iam::123456789012:role/ProxylityLambdaRole"
      }
      batching = {
        count = 10
        timeout_in_seconds = 5.0
      }
      metrics_enabled = true
      formatter = "base64"
    },
    {
      name = "multi-region-sns"
      description = "Multi-region SNS destinations"
      destination_arn = {
        "us-east-1" = "arn:aws:sns:us-east-1:123456789012:notifications"
        "us-west-2" = "arn:aws:sns:us-west-2:123456789012:notifications"
        "eu-west-1" = "arn:aws:sns:eu-west-1:123456789012:notifications"
      }
      role = {
        role_arn = "arn:aws:iam::123456789012:role/ProxylitySnsRole"
      }
      formatter = "utf8"
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Binding Destination ARNs

```hcl
# Create the listener first
module "proxylity_listener" {
  source = "./path/to/proxylity-terraform-provider"
  
  listener_name = "my-udp-gateway"
  protocols = ["udp"]
  # client_restrictions uses default (open to all)
  
  # Declare destinations that will later have ARNs bound to them
  destinations = [
    {
      name = "lambda-destination"
      type = "passthrough"
    }
  ]
}

# Then bind ARNs to destination names
module "destination_arn_binding" {
  source = "./path/to/proxylity-terraform-provider/modules/proxylity_destination_arn"
  
  destination_name = "lambda-destination"
  destination_arn = aws_lambda_function.my_function.arn
  # ingress_region_key = "*"  # Optional: use "*" for all regions
  
  tags = {
    Environment = "production"
  }
}
```

## Variables

### Root Module Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `listener_name` | Name of the Proxylity listener | `string` | n/a | yes |
| `protocols` | List of protocols for the listener | `list(string)` | `["udp"]` | no |
| `client_restrictions` | Client restrictions with networks and domains | `object({networks = list(string), domains = list(string)})` | `{networks = ["0.0.0.0/0", "::/0"], domains = []}` | no |
| `destinations` | List of destination configurations with ARNs, roles, batching, etc. | `list(object({...}))` | `[]` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

### Destination ARN Module Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `destination_name` | Name of the destination to bind the ARN to | `string` | n/a | yes |
| `destination_arn` | ARN of the AWS resource to bind | `string` | n/a | yes |
| `ingress_region_key` | Region key for ingress configuration. Use "*" for all regions. | `string` | current region | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

### Root Module Outputs

| Name | Description |
|------|-------------|
| `listener_name` | The name of the created listener |
| `port` | The port assigned to the listener |
| `domain` | The domain assigned to the listener |
| `destination_names` | List of destination names configured for the listener |

## Architecture Notes

- **Destinations vs Destination ARNs**: Destinations are declared inline with listeners during listener creation. The `proxylity_destination_arn` module is used separately to bind AWS ARNs to existing destination names.
- **Resource Naming**: The CloudFormation custom resource types are:
  - `Custom::ProxylityUdpGatewayListener` for listeners
  - `Custom::ProxylityUdpGatewayDestinationArn` for destination ARN bindings

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Examples

See the `examples/` directory for complete usage examples:

- **`examples/simple/`**: Basic UDP Gateway with inline destinations
- **`examples/multi-region/`**: Multi-region S3 destinations with optimal routing

## Versioning

This module follows [Semantic Versioning](https://semver.org/).

### Terraform Registry Version Constraints

```hcl
# Recommended for production
module "proxylity_listener" {
  source  = "proxylity/udp-gateway/aws"
  version = "1.0.0"  # Exact version
}

# Allow patch updates (recommended)
module "proxylity_listener" {
  source  = "proxylity/udp-gateway/aws"
  version = "~> 1.0.0"  # >= 1.0.0, < 1.1.0
}

# Allow minor updates (use with caution)
module "proxylity_listener" {
  source  = "proxylity/udp-gateway/aws"
  version = "~> 1.0"    # >= 1.0.0, < 2.0.0
}
```

### Git Tag Version Constraints

- **Pin to specific version**: `?ref=v1.0.0` (recommended for production)
- **Allow patch updates**: `?ref=v1.0` (gets latest v1.0.x)
- **Allow minor updates**: `?ref=v1` (gets latest v1.x.x)

### Upgrade Guidelines

- **Patch releases** (1.0.x): Safe to upgrade, bug fixes only
- **Minor releases** (1.x.0): New features, backward compatible
- **Major releases** (x.0.0): Breaking changes, review CHANGELOG.md

See [CHANGELOG.md](./CHANGELOG.md) for detailed release notes.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development and release guidelines.

## License

This module is licensed under the MIT License.

