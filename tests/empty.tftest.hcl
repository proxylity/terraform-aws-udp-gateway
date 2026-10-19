mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      outputs = { ListenerName = "listener", Port = "12345", Domain = "example", DestinationNames = "" }
    }
  }
}

run "empty_destination_names" {
  command = apply
  variables { stack_name = "test-empty" }
  assert {
    condition     = length(output.destination_names) == 0
    error_message = "Empty names must return [], not [\"\"]."
  }
}
