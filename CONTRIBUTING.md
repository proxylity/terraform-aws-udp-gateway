# Contributing to Proxylity Terraform Provider

## Versioning Guidelines

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0): Breaking changes that require user action
- **MINOR** version (0.X.0): New features that are backward compatible
- **PATCH** version (0.0.X): Bug fixes and improvements

## Release Process

### For Git Tags
1. **Update CHANGELOG.md** with changes
2. **Update version** in relevant files
3. **Create and push git tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. **Create GitHub release** with release notes

### For Terraform Registry
1. **Follow git tag process above**
2. **Registry auto-syncs** from your tagged releases
3. **Verify publication** at registry.terraform.io
4. **Test installation** using registry source

See [REGISTRY.md](./REGISTRY.md) for detailed registry publishing guidelines.

## Breaking Changes

Examples of breaking changes that require MAJOR version bump:
- Removing or renaming variables
- Changing variable types or validation
- Modifying output names or types
- Changes to CloudFormation resource properties that affect existing deployments

## Backward Compatible Changes

Examples that require MINOR version bump:
- Adding new optional variables
- Adding new outputs
- Adding new features without affecting existing functionality
- Improving documentation

## Bug Fixes

Examples that require PATCH version bump:
- Fixing validation rules
- Correcting documentation errors
- Performance improvements
- Security updates that don't change API

## Testing

Before releasing:
- [ ] Test with `terraform plan` and `terraform apply`
- [ ] Validate examples work correctly
- [ ] Update documentation if needed
- [ ] Check for breaking changes