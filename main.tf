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
          ClientRestrictions = var.client_restrictions
          Destinations = [
            for dest in var.destinations : {
              Name            = dest.name
              Description     = dest.description
              DestinationArn  = dest.destination_arn
              Role            = dest.role
              Batching        = dest.batching
              MetricsEnabled  = dest.metrics_enabled
              Formatter       = dest.formatter
            }
          ]
        }
      }
    }
    
    Outputs = {
      ListenerName = {
        Value = { Ref = "ProxylityListener" }
      }
      Port = {
        Value = { "Fn::GetAtt" = ["ProxylityListener", "Port"] }
      }
      Domain = {
        Value = { "Fn::GetAtt" = ["ProxylityListener", "Domain"] }
      }
      DestinationNames = {
        Value = { "Fn::GetAtt" = ["ProxylityListener", "DestinationNames"] }
      }
    }
  })

  tags = var.tags
}

