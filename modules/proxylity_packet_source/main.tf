resource "terraform_data" "listener" {
  triggers_replace = [var.listener_name]
}

resource "aws_cloudformation_stack" "proxylity_packet_source" {
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
      ProxylityPacketSource = {
        Type = "Custom::ProxylityUdpGatewayPacketSource"
        Properties = merge({
          ServiceToken = { "Fn::FindInMap" = ["ProxylityConfig", { Ref = "AWS::Region" }, "ServiceToken"] }
          ApiKey       = { "Fn::FindInMap" = ["ProxylityConfig", "Account", "ApiKey"] }
          ListenerName = var.listener_name
          SnsTopicSource = {
            TopicArn = var.sns_topic_source.topic_arn
            Role     = var.sns_topic_source.role_arn
          }
        }, var.description == null ? {} : { Description = var.description })
      }
    }
    Outputs = {
      PacketSourceId = { Value = { Ref = "ProxylityPacketSource" } }
    }
  })

  capabilities = ["CAPABILITY_AUTO_EXPAND"]
  tags         = var.tags

  lifecycle {
    replace_triggered_by = [terraform_data.listener]
  }
}
