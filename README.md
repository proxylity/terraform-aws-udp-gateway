# Proxylity UDP Gateway Terraform module

Manage Proxylity UDP, WireGuard, DTLS and WebRTC listeners with the standard AWS
provider. This is a **Terraform module, not a Terraform provider**. It manages
CloudFormation stacks containing the same custom resources as the
[CDK construct library](https://github.com/proxylity/cdk-udp-gateway).

Version **2.0.0+**. See [MIGRATION.md](./MIGRATION.md)
before upgrading from 1.x.

## Requirements

- Terraform >= 1.9 (cross-variable validation; mocked tests).
- AWS provider >= 5.0, < 7.0. Configure providers in your calling module.
- An active Proxylity UDP Gateway AWS Marketplace subscription.
- Read access to
  `s3://proxylity-config-<region>/<account-id>/customer-config.json`.
- Permissions to manage CloudFormation stacks and invoke the Proxylity custom
  resource service token. IAM/S3/SNS/etc. permissions depend on resources you create.

The module uses `AWS::Include` and `Fn::FindInMap` to resolve the account API key and
regional service token **inside CloudFormation**, without fetching the API key
into Terraform configuration.

## Quick start

Use the Terraform Registry module:

```hcl
provider "aws" {
  region = "us-west-2"
}

module "gateway" {
  source  = "proxylity/udp-gateway/aws"
  version = "~> 2.0"

  stack_name          = "telemetry-gateway"
  listener_name       = "Telemetry gateway"
  client_restrictions = { networks = ["192.0.2.10/32"] } # Replace with your public CIDR.

  destinations = {
    telemetry-processor = {
      destination_arn = aws_lambda_function.processor.arn
      role            = { arn = aws_iam_role.delivery.arn }
      batching        = { count = 100, timeout_in_seconds = 0.25, size_in_mb = 1 }
      arguments       = { use_response_streaming = true }
    }
  }

  depends_on = [aws_iam_role_policy.delivery]
}

output "endpoint" {
  value = module.gateway.endpoint
}
```

This snippet assumes the Lambda and delivery role already exist. The
[simple example](./examples/simple/) creates a real SQS queue, native Terraform
IAM role/policy, and listener end-to-end.

For local development, use `source = "./terraform-aws-udp-gateway"` and omit
`version`. Git consumers should pin a release tag such as `?ref=v2.0.3`; do not
depend on a moving branch in production.

## Design

- One root module call manages one listener stack. Use `for_each` in your calling
  module for multiple listeners.
- `protocol` is a single string: a listener cannot combine protocols.
- `stack_name` is infrastructure identity; `listener_name` is optional display
  text. The output `listener_name` is the **service-generated listener ID**.
- Destinations are a typed map keyed by service destination name. Ordering is
  deterministic. Use distinct names across listeners unless deliberately sharing
  an existing destination through `destination_names`.
- Optional fields are omitted, never serialized as JSON `null`. The service
  supplies batching/formatter defaults, including `utf8` for CloudWatch Logs.
- The module does not create IAM roles or guess permissions from arbitrary ARNs.
  Compose it with ordinary AWS resources and explicit dependencies on policies.
- Existing CloudFormation resource addresses/logical IDs are retained for upgrade
  planning. Review the migration guide; this does not guarantee a no-op upgrade.

### Client access

**No clients are allowed by default.** Set `client_restrictions.networks` and/or
`.domains` explicitly. To intentionally allow public IPv4 and IPv6 access:

```hcl
client_restrictions = { networks = ["0.0.0.0/0", "::/0"] }
```

For WireGuard these are the outer/public client addresses, not inner tunnel IPs.

### IAM

Delivery, observability and SNS subscription roles must trust the regional
**Proxylity `ServiceRole` ARN**, not `lambda.amazonaws.com` or `sns.amazonaws.com`.
Obtain that principal from the region's entry in your customer configuration:

```sh
aws s3 cp s3://proxylity-config-us-west-2/123456789012/customer-config.json - \
  | jq -r '."us-west-2".ServiceRole'
```

Do not print or check in the account API key. The destination role needs
service-specific actions scoped to its target, such as `lambda:InvokeFunction`,
`sqs:SendMessage` or `s3:PutObject`. Lambda MicroVM image destinations need
`lambda:RunMicrovm`, `GetMicrovm`, `ResumeMicrovm`, `TerminateMicrovm`,
`GetMicrovmImage`, `GetMicrovmImageVersion` and `CreateMicrovmAuthToken` on the image
ARN, `lambda:PassNetworkConnector` on the connectors the MicroVM uses (by default the AWS-managed `HTTP_INGRESS` and `INTERNET_EGRESS` connectors; with `egress_network_connector_arns`, `HTTP_INGRESS` plus those connectors), and
`iam:PassRole` on `execution_role_arn` (condition `iam:PassedToService` =
`lambda.amazonaws.com`). Metrics additionally need
`cloudwatch:PutMetricData`; log delivery needs `logs:CreateLogStream` and
`logs:PutLogEvents`. Create log groups yourself. For cross-region destinations,
trust the Proxylity principals for the applicable ingress regions.

Listener/destination roles use `{ arn = "...", duration = "1:00:00" }`.
`duration` is a .NET TimeSpan, not a number of seconds. The service validates role
durations, destination-service constraints, BREX expressions and AWS permissions.

## Inputs

The complete, typed nested schema and validation messages are in
[variables.tf](./variables.tf).

| Input | Type | Default | Purpose |
|-------|------|---------|---------|
| `stack_name` | string | required | Stable, unique CloudFormation stack name |
| `listener_name` | string | null | Optional listener display name |
| `description` | string | null | Listener description |
| `protocol` | string | `"udp"` | `udp`, `wg`, `dtls`, `webrtc` |
| `client_restrictions` | object | empty lists | Allowed CIDRs and domains |
| `destinations` | map(object) | `{}` | Inline destinations keyed by name |
| `destination_names` | set(string) | `[]` | Existing destinations to reference |
| `role` | object | null | Listener metrics/log delivery role |
| `metrics_enabled` | bool | null | Listener metrics |
| `log_group_name` | string | null | Listener log group |
| `wireguard` | sensitive object | null | WireGuard options; requires `wg` |
| `dtls` | sensitive object | null | DTLS options; requires `dtls` |
| `webrtc` | sensitive object | null | WebRTC options; requires `webrtc` |
| `tags` | map(string) | `{}` | CloudFormation stack tags |

### Destinations

Each destination supports `description`, `role`, `batching`, `metrics_enabled`,
`formatter`, `filter_expression` (BREX), `log_group_name`, and typed `arguments`.
Supported payload formatters: `base64`, `hex`, `ascii`, `utf8`, `coap`,
`coap+`, `syslog`. The protocol-aware formatters (`coap`, `coap+`, `syslog`)
deliver `Data` as a JSON object; `coap+` decodes supported CoAP content formats.
See the [Proxylity formatter documentation](https://www.proxylity.com/docs/destinations/formatters.html)
for packet shapes and supported content formats.

Set **one** ARN form:

```hcl
destinations = {
  regional-storage = {
    destination_arns = {
      "*"         = "arn:aws:s3:::fallback-packets"
      "us-east-1" = "arn:aws:s3:::east-packets"
      "eu-west-1" = "arn:aws:s3:::europe-packets"
    }
    role = { arn = aws_iam_role.delivery.arn }
  }
}
```

- `destination_arn`: one ARN string.
- `destination_arns`: region => ARN map. `"*"` is a fallback, not an override.
- Neither: an unbound destination, to register later using the ARN submodule.
- `destination_names`: references existing destinations without redefining them.

Typed `arguments` cover:

| Service | Settings |
|---------|----------|
| Lambda | `tenant_id`, `tenant_id_expression`, `tenant_id_formatter`, `use_response_streaming`, `use_async_invoke` (invoke modes are mutually exclusive) |
| Lambda MicroVM image (`arn:aws:lambda:REGION:ACCOUNT:microvm-image:NAME[:VERSION]`) | `idle_duration_seconds` (integer; the service clamps to 60-28800, default 900), `execution_role_arn`, `run_hook_extra_data` (up to 2048 characters, no secrets), `egress_network_connector_arns` (1-10 customer-managed network connector ARNs; omit for Lambda's default internet egress), `runtime_log_group_name` (the CloudWatch Logs group MicroVMs write their stdout/stderr to, using the execution role, which must be allowed to write there; omit for Lambda's default `/aws/lambda-microvms/{image name}`), `use_tenant_id_for_log_stream_name` (name each MicroVM's log stream after its tenant ID; requires `tenant_id` or `tenant_id_expression`), and the `tenant_id*` settings. `use_response_streaming` and `use_async_invoke` are rejected. |
| IoT Data | `dynamic_topic_suffix`, `topic_suffix_expression`, `topic_suffix_formatter` |
| SQS | `send_raw`, `use_message_attributes`, `message_group_id_expression`, `message_group_id_formatter`, `message_deduplication_id_expression`, `message_deduplication_id_formatter` |
| Kinesis | `partition_key_expression`, `partition_key_expression_formatter` |
| Location | `device_id_expression`, `latitude_expression`, `longitude_expression`, `scale_factor`, `accuracy_expression`, `position_property_expressions`, `timestamp_expression`, `timestamp_time_unit` |

Argument formatters accept `base64`, `hex`, `ascii`, `utf8`. Timestamp units are
`seconds` or `milliseconds`. Other supported AWS services still use their normal
destination ARN, role, formatter, filter and batching configuration.

### Protocol settings

- `wireguard`: `peers` (`public_key`, optional `shared_secret`, `allowed_ips`),
  `allow_unknown_peers`, `unknown_peer_pre_shared_key`, `decapsulated_delivery`,
  `key_refresh_token`.
- `dtls`: `psks`, `server_secret`, `require_cookies`, `allow_early_data`,
  `early_data_window_seconds` (integer 1..604800), `cert_refresh_token`.
- `webrtc`: `server_secret`, `require_cookies` (cannot be false),
  `cert_refresh_token`, `signaling_mode` (`none` or `public`),
  `signaling_refresh_token`.

WireGuard keys and server secrets must be base64-encoded 32-byte values.
Changing rotation tokens rotates the corresponding service key/certificate/token
on stack update. Omitted settings use service defaults; the module does not turn
on unknown peers, early data or public signaling implicitly.

## Outputs

| Output | Type / behavior |
|--------|-----------------|
| `stack_name`, `stack_id` | CloudFormation identity |
| `listener_name` | Service listener ID, usable by packet sources |
| `port` | number |
| `domain` | subdomain without `.proxylity.com` |
| `hostname`, `endpoint` | Full hostname and `hostname:port` |
| `destination_names` | list(string), empty when there are none |
| `wireguard_public_key` | string for `wg`, otherwise null |
| `dtls_server_certificate` | PEM for `dtls`/`webrtc`, otherwise null |
| `webrtc` | `{ fingerprint, sctp_port, channel_id, signaling_mode }`, otherwise null |
| `webrtc_signaling_token`, `webrtc_signaling_url` | sensitive strings only for public WebRTC signaling, otherwise null |

Only protocol-appropriate CloudFormation attributes are requested.

## Submodules and examples

- [Destination ARN registration](./modules/proxylity_destination_arn/): one region
  registration per stack, with explicit stack names to prevent collisions.
- [SNS packet source](./modules/proxylity_packet_source/): server-initiated push.
- [Simple](./examples/simple/): SQS queue, IAM role/policy and UDP listener.
- [Multi-region](./examples/multi-region/): three S3 buckets with static provider
  aliases and regional registrations.
- [Protocols](./examples/protocols/): WireGuard, DTLS and public WebRTC.
- [Server push](./examples/server-push/): SNS topic, subscription IAM and packet source.

For Registry submodules use sources such as
`proxylity/udp-gateway/aws//modules/proxylity_packet_source`, pinned to `~> 2.0`.

## State and deployment safety

Sensitive inputs/outputs redact CLI display; they **do not encrypt Terraform
state, saved plans or CloudFormation templates/outputs**. Use encrypted remote
state and restrict access to state, plans and CloudFormation. Public signaling
outputs contain credentials. Do not commit PSKs, secrets or populated variable
files. Prefer service-generated secrets where supported.

CloudFormation manages the custom resources; Terraform cannot independently
refresh service-side drift. Inspect stack events for deployment errors. Separate
ARN registrations must depend on listener creation and IAM policy readiness.
Changing a packet source's listener ID replaces its stack because the service
does not permit that update. Changing an ARN registration's destination name
also replaces that registration stack.

See [TESTING.md](./TESTING.md) for credential-free tests and live verification,
and [CHANGELOG.md](./CHANGELOG.md) for release notes.
