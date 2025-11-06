# Enterprise Serverless API Stack - AI Coding Agent Instructions

## Project Overview
This is an **enterprise-grade Terraform Stacks demonstration** showcasing a multi-region serverless API built with AWS Lambda, S3, and API Gateway. This Stack demonstrates ALL major Stacks features for customer demos and architectural discussions.

## Demo Purpose & Audience
**Target**: Enterprise customers familiar with Terraform but new to Stacks  
**Goal**: Demonstrate component-based architecture, deployment groups, multi-region patterns, and enterprise governance  
**Use Case**: Serverless microservice API deployed across multiple environments and regions

## Official Documentation Links
- **[Stacks Overview](https://developer.hashicorp.com/terraform/language/stacks)** - Core concepts and architecture
- **[Component Configuration](https://developer.hashicorp.com/terraform/language/stacks/component/config)** - Define Stack components
- **[Deployment Configuration](https://developer.hashicorp.com/terraform/language/stacks/deploy/config)** - Define deployments
- **[Declare Providers](https://developer.hashicorp.com/terraform/language/stacks/component/declare-providers)** - Provider setup patterns
- **[Deployment Conditions](https://developer.hashicorp.com/terraform/language/stacks/deploy/conditions)** - Auto-approval rules
- **[CLI Commands](https://developer.hashicorp.com/terraform/cli/commands/stacks)** - Full command reference

## Architecture & Component Flow

### Serverless API Components
1. **S3 Component** (`./s3`) - Versioned bucket for Lambda deployment packages
2. **Lambda Component** (`./lambda`) - Ruby function, depends on S3 bucket
3. **API Gateway Component** (`./api-gateway`) - HTTP endpoint, depends on Lambda

### Component Dependencies
```hcl
S3 Bucket → Lambda Function → API Gateway → Public HTTP Endpoint
  |            |                   |
  └─ Stores ───┴─ Executes ────────┴─ Exposes
     code         function              endpoint
```

**Key Pattern**: Each component uses `for_each = var.regions` to deploy per region automatically.

## File Structure & Purpose
```
├── components.tfcomponent.hcl      # 3 components with for_each expansion
├── deployments.tfdeploy.hcl        # 4 environments + deployment groups
├── providers.tfcomponent.hcl       # Dynamic AWS providers per region
├── variables.tfcomponent.hcl       # Validated inputs (environment, regions, etc.)
├── outputs.tfcomponent.hcl         # API endpoints, console links, monitoring
├── locals.tfcomponent.hcl          # Naming, tagging, environment logic
└── {s3,lambda,api-gateway}/        # Traditional Terraform modules (.tf)
```

## Stacks Features Demonstrated

### 1. Component-Based Architecture
```hcl
component "lambda" {
  for_each = var.regions
  source = "./lambda"
  inputs = {
    bucket_id = component.s3[each.value].bucket_id  # Component dependency
  }
}
```
**Demo Point**: Components source modules, create dependency graph automatically

### 2. Dynamic Multi-Region Deployment
```hcl
provider "aws" "configurations" {
  for_each = var.regions  # Creates provider per region
  config {
    region = each.value
    assume_role_with_web_identity { ... }
  }
}
```
**Demo Point**: One provider definition, multiple instances automatically created

### 3. Deployment Groups with Guardrails
```hcl
# Dev: Liberal (≤20 changes)
# Test: Moderate (≤10 changes, no destroys)
# Staging: Strict (≤5 changes, no destroys)
# Production: Critical (≤3 changes, no destroys, success required)
```
**Demo Point**: Codified change management, progressive restrictions

### 4. Environment Progression
- **Dev**: 1 region (us-east-1), 128MB Lambda, 7-day logs
- **Test**: 1 region (us-east-1), 256MB Lambda, 14-day logs  
- **Staging**: 2 regions (us-east + us-west), 512MB Lambda, 30-day logs
- **Production**: 3 regions (us-east + us-west + eu-west), 1024MB Lambda, 90-day logs

**Demo Point**: Same Stack config, different inputs per environment

### 5. Comprehensive Outputs
Outputs include:
- API endpoint URLs per region with test instructions
- AWS Console direct links (Lambda, API Gateway, S3)
- CloudWatch Log Group names for monitoring
- Deployment summary with test commands

**Demo Point**: Observable infrastructure from HCP Terraform UI

### 6. Enterprise Tagging Strategy
```hcl
locals {
  computed_tags = {
    StackName, Environment, EnvironmentTier, ManagedBy, DeployedAt
  }
  compliance_tags = is_production ? { Compliance, DataClass, etc. } : {}
}
```
**Demo Point**: Cost allocation, compliance, governance baked in

### 7. Variable Validation
All inputs validated:
- `environment` must be dev/test/staging/production
- `regions` must be 1-10 valid AWS regions
- `role_arn` must match IAM ARN format
- `lambda_memory_mb` must be 128-10240, multiple of 64
- `log_retention_days` must be valid CloudWatch retention period

**Demo Point**: Type safety and input validation prevent configuration errors

## Demo Walkthrough Script

### Opening (2 min)
"This Stack deploys a serverless API—S3, Lambda, API Gateway—across multiple AWS regions and environments. But we're not here to talk about Lambda. We're here to show you how Stacks transforms infrastructure management."

### Component Architecture (3 min)
1. Show `components.tfcomponent.hcl` - "Three components, each with `for_each = var.regions`"
2. Highlight dependency: "Lambda needs S3 bucket ID, API Gateway needs Lambda ARN"
3. Point out: "Stacks resolves dependencies automatically, deploys in correct order"

### Multi-Region Pattern (3 min)
1. Show `providers.tfcomponent.hcl` - "One provider definition, `for_each = var.regions`"
2. Show component: `providers = { aws = provider.aws.configurations[each.value] }`
3. Result: "Add region to deployment input, entire stack deploys there automatically"

### Deployment Groups & Guardrails (5 min)
1. Show `deployments.tfdeploy.hcl` - Four environments
2. Walk through auto-approval rules: "Dev allows 20 changes, Production only 3"
3. Explain: "This codifies your change management process in infrastructure code"
4. Show deployment group assignment per environment

### Environment Progression (3 min)
1. Compare dev vs production inputs:
   - Regions: 1 → 3
   - Lambda memory: 128MB → 1024MB
   - Log retention: 7 days → 90 days
2. Highlight tags: "Production gets compliance tags automatically"

### Outputs & Observability (2 min)
1. Show `outputs.tfcomponent.hcl`
2. Highlight API endpoints, AWS console links, monitoring paths
3. "HCP Terraform UI presents all this—your team sees exactly what's deployed where"

### Live Demo (5 min - if possible)
1. `terraform stacks plan` - Show multi-deployment planning
2. Apply dev deployment - Watch auto-approval
3. Test API endpoint: `curl https://.../hello?name=Demo`
4. Show HCP Terraform UI outputs

### Closing (2 min)
"Same Stack configuration deploys across four environments, multiple regions, with progressive guardrails. Your existing modules work as-is. You get deployment orchestration, multi-region expansion, and governance built in."

## Common Customer Questions

### "How does this compare to workspaces?"
**Stacks**: Shared lifecycle infrastructure (microservices, multi-region apps)  
**Workspaces**: Independent infrastructure with separate configs  

Use Stacks when components depend on each other and need coordinated deployment.

### "Can I use my existing modules?"
Yes! Modules stay unchanged (`.tf` files). Only the root module becomes `.tfcomponent.hcl` files.

### "What if Lambda ARN isn't available until after creation?"
Stacks automatically defer dependent resources (API Gateway) to next apply cycle. This is called **deferred changes**.

### "How do I add a new region?"
Add region to `deployments.tfdeploy.hcl` input. Stacks creates complete infrastructure there automatically.

### "What about secrets?"
Use the `store` block to reference HCP Terraform variable sets for sensitive values.

### "Can Stacks talk to each other?"
Yes! Use `publish_output` in upstream Stack, `upstream_input` in downstream Stack.

## Key Talking Points

1. **Zero code duplication** - `for_each` creates regional resources automatically
2. **Progressive guardrails** - Different approval rules per environment tier
3. **Component dependencies** - Automatic ordering and data passing
4. **Observable by default** - Rich outputs with console links and monitoring paths
5. **Enterprise-ready** - Tagging, validation, compliance built in

## Modification Patterns

### Add New Component
1. Create module directory (e.g., `./dynamodb`)
2. Add component block in `components.tfcomponent.hcl`
3. Use `for_each = var.regions` for multi-region
4. Add outputs to `outputs.tfcomponent.hcl`

### Add New Environment
1. Create `deployment_auto_approve` rules in `deployments.tfdeploy.hcl`
2. Create `deployment_group` with those rules
3. Add `deployment` block with environment-specific inputs
4. Assign to deployment group

### Change Region Configuration
Update `regions` input in deployment:
```hcl
deployment "production" {
  inputs = {
    regions = ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"]  # Add region here
    # ...
  }
}
```

## Troubleshooting

### "Provider not configured for component"
Ensure component `providers` block references correct provider:
```hcl
providers = {
  aws = provider.aws.configurations[each.value]
}
```

### "Cannot reference component output"
Check syntax: `component.<name>[<key>].<output>`  
Correct: `component.s3[each.value].bucket_id`  
Wrong: `component.s3.bucket_id[each.value]`

### "OIDC authentication failed"
Verify:
1. Role ARN is correct in deployment inputs
2. IAM trust policy allows HCP Terraform
3. `identity_token` audience matches IAM trust policy

## Quick Commands

```bash
terraform stacks init              # Initialize, download providers
terraform stacks validate          # Validate all configurations
terraform stacks fmt               # Format files
terraform stacks plan              # Plan all deployments
terraform stacks apply             # Apply changes
terraform stacks deployment-group list   # List deployment groups
```

## Success Metrics

After this demo, customers should understand:
1. How Stacks differ from workspaces
2. Component-based architecture benefits
3. Multi-region deployment patterns with `for_each`
4. Deployment groups for governance
5. How to migrate existing Terraform to Stacks

## Official Documentation Links
- **[Stacks Overview](https://developer.hashicorp.com/terraform/language/stacks)** - Core concepts and architecture
- **[Component Configuration](https://developer.hashicorp.com/terraform/language/stacks/component/config)** - Define Stack components
- **[Deployment Configuration](https://developer.hashicorp.com/terraform/language/stacks/deploy/config)** - Define deployments
- **[Declare Providers](https://developer.hashicorp.com/terraform/language/stacks/component/declare-providers)** - Provider setup patterns
- **[Manage Components](https://developer.hashicorp.com/terraform/language/stacks/component/manage)** - Add/remove components
- **[Pass Data Between Stacks](https://developer.hashicorp.com/terraform/language/stacks/deploy/pass-data)** - Stack dependencies
- **[Deployment Conditions](https://developer.hashicorp.com/terraform/language/stacks/deploy/conditions)** - Auto-approval rules
- **[CLI Commands](https://developer.hashicorp.com/terraform/cli/commands/stacks)** - Full command reference

## Stacks vs Traditional Terraform
- **Components**: Replace root modules - each `component` block sources a Terraform module
- **Deployments**: Define how many times to deploy Stack infrastructure with different inputs
- **Providers**: Use `config` blocks instead of direct configuration, support `for_each` meta-argument
- **CLI**: Use `terraform stacks` commands instead of `terraform plan/apply`
- **State**: Each deployment has isolated state, preventing cross-deployment interference

## Architecture Pattern
- **Multi-region deployment**: Uses `for_each = var.regions` across components and providers
- **Component dependencies**: Components reference each other's outputs using `component.<name>[<key>].<output>`
- **Dynamic providers**: Provider configurations created per region using `for_each = var.regions`
- **Shared lifecycle**: All components in a Stack share the same deployment lifecycle

## File Structure & Purpose
```
├── .terraform-version            # Required: Terraform v1.13.x+
├── components.tfcomponent.hcl    # Component definitions (replaces main.tf)
├── deployments.tfdeploy.hcl      # Deployment configurations per environment
├── providers.tfcomponent.hcl     # Provider configurations with aliases
├── variables.tfcomponent.hcl     # Stack-level input variables
├── outputs.tfcomponent.hcl       # Stack-level outputs for HCP Terraform UI
└── {vpc,instance,key_pair}/      # Traditional Terraform modules (.tf files)
```

## Critical Implementation Patterns

### Dynamic Multi-Region Providers
```hcl
provider "aws" "this" {
  for_each = var.regions  # Creates one provider per region
  config {
    region = each.value
    assume_role_with_web_identity {
      role_arn           = var.role_arn
      web_identity_token = var.identity_token
    }
  }
}
```

### Component Inter-Dependencies
```hcl
component "instance" {
  for_each = var.regions
  inputs = {
    # Reference outputs from other components
    network = {
      vpc_id             = component.vpc[each.value].vpc_id
      private_subnet_ids = component.vpc[each.value].private_subnet_ids
    }
    key_name = component.key_pair[each.value].key_name
  }
  providers = {
    aws = provider.aws.this[each.value]  # Use region-specific provider
  }
}
```

### OIDC Authentication Flow
- Uses `identity_token` blocks in deployment configuration
- Generates JWT tokens for Web Identity authentication
- No static AWS access keys - all authentication is dynamic
- Role ARN: `arn:aws:iam::258850230659:role/tfstacks-role`

## Development Workflow

### Essential Commands (v1.13.3+ required)
```bash
terraform stacks init         # Download providers, create lock file
terraform stacks validate     # Validate configuration syntax
terraform stacks fmt          # Format configuration files
terraform stacks plan         # Plan deployment changes
terraform stacks apply        # Apply deployment changes
```

### Deployment Management
- **Development**: Single region deployment for testing
- **Production**: Multi-region deployment with same components
- **Isolation**: Each deployment has separate state file
- **Cleanup**: Both deployments have `destroy = true` for tutorial purposes

## Stack Constraints & Limits
- Maximum 20 deployments per Stack
- Maximum 100 components per Stack
- Maximum 10,000 resources per Stack
- Deployment groups support only 1 deployment per group
- Up to 20 upstream Stack dependencies
- Up to 25 downstream Stack consumers

## Module Development Conventions
- Modules use standard `.tf` files (NOT `.tfcomponent.hcl`)
- Components cannot declare their own providers - all providers passed from Stack level
- Use community modules when possible (e.g., `terraform-aws-modules/vpc/aws`)
- Network data structure: `var.network.{vpc_id, private_subnet_ids, security_group_ids}`

## Common Modification Patterns
- **Add component**: Create `component` block + corresponding module directory
- **Remove component**: Delete `component` block + add `removed` block for cleanup
- **Add region**: Update `var.regions` in deployment inputs
- **Provider changes**: Update both `providers.tfcomponent.hcl` AND component `providers` blocks
- **Cross-component data**: Use `component.<name>.<output>` references

## Deferred Changes
Stacks automatically handle resource dependencies that can't be resolved in a single plan/apply cycle:

### What Gets Deferred
- **Kubernetes workloads**: CRDs must be deployed before resources that use them
- **Dynamic references**: Resources that depend on computed values from other components
- **Provider-specific limitations**: Some providers require multi-step provisioning

### How It Works
```hcl
# HCP Terraform automatically defers this if the EKS cluster isn't ready
component "k8s_app" {
  source = "./k8s-app"
  inputs = {
    cluster_endpoint = component.eks.cluster_endpoint  # May be deferred
  }
}
```

### Provider Support
- **Kubernetes**: v2.32.0+ supports deferred changes
- **AWS**: Most resources support immediate provisioning
- Check provider docs for specific deferred change support

## Deployment Groups & Auto-Approval
Deployment groups organize deployments and define auto-approval rules (Premium tier feature):

### Basic Deployment Group
```hcl
deployment_auto_approve "no_destroys" {
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Plan destroys ${context.plan.changes.remove} resources."
  }
}

deployment_group "production" {
  auto_approve_checks = [
    deployment_auto_approve.no_destroys
  ]
}

deployment "prod_us_east" {
  inputs = { region = "us-east-1" }
  deployment_group = deployment_group.production
}
```

### Available Context Variables
- `context.plan.changes.add` - Resources being created
- `context.plan.changes.change` - Resources being modified  
- `context.plan.changes.remove` - Resources being destroyed
- `context.plan.changes.total` - Total changes
- `context.success` - Whether operation succeeded

### Common Auto-Approval Patterns
```hcl
# Auto-approve if no changes
deployment_auto_approve "empty_plan" {
  check {
    condition = context.plan.changes.total == 0
    reason    = "No changes to apply"
  }
}

# Auto-approve small changes only
deployment_auto_approve "small_changes" {
  check {
    condition = context.plan.changes.total <= 5
    reason    = "Too many changes (${context.plan.changes.total}) for auto-approval"
  }
}
```

## Stack Dependencies & Data Passing
Share data between Stacks in the same HCP Terraform project:

### Publishing Outputs (Upstream Stack)
```hcl
# In network-stack/outputs.tfcomponent.hcl
output "vpc_id" {
  description = "VPC ID for application stacks"
  type        = string
  value       = component.vpc.vpc_id
}

# In network-stack/deployments.tfdeploy.hcl
publish_output "shared_vpc_id" {
  description = "VPC ID available to other stacks"
  value       = deployment.network.vpc_id
}

deployment "network" {
  inputs = { region = "us-east-1" }
}
```

### Consuming Outputs (Downstream Stack)
```hcl
# In app-stack/deployments.tfdeploy.hcl
upstream_input "network_stack" {
  type   = "stack"
  source = "app.terraform.io/my-org/my-project/network-stack"
}

deployment "application" {
  inputs = {
    vpc_id = upstream_input.network_stack.shared_vpc_id
    region = "us-east-1"
  }
}
```

### Dependency Triggers
- Upstream Stack changes automatically trigger downstream Stack runs
- Use `terraform stacks deployment-group watch` to monitor cascading deployments
- Maximum 20 upstream dependencies, 25 downstream consumers per Stack

## Common Troubleshooting

### Provider Configuration Issues
```bash
# Error: "provider not configured for component"
# Solution: Ensure component has providers block matching required providers
providers = {
  aws = provider.aws.this[each.value]
}
```

### Lock File Issues
```bash
# Error: "provider lock file is out of date"
# Solution: Upgrade lock file after provider version changes
terraform stacks init -upgrade
```

### Component Dependency Errors
```bash
# Error: "cannot reference component output"
# Solution: Check syntax - use component.<name>[<key>].<output>
# Correct: component.vpc[each.value].vpc_id
# Wrong:   component.vpc.vpc_id[each.value]
```

### OIDC Authentication Failures
```bash
# Error: "AssumeRoleWithWebIdentity failed"
# Solution: Verify role ARN, audience, and trust policy
# Check identity_token audience matches IAM role trust policy
identity_token "aws" {
  audience = ["terraform-stacks-private-preview"]  # Must match IAM
}
```

### State Lock Issues
```bash
# Error: "state is locked"
# Solution: Check for stuck runs in HCP Terraform UI
# Or use: terraform stacks deployment unlock <deployment-name>
```

## Quick Reference

### Minimal Stack Structure
```hcl
# providers.tfcomponent.hcl
required_providers {
  aws = { source = "hashicorp/aws", version = "~> 5.0" }
}
provider "aws" "main" {
  config { region = var.region }
}

# components.tfcomponent.hcl
component "app" {
  source = "./app"
  inputs = { name = var.app_name }
  providers = { aws = provider.aws.main }
}

# deployments.tfdeploy.hcl
deployment "dev" {
  inputs = { region = "us-east-1", app_name = "myapp-dev" }
}
```

### When to Use Stacks vs Workspaces

**Use Stacks when:**
- Managing infrastructure with shared lifecycle (microservices architecture)
- Deploying same configuration across multiple environments/regions
- Need automatic deferred change handling for complex dependencies
- Want to pass data between related but independent infrastructure

**Use Workspaces when:**
- Managing simple, independent infrastructure
- Each environment has significantly different configurations
- No complex inter-component dependencies
- Simpler approval workflows suffice

### File Extension Quick Guide
- `.tfcomponent.hcl` - Stack component configuration (providers, components, variables, outputs)
- `.tfdeploy.hcl` - Deployment configuration (deployments, identity tokens, deployment groups)
- `.tf` - Traditional Terraform modules (used inside component source directories)

## Known Issues & Tutorial Specifics
- Typo in `outputs.tfcomponent.hcl`: `intance_ids` should be `instance_ids`
- Security group allows SSH from `0.0.0.0/0` (demo purposes only)
- Hardcoded IAM role ARN for specific AWS account