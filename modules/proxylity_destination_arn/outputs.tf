output "stack_name" {
  description = "The name of the CloudFormation stack for the destination ARN binding"
  value       = aws_cloudformation_stack.proxylity_destination_arn.name
}

output "stack_id" {
  description = "The ID of the CloudFormation stack for the destination ARN binding"
  value       = aws_cloudformation_stack.proxylity_destination_arn.id
}

output "destination_name" {
  description = "The name of the destination this ARN is bound to"
  value       = var.destination_name
}

output "destination_arn" {
  description = "The AWS ARN bound to this destination"
  value       = var.destination_arn
}

output "ingress_region_key" {
  description = "The ingress region key used for this destination"
  value       = var.ingress_region_key
}