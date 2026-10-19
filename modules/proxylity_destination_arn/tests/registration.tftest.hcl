mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      outputs = {
        Destination      = "storage"
        IngressRegionKey = "us-west-2"
        Arn              = "arn:aws:s3:::packets"
      }
    }
  }
}

variables {
  stack_name       = "test-registration"
  destination_name = "storage"
  destination_arn  = "arn:aws:s3:::packets"
}

run "default_region_and_outputs" {
  command = apply
  assert {
    condition     = jsondecode(aws_cloudformation_stack.proxylity_destination_arn.template_body).Resources.ProxylityDestinationArn.Properties.IngressRegionKey.Ref == "AWS::Region"
    error_message = "Default ingress region must use AWS::Region without HCL string/object coercion."
  }
  assert {
    condition     = output.ingress_region_key == "us-west-2"
    error_message = "Output the resolved region rather than the nullable input."
  }
  assert {
    condition = (
      jsondecode(aws_cloudformation_stack.proxylity_destination_arn.template_body).Outputs.Arn.Value["Fn::GetAtt"][1] == "Arn" &&
      !contains(keys(jsondecode(aws_cloudformation_stack.proxylity_destination_arn.template_body).Resources.ProxylityDestinationArn), "Outputs")
    )
    error_message = "Outputs must be at template scope and use supported resource attributes."
  }
}

run "fallback" {
  command = plan
  variables { ingress_region_key = "*" }
  assert {
    condition     = jsondecode(aws_cloudformation_stack.proxylity_destination_arn.template_body).Resources.ProxylityDestinationArn.Properties.IngressRegionKey == "*"
    error_message = "Fallback must serialize as a string."
  }
}

run "explicit_region" {
  command = plan
  variables { ingress_region_key = "eu-west-1" }
  assert {
    condition     = jsondecode(aws_cloudformation_stack.proxylity_destination_arn.template_body).Resources.ProxylityDestinationArn.Properties.IngressRegionKey == "eu-west-1"
    error_message = "Explicit region must serialize as a string."
  }
}

run "invalid_arn" {
  command = plan
  variables { destination_arn = "not-an-arn" }
  expect_failures = [var.destination_arn]
}

run "destination_change_replaces_stack" {
  command = apply
  variables { destination_name = "other-storage" }
  assert {
    condition     = output.stack_id != run.default_region_and_outputs.stack_id
    error_message = "Changing the immutable destination name must replace the registration stack."
  }
}
