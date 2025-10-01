variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "proxylity-demo"
}

variable "enable_s3_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = false
}

variable "s3_storage_class" {
  description = "S3 storage class for packet data"
  type        = string
  default     = "STANDARD"
  
  validation {
    condition = contains([
      "STANDARD", 
      "STANDARD_IA", 
      "ONEZONE_IA", 
      "REDUCED_REDUNDANCY",
      "GLACIER",
      "DEEP_ARCHIVE"
    ], var.s3_storage_class)
    error_message = "Storage class must be a valid S3 storage class."
  }
}