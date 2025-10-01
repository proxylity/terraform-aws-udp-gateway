# Publishing to Terraform Registry

## Prerequisites

1. **GitHub Repository**: Module must be in a public GitHub repository
2. **Repository Naming**: Should follow pattern `terraform-<provider>-<name>`
   - Example: `terraform-aws-udp-gateway` (for organization "proxylity")
3. **Git Tags**: Use semantic versioning tags (v1.0.0, v1.1.0, etc.)
4. **HashiCorp Account**: Sign up at registry.terraform.io

## Repository Structure Requirements

```
terraform-aws-udp-gateway/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── CHANGELOG.md
├── LICENSE
├── examples/
│   ├── simple/
│   │   └── main.tf
│   └── multi-region/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
└── modules/
    └── proxylity_destination_arn/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

## Publishing Steps

### 1. Prepare Repository
```bash
# Ensure clean repository structure
git add .
git commit -m "Prepare for registry publication"
git push origin main
```

### 2. Create Release Tag
```bash
# Create and push semantic version tag
git tag v1.0.0
git push origin v1.0.0
```

### 3. Publish to Registry
1. Go to https://registry.terraform.io
2. Sign in with GitHub account
3. Click "Publish" → "Module"
4. Select your repository
5. Verify and publish

### 4. Verify Publication
- Check module appears at: `registry.terraform.io/modules/proxylity/udp-gateway/aws`
- Test installation with version constraint

## Registry vs Git Tags

| Feature | Terraform Registry | Git Tags |
|---------|-------------------|----------|
| **Discovery** | Searchable | Manual |
| **Documentation** | Auto-generated | Manual |
| **Version Browsing** | Built-in UI | GitHub releases |
| **Installation** | `source = "org/name/provider"` | `source = "git::..."` |
| **Validation** | HashiCorp verified | Self-managed |
| **Private Modules** | Terraform Cloud/Enterprise | Git permissions |

## Versioning for Registry

### Same Process, Better UX
- **Git tags**: Still required (v1.0.0, v1.1.0, etc.)
- **Registry syncs**: Automatically from your tagged releases
- **Version constraints**: Use standard Terraform syntax (`~> 1.0`)

### Registry-Specific Benefits
- **Version validation**: Registry validates semantic versioning
- **Documentation**: Auto-generated from README.md
- **Examples**: Parsed from examples/ directory
- **Dependencies**: Visual dependency graphs

## Best Practices

1. **Test before publishing**: Always test locally first
2. **Complete examples**: Include working examples in examples/
3. **Clear documentation**: Registry generates docs from README.md
4. **Semantic versioning**: Follow semver strictly
5. **Changelog maintenance**: Keep CHANGELOG.md updated

## Publishing Checklist

- [ ] Repository follows naming convention
- [ ] All required files present (main.tf, variables.tf, outputs.tf, versions.tf)
- [ ] README.md has proper formatting and examples
- [ ] examples/ directory contains working examples
- [ ] Git tag follows semantic versioning (v1.0.0)
- [ ] CHANGELOG.md updated
- [ ] Repository is public on GitHub
- [ ] All tests pass locally