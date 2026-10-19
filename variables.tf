variable "stack_name" {
  description = "CloudFormation stack name. Keep stable to avoid replacing the stack."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{0,127}$", var.stack_name))
    error_message = "stack_name must start with a letter and contain at most 128 letters, digits or hyphens."
  }
}

variable "listener_name" {
  description = "Optional display name (CloudFormation Name, not the listener ID). The service generates one when omitted."
  type        = string
  default     = null

  validation {
    condition     = var.listener_name == null ? true : can(regex("^[A-Za-z][A-Za-z0-9 _-]+$", var.listener_name))
    error_message = "listener_name must start with a letter and contain at least two letters, digits, spaces, underscores or hyphens."
  }
}

variable "description" {
  description = "Optional listener description."
  type        = string
  default     = null
}

variable "protocol" {
  description = "Exactly one listener protocol: udp, wg, dtls or webrtc."
  type        = string
  default     = "udp"
  nullable    = false

  validation {
    condition     = contains(["udp", "wg", "dtls", "webrtc"], var.protocol)
    error_message = "protocol must be udp, wg, dtls or webrtc."
  }
}

variable "client_restrictions" {
  description = "Allowed outer-client networks and domains. Empty by default: explicitly opt in to public access."
  type = object({
    networks = optional(list(string), [])
    domains  = optional(list(string), [])
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for cidr in var.client_restrictions.networks : can(cidrhost(cidr, 0))])
    error_message = "Every client network must be an IPv4 or IPv6 CIDR."
  }
}

variable "role" {
  description = "Listener metrics/log delivery role. Trust the regional Proxylity ServiceRole, not an AWS service principal. Duration is a .NET TimeSpan, e.g. 1:00:00."
  type = object({
    arn      = string
    duration = optional(string)
  })
  default = null
}

variable "metrics_enabled" {
  description = "Enable listener metrics. Supply an appropriate listener role."
  type        = bool
  default     = null
}

variable "log_group_name" {
  description = "Existing CloudWatch log group for listener logs. Supply an appropriate listener role."
  type        = string
  default     = null
}

variable "wireguard" {
  description = "WireGuard-only settings. Rotation tokens rotate server keys on update. Contains secrets; protect Terraform state."
  type = object({
    decapsulated_delivery       = optional(bool)
    allow_unknown_peers         = optional(bool)
    unknown_peer_pre_shared_key = optional(string)
    key_refresh_token           = optional(string)
    peers = optional(list(object({
      public_key    = string
      shared_secret = optional(string)
      allowed_ips   = optional(list(string))
    })), [])
  })
  default   = null
  sensitive = true

  validation {
    condition     = var.wireguard == null || var.protocol == "wg"
    error_message = "wireguard settings require protocol = \"wg\"."
  }

  validation {
    condition = var.wireguard == null ? true : (
      var.wireguard.unknown_peer_pre_shared_key == null || var.wireguard.allow_unknown_peers == true
    )
    error_message = "unknown_peer_pre_shared_key requires allow_unknown_peers = true."
  }

  validation {
    condition = var.wireguard == null ? true : alltrue(concat(
      [var.wireguard.unknown_peer_pre_shared_key == null ? true : can(regex("^[A-Za-z0-9+/]{43}=$", var.wireguard.unknown_peer_pre_shared_key))],
      [for peer in var.wireguard.peers : can(regex("^[A-Za-z0-9+/]{43}=$", peer.public_key)) && (peer.shared_secret == null ? true : can(regex("^[A-Za-z0-9+/]{43}=$", peer.shared_secret)))],
      [for peer in var.wireguard.peers : peer.allowed_ips == null ? true : alltrue([for cidr in peer.allowed_ips : can(cidrhost(cidr, 0))])]
    ))
    error_message = "WireGuard keys must be base64-encoded 32-byte keys and allowed_ips must contain valid CIDRs."
  }
}

variable "dtls" {
  description = "DTLS-only settings. PSKs must be non-empty strings. Contains secrets; protect Terraform state."
  type = object({
    psks                      = optional(map(string))
    server_secret             = optional(string)
    require_cookies           = optional(bool)
    allow_early_data          = optional(bool)
    early_data_window_seconds = optional(number)
    cert_refresh_token        = optional(string)
  })
  default   = null
  sensitive = true

  validation {
    condition     = var.dtls == null || var.protocol == "dtls"
    error_message = "dtls settings require protocol = \"dtls\"."
  }

  validation {
    condition = var.dtls == null ? true : (
      var.dtls.early_data_window_seconds == null ? true : (
        var.dtls.early_data_window_seconds >= 1 && var.dtls.early_data_window_seconds <= 604800 &&
        floor(var.dtls.early_data_window_seconds) == var.dtls.early_data_window_seconds
      )
    )
    error_message = "early_data_window_seconds must be an integer from 1 through 604800."
  }

  validation {
    condition = var.dtls == null ? true : (
      (var.dtls.server_secret == null ? true : can(regex("^[A-Za-z0-9+/]{43}=$", var.dtls.server_secret))) &&
      (var.dtls.psks == null ? true : alltrue([for value in values(var.dtls.psks) : value == null ? false : trimspace(value) != ""]))
    )
    error_message = "server_secret must be a base64-encoded 32-byte key; PSK values must be non-empty."
  }
}

variable "webrtc" {
  description = "WebRTC-only settings. Cookies are always required. Contains secrets; protect Terraform state."
  type = object({
    server_secret           = optional(string)
    require_cookies         = optional(bool)
    cert_refresh_token      = optional(string)
    signaling_mode          = optional(string, "none")
    signaling_refresh_token = optional(string)
  })
  default   = null
  sensitive = true

  validation {
    condition     = var.webrtc == null || var.protocol == "webrtc"
    error_message = "webrtc settings require protocol = \"webrtc\"."
  }

  validation {
    condition = var.webrtc == null ? true : (
      var.webrtc.require_cookies != false &&
      contains(["none", "public"], var.webrtc.signaling_mode) &&
      (var.webrtc.server_secret == null ? true : can(regex("^[A-Za-z0-9+/]{43}=$", var.webrtc.server_secret)))
    )
    error_message = "WebRTC requires cookies, signaling_mode must be none or public, and server_secret must be a base64-encoded 32-byte key."
  }
}

variable "destinations" {
  description = "Inline destinations keyed by unique service destination name. Use destination_arn OR destination_arns (region => ARN, '*' fallback). Omit both for later registration."
  type = map(object({
    description      = optional(string)
    destination_arn  = optional(string)
    destination_arns = optional(map(string))
    role = optional(object({
      arn      = string
      duration = optional(string)
    }))
    batching = optional(object({
      count              = optional(number)
      timeout_in_seconds = optional(number)
      size_in_mb         = optional(number)
    }))
    metrics_enabled   = optional(bool)
    formatter         = optional(string)
    filter_expression = optional(string)
    log_group_name    = optional(string)
    arguments = optional(object({
      dynamic_topic_suffix                = optional(bool)
      topic_suffix_expression             = optional(string)
      topic_suffix_formatter              = optional(string)
      tenant_id                           = optional(string)
      tenant_id_expression                = optional(string)
      tenant_id_formatter                 = optional(string)
      use_response_streaming              = optional(bool)
      use_async_invoke                    = optional(bool)
      send_raw                            = optional(bool)
      use_message_attributes              = optional(bool)
      message_group_id_expression         = optional(string)
      message_group_id_formatter          = optional(string)
      message_deduplication_id_expression = optional(string)
      message_deduplication_id_formatter  = optional(string)
      partition_key_expression            = optional(string)
      partition_key_expression_formatter  = optional(string)
      device_id_expression                = optional(string)
      latitude_expression                 = optional(string)
      longitude_expression                = optional(string)
      scale_factor                        = optional(number)
      accuracy_expression                 = optional(string)
      position_property_expressions       = optional(map(string))
      timestamp_expression                = optional(string)
      timestamp_time_unit                 = optional(string)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for dest in values(var.destinations) : !(dest.destination_arn != null && dest.destination_arns != null)])
    error_message = "Set destination_arn or destination_arns, not both."
  }

  validation {
    condition     = alltrue([for dest in values(var.destinations) : dest.formatter == null ? true : contains(["base64", "hex", "ascii", "utf8", "coap"], dest.formatter)])
    error_message = "formatter must be base64, hex, ascii, utf8 or coap."
  }

  validation {
    condition = alltrue([for dest in values(var.destinations) : dest.batching == null ? true : (
      (dest.batching.count == null ? true : dest.batching.count >= 1 && floor(dest.batching.count) == dest.batching.count) &&
      (dest.batching.timeout_in_seconds == null ? true : dest.batching.timeout_in_seconds > 0) &&
      (dest.batching.size_in_mb == null ? true : dest.batching.size_in_mb > 0)
    )])
    error_message = "Batch count must be a positive integer; timeout and size must be positive."
  }

  validation {
    condition = alltrue([for dest in values(var.destinations) : dest.arguments == null ? true : !(
      dest.arguments.use_response_streaming == true && dest.arguments.use_async_invoke == true
    )])
    error_message = "Lambda response streaming and async invocation are mutually exclusive."
  }

  validation {
    condition = alltrue(flatten([for dest in values(var.destinations) : dest.arguments == null ? [] : [
      for formatter in [
        dest.arguments.topic_suffix_formatter, dest.arguments.tenant_id_formatter,
        dest.arguments.message_group_id_formatter, dest.arguments.message_deduplication_id_formatter,
        dest.arguments.partition_key_expression_formatter
      ] : formatter == null ? true : contains(["base64", "hex", "ascii", "utf8"], formatter)
    ]]))
    error_message = "Argument formatters must be base64, hex, ascii or utf8."
  }

  validation {
    condition = alltrue([for dest in values(var.destinations) : dest.arguments == null ? true : (
      dest.arguments.timestamp_time_unit == null ? true : contains(["seconds", "milliseconds"], dest.arguments.timestamp_time_unit)
    )])
    error_message = "timestamp_time_unit must be seconds or milliseconds."
  }
}

variable "destination_names" {
  description = "Existing service destination names to reference without redefining them."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition     = length(setintersection(toset(keys(var.destinations)), var.destination_names)) == 0
    error_message = "Do not both define and reference the same destination."
  }
}

variable "tags" {
  description = "Tags applied to the CloudFormation stack."
  type        = map(string)
  default     = {}
  nullable    = false
}
