# Destination ARN registration

Register one AWS resource ARN for an existing destination and ingress region.
Destinations are declared in the listener module, not created by this submodule.
Requires Terraform >= 1.9 and AWS provider >= 5.0, < 7.0.

```hcl
module "registration" {
  source = "./terraform-aws-udp-gateway/modules/proxylity_destination_arn"

  stack_name         = "telemetry-storage-east-arn"
  destination_name   = one(module.listener.destination_names)
  destination_arn    = aws_s3_bucket.packets.arn
  ingress_region_key = "us-east-1"

  depends_on = [aws_iam_role_policy.delivery]
}
```

Using the listener output establishes creation/deletion order. If you use a
literal destination name instead, add `depends_on = [module.listener, ...]`.
Do not manage the same region registration both inline and through this module.

| Input | Default | Meaning |
|-------|---------|---------|
| `stack_name` | required | Unique stack name per registration; keep stable |
| `destination_name` | required | Existing service destination name |
| `destination_arn` | required | AWS resource ARN |
| `ingress_region_key` | null | Stack region when omitted; `"*"` for fallback |
| `tags` | `{}` | Stack tags |

`"*"` is used only when no region-specific ARN matches. Configure the provider
alias for the region in which this registration stack should run.

Outputs: `stack_name`, `stack_id`, `destination_name`, `destination_arn`,
`ingress_region_key`. The last three are resolved service attributes, so the
default region output is an actual region rather than null.

Changing `destination_name` replaces the registration stack because the service
does not allow that update. Other ARN/region changes use the update handler.

Configuration is resolved through the same CloudFormation `AWS::Include`
mapping as the listener. See the [root documentation](../../README.md) for
permissions, state protection and limitations.
