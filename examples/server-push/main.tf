provider "aws" {
  region = "us-west-2"
}

variable "listener_name" {
  description = "ID of an existing listener in this region, not its display name."
  type        = string
}

variable "service_role_arn" {
  description = "Regional ServiceRole from your Proxylity customer-config.json."
  type        = string
}

resource "aws_sns_topic" "push" {
  name_prefix = "proxylity-push-"
}

resource "aws_iam_role" "subscribe" {
  name_prefix = "proxylity-subscribe-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.service_role_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "subscribe" {
  role = aws_iam_role.subscribe.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Subscribe", "sns:Unsubscribe", "sns:ListSubscriptionsByTopic"]
      Resource = aws_sns_topic.push.arn
    }]
  })
}

module "packet_source" {
  source = "../../modules/proxylity_packet_source"

  stack_name    = "example-packet-source"
  listener_name = var.listener_name
  sns_topic_source = {
    topic_arn = aws_sns_topic.push.arn
    role_arn  = aws_iam_role.subscribe.arn
  }

  depends_on = [aws_iam_role_policy.subscribe]
}

output "topic_arn" {
  description = "Publish correctly formatted Proxylity push messages to this topic."
  value       = aws_sns_topic.push.arn
}

output "packet_source_id" {
  description = "Created packet-source ID."
  value       = module.packet_source.packet_source_id
}
