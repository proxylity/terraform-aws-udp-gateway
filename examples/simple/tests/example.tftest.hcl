mock_provider "aws" {}

run "sqs_listener_plan" {
  command = plan
  variables {
    service_role_arn = "arn:aws:iam::123456789012:role/ProxylityService"
    client_cidr      = "192.0.2.10/32"
  }
}
