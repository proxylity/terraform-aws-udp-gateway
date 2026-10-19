output "stack_name" {
  description = "CloudFormation stack name."
  value       = aws_cloudformation_stack.proxylity_packet_source.name
}

output "stack_id" {
  description = "CloudFormation stack ID."
  value       = aws_cloudformation_stack.proxylity_packet_source.id
}

output "packet_source_id" {
  description = "Physical packet-source ID."
  value       = aws_cloudformation_stack.proxylity_packet_source.outputs.PacketSourceId
}
