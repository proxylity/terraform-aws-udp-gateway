mock_provider "aws" {
  alias = "us_west_2"
}
mock_provider "aws" {
  alias = "us_east_1"
}
mock_provider "aws" {
  alias = "eu_west_1"
}
mock_provider "random" {}

run "regional_plan" {
  command = plan
  variables {
    client_cidr = "192.0.2.10/32"
  }
  assert {
    condition     = length(local.regional_infrastructure) == 3
    error_message = "All three statically bound provider regions must be configured."
  }
}
