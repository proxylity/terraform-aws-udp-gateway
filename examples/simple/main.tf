module "udp" {
  source = "../../"

  listener_name = "example-listener"
  protocols     = ["udp"]
  client_restrictions = []
  
  # Inline destination declarations
  destinations = [
    {
      name = "lambda-destination"
      description = "Lambda function for packet processing"
      destination_arn = "arn:aws:lambda:us-west-2:123456789012:function:packet-handler"
      role = {
        role_arn = "arn:aws:iam::123456789012:role/ProxylityLambdaRole"
      }
      batching = {
        count = 10
        timeout_in_seconds = 5.0
      }
      metrics_enabled = true
      formatter = "base64"
    },
    {
      name = "sns-destination"
      description = "SNS topic for notifications"
      destination_arn = "arn:aws:sns:us-west-2:123456789012:packet-notifications"
      role = {
        role_arn = "arn:aws:iam::123456789012:role/ProxylitySnsRole"
      }
      formatter = "utf8"
    }
  ]
}
