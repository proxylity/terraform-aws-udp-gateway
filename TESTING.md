# Testing

## Credential-free checks

Install Terraform >= 1.9. These tests use mocked AWS providers; they do not create
AWS resources, read customer configuration, or require AWS credentials.

```sh
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test

terraform -chdir=modules/proxylity_destination_arn init -backend=false
terraform -chdir=modules/proxylity_destination_arn validate
terraform -chdir=modules/proxylity_destination_arn test

terraform -chdir=modules/proxylity_packet_source init -backend=false
terraform -chdir=modules/proxylity_packet_source validate
terraform -chdir=modules/proxylity_packet_source test
```

Initialize and validate each example as well:

```sh
terraform -chdir=examples/simple init -backend=false
terraform -chdir=examples/simple validate
terraform -chdir=examples/simple test
terraform -chdir=examples/multi-region init -backend=false
terraform -chdir=examples/multi-region validate
terraform -chdir=examples/multi-region test
terraform -chdir=examples/protocols init -backend=false
terraform -chdir=examples/protocols validate
terraform -chdir=examples/protocols test
terraform -chdir=examples/server-push init -backend=false
terraform -chdir=examples/server-push validate
terraform -chdir=examples/server-push test
```

The tests inspect the actual serialized CloudFormation template, including
PascalCase API fields, ARN string/map types, omission of nulls, protocol-specific
attributes, explicit false values, configuration transforms, validation failures,
numeric/list outputs and packet-source replacement when its listener changes.

These are contract tests, not proof of a successful live deployment. They cannot
test subscription status, IAM authorization, AWS::Include expansion or packet
delivery. CI repeats the checks using AWS provider 5.x and 6.x.

## Live verification (opt-in; incurs AWS charges)

Use a subscribed development account and a protected state backend. Never run
apply/destroy in CI with the mocked-test job.

### Simple SQS example

From `examples/simple`, supply `region`, `client_cidr` (your public IP/CIDR) and
`service_role_arn` (from the regional customer configuration). Then:

```sh
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output -raw endpoint
terraform output -raw queue_url
```

Send a UDP packet to the returned hostname/port from the allowed public source
network and receive the resulting SQS message using `aws sqs receive-message`.
Inspect CloudFormation stack events if provisioning fails. The example's
`test.sh` / `test.ps1` wrappers validate and plan; deployment remains opt-in.

### Multi-region

Supply `client_cidr` in `examples/multi-region`, then plan/apply normally (no
targeted apply required). Confirm all three regional registration stacks exist.
Send packets through each configured ingress region and verify objects arrive in
the corresponding bucket. Other ingress regions have no fallback ARN in this
example; configure one if needed. The destination role trusts all three regional
ServiceRole principals.

### Protocols and server push

- `examples/protocols` requires an existing destination, allowed public CIDR,
  WireGuard peer public key and protected DTLS PSKs. Verify a real handshake and
  payload delivery for each protocol. Verify certificate/key outputs against
  clients; test token/certificate rotation separately.
- `examples/server-push` requires an existing listener ID and regional ServiceRole
  ARN. Confirm the SNS subscription and send a valid Proxylity push message
  targeting a connected client. This example creates the subscription, not a
  complete application-level push payload.

### Cleanup

Run `terraform destroy` only in the example/state you created. Empty S3 buckets
(including object versions/delete markers) first; the multi-region example does
not force-delete packet data. Remove sensitive saved plan files when finished.
