resource "terraform_data" "destination" {
  triggers_replace = [var.destination_name]
}

resource "aws_cloudformation_stack" "proxylity_destination_arn" {
  name = var.stack_name

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
          Destination      = var.destination_name
          IngressRegionKey = jsondecode(var.ingress_region_key != null ? jsonencode(var.ingress_region_key) : jsonencode({ Ref = "AWS::Region" }))
          Arn              = var.destination_arn
        }

      }
    }

    Outputs = {
      Destination      = { Value = { "Fn::GetAtt" = ["ProxylityDestinationArn", "Destination"] } }
      IngressRegionKey = { Value = { "Fn::GetAtt" = ["ProxylityDestinationArn", "IngressRegionKey"] } }
      Arn              = { Value = { "Fn::GetAtt" = ["ProxylityDestinationArn", "Arn"] } }
    }
  })

  capabilities = ["CAPABILITY_AUTO_EXPAND"]
  tags         = var.tags

  lifecycle {
    replace_triggered_by = [terraform_data.destination]
  }
}