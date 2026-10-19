provider "aws" {
  region = var.region
}

variable "region" {
  description = "Region with an active Proxylity subscription."
  type        = string
  default     = "us-west-2"
}

variable "service_role_arn" {
  description = "Regional ServiceRole from your Proxylity customer-config.json. This is the trusted principal, not the destination role."
  type        = string
}

variable "client_cidr" {
  description = "Public source CIDR allowed to send packets. Use your public IP with /32."
  type        = string
}

resource "aws_sqs_queue" "packets" {
  name_prefix = "proxylity-packets-"
}

resource "aws_iam_role" "delivery" {
  name_prefix = "proxylity-delivery-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.service_role_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "delivery" {
  role = aws_iam_role.delivery.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = aws_sqs_queue.packets.arn
    }]
  })
}

module "udp" {
  source = "../.."

  stack_name          = "example-listener"
  listener_name       = "Example UDP listener"
  client_restrictions = { networks = [var.client_cidr] }
  destinations = {
    example-sqs-packets = {
      destination_arn = aws_sqs_queue.packets.arn
      role            = { arn = aws_iam_role.delivery.arn }
      formatter       = "base64"
      batching        = { count = 10, timeout_in_seconds = 0.25 }
      arguments       = { send_raw = false, use_message_attributes = true }
    }
  }

  depends_on = [aws_iam_role_policy.delivery]
}

output "endpoint" {
  description = "Send UDP packets to this hostname:port."
  value       = module.udp.endpoint
}

output "queue_url" {
  description = "Receive delivered packets with aws sqs receive-message --queue-url."
  value       = aws_sqs_queue.packets.url
}
