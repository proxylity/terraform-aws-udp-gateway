mock_provider "aws" {}

run "push_plan" {
  command = plan
  variables {
    listener_name    = "listener-123"
    service_role_arn = "arn:aws:iam::123456789012:role/ProxylityService"
  }
}
