# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/your-org/proxylity-terraform-provider/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-org/proxylity-terraform-provider/releases/tag/v1.0.0