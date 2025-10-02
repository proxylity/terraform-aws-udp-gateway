variable "listener_name" {
  description = "Name of the Proxylity listener"
  type        = string
}

variable "protocols" {
  description = "List of protocols for the listener"
  type        = list(string)
  default     = ["udp"]
  
  validation {
    condition = alltrue([
      for protocol in var.protocols : contains(["udp", "wg"], protocol)
    ])
    error_message = "Protocols must be 'udp' or 'wg'."
  }
}

variable "client_restrictions" {
  description = "Client restrictions configuration with Networks and Domains"
  type = object({
    networks = optional(list(string), ["0.0.0.0/0", "::/0"])
    domains  = optional(list(string), [])
  })
  default = {
    networks = ["0.0.0.0/0", "::/0"]
    domains  = []
  }
}

variable "destinations" {
  description = "List of destination configurations"
  type = list(object({
    name             = optional(string)
    description      = optional(string)
    destination_arn  = optional(any) # Can be string or map of regions to ARNs
    role = optional(object({
      role_arn = string
    }))
    batching = optional(object({
      count             = optional(number)
      timeout_in_seconds = optional(number)
      size_in_mb        = optional(number)
    }))
    metrics_enabled = optional(bool, false)
    formatter       = optional(string, "base64") # base64, hex, ascii, utf8
  }))
  default = []
  
  validation {
    condition = alltrue([
      for dest in var.destinations : 
      dest.formatter == null || contains(["base64", "hex", "ascii", "utf8"], dest.formatter)
    ])
    error_message = "Formatter must be one of: base64, hex, ascii, utf8."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}