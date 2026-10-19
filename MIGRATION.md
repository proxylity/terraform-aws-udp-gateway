# Migrating from 1.x to 2.0

2.0 is a breaking release. Back up your state and review a full plan before
applying.

## Input changes

| 1.x | 2.0 |
|-----|-----|
| `listener_name` also named the stack | Set `stack_name` to the **old `listener_name`** to preserve stack identity; `listener_name` now maps to the service's `Name` display property |
| `protocols = ["udp"]` | `protocol = "udp"`; exactly one of `udp`, `wg`, `dtls`, `webrtc` |
| `destinations = [{ name = "processor", ... }]` | `destinations = { processor = { ... } }` |
| `destination_arn` accepts string or map (`any`) | `destination_arn` is a string; use `destination_arns` for region => ARN maps |
| `role = { role_arn = "..." }` | `role = { arn = "...", duration = "1:00:00" }` |
| Public IPv4/IPv6 access by default | Empty restrictions admit no clients; explicitly set allowed CIDRs/domains |
| Formatter defaults to `base64` in Terraform | Omitted formatter uses service defaults (`utf8` for logs, otherwise `base64`); set explicitly to retain old behavior |
| Metrics default to `false` in Terraform | Omitted metrics use service defaults; set explicitly if required |
| Destination binding auto-names stack `<destination_name>-arn` | Set binding `stack_name` explicitly to the existing name to preserve it |

Example:

```hcl
module "gateway" {
  source  = "proxylity/udp-gateway/aws"
  version = "~> 2.0"

  stack_name          = "old-listener-stack"
  protocol            = "udp"
  client_restrictions = { networks = ["192.0.2.10/32"] }
  destinations = {
    processor = {
      destination_arn = aws_lambda_function.processor.arn
      role            = { arn = aws_iam_role.delivery.arn }
      formatter       = "base64"
      metrics_enabled = false
    }
  }
}
```

The old `ListenerName` property was not the service's display-name property. 2.0
corrects it to `Name`. Omit `listener_name` to leave display-name generation to the
service. Do not confuse that input with the `listener_name` **output**, which is
the service ID.

The module also corrects batching `SizeInMb` to the service's `SizeInMB`. If you
previously configured `size_in_mb`, that setting now actually takes effect.

## Output changes

- `port`: string -> number.
- `destination_names`: comma-separated string -> list(string). Replace
  `split(",", module.gateway.destination_names)` with
  `module.gateway.destination_names`.
- `domain` remains a subdomain. Prefer new `hostname` and `endpoint` outputs
  instead of building addresses manually.
- ARN registration `ingress_region_key` now returns the resolved region rather
  than null when the input is omitted.
- ARN registrations now replace their stack if the immutable destination name
  changes, rather than submitting an update the service rejects.

## State and resource identity

The existing root and registration resource addresses and CloudFormation logical
IDs are unchanged. Keep your module call addresses and stack names stable.
Changing a stack name forces replacement; changing other properties still runs
the service's custom-resource update handler.

The multi-region example now uses three explicit module calls because Terraform
does not support `aws[each.value]` provider selection. If you have state from an
adapted older example, inspect `terraform state list` and move each regional
module to its new address before applying, for example:

```sh
terraform state mv 'module.regional_infrastructure["us-west-2"]' module.us_west_2
terraform state mv 'module.regional_infrastructure["us-east-1"]' module.us_east_1
terraform state mv 'module.regional_infrastructure["eu-west-1"]' module.eu_west_1
```

Preserve existing destination names and binding stack names in your configuration
when migrating; the updated example uses unique suffixes for new deployments.
Do not apply the new example blindly to existing state.

## Upgrade checklist

1. Install Terraform >= 1.9; use AWS provider 5.x or 6.x.
2. Back up state and keep the current dependency lock file for comparison.
3. Update inputs and downstream output consumers.
4. Set client restrictions explicitly; retain public access only deliberately.
5. Confirm IAM roles trust the correct regional Proxylity ServiceRole and include
   delivery/metrics/log permissions actually needed.
6. Run `terraform init`, `terraform validate`, and `terraform plan`.
7. Inspect stack replacement, destination changes, batching behavior, formatter
   changes and client-access changes before applying.
8. Verify real packet delivery and inspect CloudFormation events after apply.
