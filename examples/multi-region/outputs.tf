output "listener_info" {
  description = "Information about the created UDP Gateway listener"
  value = {
    name             = module.udp_gateway.listener_name
    port             = module.udp_gateway.port
    domain           = module.udp_gateway.domain
    destination_names = module.udp_gateway.destination_names
  }
}

output "regional_buckets" {
  description = "Information about the regional S3 buckets"
  value = {
    for region, module in module.regional_infrastructure : region => module.bucket_info
  }
}

output "iam_role" {
  description = "IAM role for Proxylity S3 access"
  value = {
    name = aws_cloudformation_stack.proxylity_s3_role.outputs["RoleName"]
    arn  = aws_cloudformation_stack.proxylity_s3_role.outputs["RoleArn"]
  }
}

output "connection_info" {
  description = "Connection information for testing"
  value = {
    endpoint = "${module.udp_gateway.domain}:${module.udp_gateway.port}"
    protocol = "UDP"
    note     = "Traffic will be routed to the closest regional S3 bucket based on ingress region"
  }
}

output "regional_routing" {
  description = "Regional routing configuration"
  value = {
    for region, module in module.regional_infrastructure : region => {
      bucket = module.bucket_info.name
      region_key = module.destination_binding.region_key
      description = "Traffic from ${region} routes to ${module.bucket_info.name}"
    }
  }
}