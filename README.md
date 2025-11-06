# Enterprise Serverless API - Terraform Stacks Demo

> **A comprehensive demonstration of Terraform Stacks capabilities for enterprise infrastructure management**

This repository showcases **Terraform Stacks** in action, demonstrating how modern infrastructure teams can manage complex, multi-region serverless applications with enterprise-grade governance, automation, and observability.

## 🎯 What This Demo Shows

This is not just another serverless API example—it's a complete demonstration of Terraform Stacks' enterprise capabilities:

### Core Stacks Features Demonstrated

✅ **Component-Based Architecture** - Modular infrastructure with S3, Lambda, and API Gateway components  
✅ **Multi-Region Deployment** - Dynamic provider configuration with `for_each` across multiple AWS regions  
✅ **Component Dependencies** - Proper inter-component data flow (S3 → Lambda → API Gateway)  
✅ **Deployment Groups** - Environment-specific orchestration rules  
✅ **Auto-Approval Guardrails** - Progressive restrictions from dev to production  
✅ **Environment Isolation** - Separate state files for dev, test, staging, and production  
✅ **Dynamic Provider Configuration** - OIDC authentication with Web Identity tokens  
✅ **Comprehensive Outputs** - Observable infrastructure with console links and monitoring data  
✅ **Variable Validation** - Enterprise-grade input validation and type safety  
✅ **Locals for Shared Logic** - DRY principles with computed values and naming conventions  
✅ **Enterprise Tagging Strategy** - Cost allocation, compliance, and governance tags  

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Terraform Stacks                            │
│  ┌────────────┬────────────┬────────────┬────────────┐         │
│  │    Dev     │    Test    │  Staging   │ Production │         │
│  │  (us-east) │  (us-east) │(us-east/   │(us-east/   │         │
│  │            │            │ us-west)   │ us-west/   │         │
│  │            │            │            │ eu-west)   │         │
│  └─────┬──────┴─────┬──────┴──────┬─────┴──────┬─────┘         │
│        │            │             │            │                │
│   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐  ┌────▼────┐          │
│   │Component│  │Component│  │Component│  │Component│          │
│   │  Stack  │  │  Stack  │  │  Stack  │  │  Stack  │          │
│   └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘          │
└────────┼───────────┼───────────┼───────────┼──────────────────┘
         │           │           │           │
    ┌────▼───────────▼───────────▼───────────▼────┐
    │           AWS Infrastructure                  │
    │  ┌─────┐    ┌────────┐    ┌──────────────┐  │
    │  │ S3  │───▶│ Lambda │◀───│ API Gateway  │  │
    │  └─────┘    └────────┘    └──────────────┘  │
    │   Stores      Executes       Exposes HTTP    │
    │   code        function        endpoint        │
    └───────────────────────────────────────────────┘
```

### Component Workflow

1. **S3 Component** - Creates versioned bucket for Lambda deployment packages
2. **Lambda Component** - Packages Ruby function, uploads to S3, creates Lambda function
3. **API Gateway Component** - Exposes HTTP endpoint to invoke Lambda function

Each component is deployed **per region**, creating complete, isolated stacks.

## 🚀 Demo Walkthrough

### Prerequisites

1. **HCP Terraform Account** with Stacks access (GA release)
2. **AWS Account(s)** with IAM roles configured for OIDC
3. **Terraform CLI** v1.13.3 or later

### Step 1: Understanding the Stack Structure

```bash
├── components.tfcomponent.hcl      # Component definitions (S3, Lambda, API Gateway)
├── deployments.tfdeploy.hcl        # 4 environments with deployment groups
├── providers.tfcomponent.hcl       # Dynamic AWS providers per region
├── variables.tfcomponent.hcl       # Validated input variables
├── outputs.tfcomponent.hcl         # Observable outputs
├── locals.tfcomponent.hcl          # Shared configuration logic
└── {s3,lambda,api-gateway}/        # Traditional Terraform modules
```

**Key Point**: `.tfcomponent.hcl` files replace traditional root modules, while `.tf` files remain in sourced modules.

### Step 2: Examine Deployment Groups & Guardrails

Open `deployments.tfdeploy.hcl` and review the auto-approval rules:

- **Dev**: Allows up to 20 changes (rapid iteration)
- **Test**: Max 10 changes, no resource destruction
- **Staging**: Max 5 changes, strict guardrails
- **Production**: Max 3 changes, no destroys, success checks

**Demo Point**: This codifies your change management process!

### Step 3: Configure Authentication

Each environment requires an IAM role ARN. Update `deployments.tfdeploy.hcl`:

```hcl
deployment "dev" {
  inputs = {
    role_arn = "arn:aws:iam::123456789012:role/terraform-stacks-dev"
    # ...
  }
}
```

**Best Practice**: Use separate AWS accounts per environment.

### Step 4: Initialize and Validate

```bash
terraform stacks init       # Download providers, create lock file
terraform stacks validate   # Validate configuration
terraform stacks fmt        # Format files
```

### Step 5: Plan Deployments

```bash
terraform stacks plan
```

**Observe**:
- Each deployment plans separately
- Multi-region deployments show provider configurations per region
- Component dependencies are resolved automatically

### Step 6: Deploy to Dev First

Apply the dev deployment to test:

```bash
terraform stacks apply
```

**HCP Terraform will**:
1. Auto-approve if changes meet dev guardrails (≤20 changes)
2. Deploy S3 → Lambda → API Gateway in dependency order
3. Show outputs including API endpoint URLs

### Step 7: Test the API

From the outputs, grab an API endpoint and test:

```bash
curl "https://abc123.execute-api.us-east-1.amazonaws.com/serverless_lambda_stage/hello?name=Demo"
```

**Response**: `{"message": "Hello Demo!"}`

### Step 8: Promote Through Environments

As confidence grows, deployments progress:

1. **Test** - Single region, stricter guardrails
2. **Staging** - Multi-region (us-east-1, us-west-2), pre-prod testing
3. **Production** - Three regions, strictest guardrails

**Demo Point**: Same Stack configuration, different inputs and guardrails!

### Step 9: Observe Component Expansion

Check how `for_each = var.regions` creates:

```hcl
component "lambda" {
  for_each = var.regions  # Creates: lambda["us-east-1"], lambda["us-west-2"], etc.
  
  inputs = {
    bucket_id = component.s3[each.value].bucket_id  # Component dependency
  }
  
  providers = {
    aws = provider.aws.configurations[each.value]  # Region-specific provider
  }
}
```

**Result**: Automatic multi-region deployment with zero code duplication!

### Step 10: Explore Outputs

HCP Terraform UI shows rich outputs:

- **API Endpoints** - Per-region invoke URLs with test instructions
- **AWS Console Links** - Direct links to Lambda, API Gateway, S3
- **CloudWatch Log Groups** - Monitoring and debugging paths
- **Resource ARNs** - For CI/CD integration

## 📊 Key Talking Points for Customers

### 1. **"How is this different from Terraform workspaces?"**

**Stacks** manage infrastructure with **shared lifecycle** (microservices, multi-region apps)  
**Workspaces** manage **independent** infrastructure with separate configurations

Stacks excel when you need:
- Same config, multiple deployments (environments/regions)
- Component dependencies (S3 → Lambda → API Gateway)
- Progressive deployment with guardrails
- Automatic deferred change handling

### 2. **"What about existing Terraform code?"**

Your existing **modules remain unchanged** (`.tf` files)! Only the root module is replaced with `.tfcomponent.hcl` files. Migration path:

1. Keep your modules as-is
2. Create `components.tfcomponent.hcl` sourcing those modules
3. Define `deployments.tfdeploy.hcl` for environments
4. Add deployment groups for guardrails

### 3. **"How do deployment groups help compliance?"**

Deployment groups **codify change management**:

```hcl
deployment_auto_approve "prod_strict" {
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Production prohibits resource destruction"
  }
}
```

This ensures:
- Production changes require manual approval for destroys
- Test environments can iterate faster
- Audit trail of what was auto-approved vs. manual

### 4. **"What about cost management?"**

Comprehensive tagging strategy in `locals.tfcomponent.hcl`:

- **Cost allocation** by environment and cost center
- **Compliance tags** for production workloads
- **Resource management** tags for automation

Plus, outputs provide visibility into resource consumption.

### 5. **"How does this scale?"**

Current limits (generous for most use cases):
- 20 deployments per Stack
- 100 components per Stack
- 10,000 resources per Stack
- Multi-region with `for_each` provides horizontal scaling

For massive scale: Use multiple Stacks with data passing via `publish_output`/`upstream_input`.

## 🔧 Advanced Features to Explore

### Deferred Changes
When Lambda ARN isn't available until after creation, Stacks automatically defers dependent resources.

### Stack Dependencies
Create a network Stack that publishes VPC outputs, consumed by this application Stack.

### Store Block
Reference HCP Terraform variable sets for sensitive values:

```hcl
store "varset" "api_keys" {
  name = "production-secrets"
}
```

## 📚 Additional Resources

- [Terraform Stacks Documentation](https://developer.hashicorp.com/terraform/language/stacks)
- [Stack CLI Commands](https://developer.hashicorp.com/terraform/cli/commands/stacks)
- [Deployment Groups Guide](https://developer.hashicorp.com/terraform/language/stacks/deploy/conditions)

## 🤝 Contributing

This is a demo repository. For improvements:

1. Fork the repository
2. Create a feature branch
3. Test with `terraform stacks validate`
4. Submit a pull request

## 📄 License

This project is licensed under the MPL-2.0 License - see the [LICENSE](LICENSE) file for details.

---

**Ready to see Stacks in action? Clone this repo and start with Step 1!**
