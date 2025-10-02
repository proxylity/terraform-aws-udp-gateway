# Proxylity Listener Resource
resource "aws_cloudformation_stack" "proxylity_listener" {
  name = var.listener_name

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
      ProxylityListener = {
        Type = "Custom::ProxylityUdpGatewayListener"
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
          ListenerName = var.listener_name
          Protocols = var.protocols
          ClientRestrictions = {
            Networks = var.client_restrictions.networks
            Domains  = var.client_restrictions.domains
          }
          Destinations = [
            for dest in var.destinations : merge(
              {
                Name            = dest.name
                Description     = dest.description
                DestinationArn  = dest.destination_arn
                Role            = dest.role != null ? {
                  Arn = dest.role.role_arn
                } : null
                MetricsEnabled  = dest.metrics_enabled
                Formatter       = dest.formatter
              },
              dest.batching != null ? {
                Batching = merge(
                  {},
                  dest.batching.count != null ? { Count = dest.batching.count } : {},
                  dest.batching.timeout_in_seconds != null ? { TimeoutInSeconds = dest.batching.timeout_in_seconds } : {},
                  dest.batching.size_in_mb != null ? { SizeInMb = dest.batching.size_in_mb } : {}
                )
              } : {}
            )
          ]
        }
      }
    }
    
    Outputs = {
      ListenerName = {
        Value = { "Fn::GetAtt" = ["ProxylityListener", "Id"] }
      }
      Port = {
        Value = { "Fn::GetAtt" = ["ProxylityListener", "Port"] }
      }
      Domain = {
        Value = { "Fn::GetAtt" = ["ProxylityListener", "Domain"] }
      }
      DestinationNames = {
        Value = { "Fn::Join": [ ",", { "Fn::GetAtt" = ["ProxylityListener", "DestinationNames"] } ] }
      }
    }
  })

  capabilities = ["CAPABILITY_AUTO_EXPAND"]
  tags         = var.tags
}

