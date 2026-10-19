# SNS packet source

Subscribe a listener to an SNS topic for server-initiated push using
`Custom::ProxylityUdpGatewayPacketSource`.
Requires Terraform >= 1.9 and AWS provider >= 5.0, < 7.0.

```hcl
module "push" {
  source = "./terraform-aws-udp-gateway/modules/proxylity_packet_source"

  stack_name    = "telemetry-push"
  listener_name = module.listener.listener_name
  sns_topic_source = {
    topic_arn = aws_sns_topic.push.arn
    role_arn  = aws_iam_role.subscribe.arn
  }
  depends_on = [aws_iam_role_policy.subscribe]
}
```

| Input | Default | Meaning |
|-------|---------|---------|
| `stack_name` | required | Unique, stable CloudFormation stack name |
| `listener_name` | required | Service listener ID, not the display name |
| `sns_topic_source` | required | `{ topic_arn, role_arn }` |
| `description` | null | Omitted to use the service-generated description |
| `tags` | `{}` | Stack tags |

The topic must be in the same region as the packet-source stack. The subscribe
role must trust the regional Proxylity `ServiceRole` and permit `sns:Subscribe`,
`sns:Unsubscribe`, `sns:ListSubscriptionsByTopic` on that topic. The caller is
responsible for any topic policy required for cross-account access.

Changing `listener_name` replaces the stack (destroy then create) because the
service rejects updating it. Do not enable create-before-destroy with a fixed
stack name. Other subscription changes follow the service's update behavior.

Outputs: `stack_name`, `stack_id`, `packet_source_id` (custom-resource `Ref`).
There are no packet-source `GetAtt` outputs. This module does not create the
listener, SNS topic, IAM role/policy, or application push messages.

See the [server-push example](../../examples/server-push/) and
[root documentation](../../README.md).
