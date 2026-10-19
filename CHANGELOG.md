# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0]

### Added
- Typed WireGuard, DTLS and WebRTC settings and protocol-specific outputs.
- Listener/destination observability, BREX filtering, CoAP formatting and typed
  Lambda, IoT, SQS, Kinesis and Location destination arguments.
- Existing destination references, typed regional ARN maps and fallback routing.
- SNS packet-source submodule with automatic replacement for listener changes.
- Numeric port, list destination names, hostname/endpoint and stack identity outputs.
- Credential-free Terraform contract tests and CI for AWS providers 5.x/6.x.
- Deployable SQS, protocol and SNS push examples; 1.x migration guide.

### Changed (breaking)
- Require Terraform >= 1.9; support AWS provider >= 5.0, < 7.0.
- Separate required `stack_name` from optional listener display name.
- Replace `protocols` list with a single `protocol` string.
- Replace destination list with a typed map; split string `destination_arn` from
  map `destination_arns`; rename role `role_arn` to `arn`.
- Default client restrictions now admit no traffic. Explicitly opt in to public access.
- Leave omitted formatter/metrics settings to service defaults.
- Require explicit stack names for ARN registrations.

### Fixed
- Serialize listener display name as `Name` and batching size as `SizeInMB`.
- Omit absent fields instead of emitting null custom-resource properties.
- Resolve ARN registration default-region output and avoid mixed HCL conditional types.
- Replace ARN registration stacks when their immutable destination name changes.
- Replace unsupported dynamic provider selection in the multi-region example.
- Wire regional delivery roles, policy ordering, full endpoints and unique binding names.

## [1.0.0] - 2025-09-30

### Added
- Initial release of Proxylity Terraform Provider
- Support for UDP Gateway listeners with inline destination configuration
- Full destination schema support (name, description, destination_arn, role, batching, metrics_enabled, formatter)
- Support for single global destinations and multi-region destination routing
- Standalone destination ARN binding module for post-deployment ARN association
- S3-based configuration system integration
- Comprehensive examples and documentation
- Validation for protocols (udp, wg) and formatters (base64, hex, ascii, utf8)

### Security
- Uses Proxylity's S3-based ServiceToken and ApiKey configuration system
- IAM role-based access control for destination resources

[2.0.0]: https://github.com/proxylity/terraform-aws-udp-gateway/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/proxylity/terraform-aws-udp-gateway/releases/tag/v1.0.0