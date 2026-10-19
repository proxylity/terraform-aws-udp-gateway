provider "aws" {
  region = "us-west-2"
}

variable "client_cidr" {
  description = "Allowed outer-client public source CIDR, not the WireGuard inner address."
  type        = string
}

variable "destination_name" {
  description = "Existing destination to share among the listeners. Create it before using this example."
  type        = string
}

variable "peer_public_key" {
  description = "Base64-encoded 32-byte WireGuard client public key."
  type        = string
}

variable "dtls_psks" {
  description = "DTLS identity => pre-shared key. Supply through a protected variable source."
  type        = map(string)
  sensitive   = true
}

module "wireguard" {
  source = "../.."

  stack_name          = "example-wireguard"
  protocol            = "wg"
  client_restrictions = { networks = [var.client_cidr] }
  destination_names   = [var.destination_name]
  wireguard = {
    decapsulated_delivery = true
    peers = [{
      public_key  = var.peer_public_key
      allowed_ips = ["10.0.0.2/32"]
    }]
  }
}

module "dtls" {
  source = "../.."

  stack_name          = "example-dtls"
  protocol            = "dtls"
  client_restrictions = { networks = [var.client_cidr] }
  destination_names   = [var.destination_name]
  dtls = {
    psks            = var.dtls_psks
    require_cookies = true
  }
}

module "webrtc" {
  source = "../.."

  stack_name          = "example-webrtc"
  protocol            = "webrtc"
  client_restrictions = { networks = [var.client_cidr] }
  destination_names   = [var.destination_name]
  webrtc = {
    signaling_mode = "public"
  }
}

output "wireguard" {
  description = "WireGuard endpoint and server public key."
  value       = { endpoint = module.wireguard.endpoint, public_key = module.wireguard.wireguard_public_key }
}

output "dtls" {
  description = "DTLS endpoint and server certificate."
  value       = { endpoint = module.dtls.endpoint, certificate = module.dtls.dtls_server_certificate }
}

output "webrtc" {
  description = "WebRTC endpoint and connection metadata."
  value       = { endpoint = module.webrtc.endpoint, connection = module.webrtc.webrtc }
}

output "webrtc_signaling_token" {
  description = "Bearer token. Distribute only to authorized clients."
  value       = module.webrtc.webrtc_signaling_token
  sensitive   = true
}

output "webrtc_signaling_url" {
  description = "Public signaling URL."
  value       = module.webrtc.webrtc_signaling_url
  sensitive   = true
}
