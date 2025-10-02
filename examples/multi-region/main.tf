# Configure AWS providers for multiple regions
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# Random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  suffix = random_id.suffix.hex
  
  # Common tags
  common_tags = {
    Project     = "proxylity-udp-gateway"
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

# IAM role for Proxylity to access S3 buckets (created via CloudFormation)
resource "aws_cloudformation_stack" "proxylity_s3_role" {
  provider = aws.us_west_2
  name     = "proxylity-s3-role-${local.suffix}"

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    
    Mappings = {
      ProxylityConfig = {
        "Fn::Transform" = {
          Name = "AWS::Include"
          Parameters = {
            Location = {
              "Fn::Sub" = "s3://proxylity-config-$${AWS::Region}/$${AWS::AccountId}/customer-config.json"
            }
          }
        }
      }
    }
    
    Resources = {
      ProxylityS3Role = {
        Type = "AWS::IAM::Role"
        Properties = {
          RoleName = "proxylity-s3-role-${local.suffix}"
          AssumeRolePolicyDocument = {
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Principal = {
                  AWS = {
                    "Fn::FindInMap" = [
                      "ProxylityConfig",
                      { "Ref" = "AWS::Region" },
                      "ServiceRole"
                    ]
                  }
                }
                Action = "sts:AssumeRole"
              }
            ]
          }
        }
      }
    }
    
    Outputs = {
      RoleArn = {
        Value = { "Fn::GetAtt" = ["ProxylityS3Role", "Arn"] }
      }
      RoleName = {
        Value = { "Ref" = "ProxylityS3Role" }
      }
    }
  })

  capabilities = ["CAPABILITY_AUTO_EXPAND", "CAPABILITY_NAMED_IAM"]
  tags         = local.common_tags
}

# Create UDP Gateway Listener with destination names only (no ARNs)
module "udp_gateway" {
  source = "../../"

  providers = {
    aws = aws.us_west_2
  }

  listener_name = "multi-region-gateway-${local.suffix}"
  protocols     = ["udp"]
  # client_restrictions uses default values (open to all networks)

  # Define destinations with names only - ARNs will be bound separately per region
  destinations = [
    {
      name        = "regional-s3-storage"
      description = "Multi-region S3 storage for UDP packet data"
      # No destination_arn specified - will be populated by destination_arn modules
      batching = {
        count              = 100
        timeout_in_seconds = 5.0
        size_in_mb        = 5
      }
      metrics_enabled = true
      formatter      = "base64"
    }
  ]

  tags = local.common_tags
}

# Regional S3 buckets and destination ARN bindings
module "regional_infrastructure" {
  for_each = {
    "us-west-2" = "us_west_2"
    "us-east-1" = "us_east_1"
    "eu-west-1" = "eu_west_1"
  }

  source = "./modules/regional-destination"

  providers = {
    aws = aws[each.value]
  }

  region                = each.key
  suffix               = local.suffix
  destination_name     = "regional-s3-storage"  # Must match destination in listener
  global_role_arn      = aws_cloudformation_stack.proxylity_s3_role.outputs["RoleArn"]
  
  tags = local.common_tags

  depends_on = [module.udp_gateway]
}