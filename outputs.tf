output "listener_name" {
  description = "Name of the created listener"
  value       = aws_cloudformation_stack.proxylity_listener.outputs.ListenerName
}

output "port" {
  description = "Port assigned to the listener"
  value       = aws_cloudformation_stack.proxylity_listener.outputs.Port
}

output "domain" {
  description = "Domain assigned to the listener"
  value       = aws_cloudformation_stack.proxylity_listener.outputs.Domain
}

output "destination_names" {
  description = "List of destination names from the listener"
  value       = aws_cloudformation_stack.proxylity_listener.outputs.DestinationNames
}