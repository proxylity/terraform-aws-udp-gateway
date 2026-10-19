mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = { outputs = { PacketSourceId = "source-123" } }
  }
}

variables {
  stack_name    = "test-packet-source"
  listener_name = "listener-123"
  sns_topic_source = {
    topic_arn = "arn:aws:sns:us-west-2:123456789012:push"
    role_arn  = "arn:aws:iam::123456789012:role/subscribe"
  }
}

run "sns_source" {
  command = apply
  assert {
    condition = jsondecode(aws_cloudformation_stack.proxylity_packet_source.template_body).Resources.ProxylityPacketSource.Properties.SnsTopicSource == {
      TopicArn = "arn:aws:sns:us-west-2:123456789012:push"
      Role     = "arn:aws:iam::123456789012:role/subscribe"
    }
    error_message = "Packet sources require SnsTopicSource.Role as a bare string, not { Arn }."
  }
  assert {
    condition = (
      output.packet_source_id == "source-123" &&
      !contains(keys(jsondecode(aws_cloudformation_stack.proxylity_packet_source.template_body).Resources.ProxylityPacketSource.Properties), "Description")
    )
    error_message = "The physical ID must use Ref and absent descriptions must be omitted."
  }
}

run "listener_change_replaces_stack" {
  command = apply
  variables { listener_name = "listener-456" }
  assert {
    condition     = output.stack_id != run.sns_source.stack_id
    error_message = "An immutable listener change must trigger stack replacement."
  }
}

run "invalid_source" {
  command = plan
  variables {
    sns_topic_source = { topic_arn = "arn:aws:sqs:us-west-2:123456789012:queue", role_arn = "not-a-role" }
  }
  expect_failures = [var.sns_topic_source]
}
