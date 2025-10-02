locals {
  ingress_region_key = var.ingress_region_key != null ? var.ingress_region_key : { "Ref" = "AWS::Region" }
}

resource "aws_cloudformation_stack" "proxylity_destination_arn" {
  name = "${var.destination_name}-arn"

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
      ProxylityDestinationArn = {
        Type = "Custom::ProxylityUdpGatewayDestinationArn"
        Properties = {
          ServiceToken = { 
            "Fn::FindInMap" = [
              "ProxylityConfig",
              { "Ref" = "AWS::Region" },
              "ServiceToken"
            ]
          }
          ApiKey = { 
            "Fn::FindInMap" = [
              "ProxylityConfig",
              "Account",
              "ApiKey"
            ]
          }
          Destination = var.destination_name
          IngressRegionKey = local.ingress_region_key
          Arn = var.destination_arn
        }
      }
    }
  })

  capabilities = ["CAPABILITY_AUTO_EXPAND"]
  tags         = var.tags
}