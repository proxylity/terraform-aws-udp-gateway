variable "destination_name" {
  description = "Name of the destination to bind ARN to"
  type        = string
}

variable "destination_arn" {
  description = "AWS resource ARN to bind to destination"
  type        = string
}

variable "ingress_region_key" {
  description = "Region key for ingress configuration. Defaults to current AWS region. Use '*' for all regions."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the CloudFormation stack"
  type        = map(string)
  default     = {}
}