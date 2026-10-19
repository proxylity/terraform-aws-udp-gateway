variable "destination_name" {
  description = "Name of the destination to bind ARN to"
  type        = string
  nullable    = false
}

variable "destination_arn" {
  description = "AWS resource ARN to bind to destination"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:[^:]+:[^:]+:[^:]*:[^:]*:.+$", var.destination_arn))
    error_message = "destination_arn must be a valid ARN."
  }
}

variable "ingress_region_key" {
  description = "Ingress region key. Defaults to the stack region. '*' is a fallback, not an override for registered regions."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the CloudFormation stack"
  type        = map(string)
  default     = {}
  nullable    = false
}
variable "stack_name" {
  description = "Unique CloudFormation stack name for this registration. Use a distinct name for each region key."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{0,127}$", var.stack_name))
    error_message = "stack_name must start with a letter and contain at most 128 letters, digits or hyphens."
  }
}
