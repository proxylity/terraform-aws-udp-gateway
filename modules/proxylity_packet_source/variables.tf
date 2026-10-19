variable "stack_name" {
  description = "Unique CloudFormation stack name for the packet source."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{0,127}$", var.stack_name))
    error_message = "stack_name must start with a letter and contain at most 128 letters, digits or hyphens."
  }
}

variable "listener_name" {
  description = "Target service listener ID (module.listener_name), not its display name. Changing it requires replacing this stack."
  type        = string
  nullable    = false
}

variable "sns_topic_source" {
  description = "SNS topic in the stack region and IAM role ARN used by Proxylity to subscribe. Role is a bare ARN on the wire."
  type = object({
    topic_arn = string
    role_arn  = string
  })
  nullable = false

  validation {
    condition = (
      can(regex("^arn:[^:]+:sns:[^:]+:[0-9]{12}:.+$", var.sns_topic_source.topic_arn)) &&
      can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+$", var.sns_topic_source.role_arn))
    )
    error_message = "sns_topic_source requires an SNS topic ARN and an IAM role ARN."
  }
}

variable "description" {
  description = "Optional packet-source description."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the CloudFormation stack."
  type        = map(string)
  default     = {}
  nullable    = false
}
