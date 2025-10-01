variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "suffix" {
  description = "Random suffix for unique resource naming"
  type        = string
}

variable "destination_name" {
  description = "Name of the destination to bind this ARN to (must match listener destination)"
  type        = string
}

variable "global_role_arn" {
  description = "ARN of the global IAM role for Proxylity"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}