output "stack_name" {
  description = "CloudFormation stack name."
  value       = aws_cloudformation_stack.proxylity_listener.name
}

output "stack_id" {
  description = "CloudFormation stack ID."
  value       = aws_cloudformation_stack.proxylity_listener.id
}

output "listener_name" {
  description = "Service listener ID, not the display name."
  value       = aws_cloudformation_stack.proxylity_listener.outputs.ListenerName
}

output "port" {
  description = "Allocated listener port as a number."
  value       = tonumber(aws_cloudformation_stack.proxylity_listener.outputs.Port)
}

output "domain" {
  description = "Listener subdomain, without .proxylity.com."
  value       = aws_cloudformation_stack.proxylity_listener.outputs.Domain
}

output "hostname" {
  description = "Fully qualified listener hostname."
  value       = "${aws_cloudformation_stack.proxylity_listener.outputs.Domain}.proxylity.com"
}

output "endpoint" {
  description = "Listener hostname:port."
  value       = "${aws_cloudformation_stack.proxylity_listener.outputs.Domain}.proxylity.com:${aws_cloudformation_stack.proxylity_listener.outputs.Port}"
}

output "destination_names" {
  description = "Destination names as a list (empty when there are no destinations)."
  value       = compact(split(",", aws_cloudformation_stack.proxylity_listener.outputs.DestinationNames))
}

output "wireguard_public_key" {
  description = "WireGuard server public key, or null for other protocols."
  value       = var.protocol == "wg" ? aws_cloudformation_stack.proxylity_listener.outputs.WireGuardPublicKey : null
}

output "dtls_server_certificate" {
  description = "DTLS/WebRTC server PEM certificate, or null for other protocols."
  value       = contains(["dtls", "webrtc"], var.protocol) ? aws_cloudformation_stack.proxylity_listener.outputs.DtlsServerCertificate : null
}

output "webrtc" {
  description = "WebRTC connection metadata, or null for other protocols."
  value = var.protocol == "webrtc" ? {
    fingerprint    = aws_cloudformation_stack.proxylity_listener.outputs.WebRtcFingerprint
    sctp_port      = tonumber(aws_cloudformation_stack.proxylity_listener.outputs.WebRtcSctpPort)
    channel_id     = tonumber(aws_cloudformation_stack.proxylity_listener.outputs.WebRtcChannelId)
    signaling_mode = aws_cloudformation_stack.proxylity_listener.outputs.WebRtcSignalingMode
  } : null
}

output "webrtc_signaling_token" {
  description = "Public signaling bearer token, or null unless public signaling is enabled."
  value       = local.public_signaling ? aws_cloudformation_stack.proxylity_listener.outputs.WebRtcSignalingToken : null
  sensitive   = true
}

output "webrtc_signaling_url" {
  description = "Public signaling URL, or null unless public signaling is enabled."
  value       = local.public_signaling ? aws_cloudformation_stack.proxylity_listener.outputs.WebRtcSignalingUrl : null
  sensitive   = true
}
