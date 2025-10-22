# Terraform Best Practices - Enterprise Structure

## 📁 Recommended Directory Structure

```
terraform/
├── environments/                    # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf                 # Environment entry point
│   │   ├── variables.tf            # Environment-specific variables
│   │   ├── terraform.tfvars        # Development values
│   │   └── backend.tf              # Remote state configuration
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/                        # Reusable infrastructure modules
│   ├── networking/
│   │   ├── main.tf                 # VPC, subnets, gateways
│   │   ├── variables.tf            # Module inputs
│   │   ├── outputs.tf              # Module outputs
│   │   └── README.md               # Module documentation
│   ├── security/
│   │   ├── main.tf                 # Security groups, WAF, ACM
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── compute/
│   │   ├── main.tf                 # ECS cluster, services, ALB
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── database/
│   │   ├── main.tf                 # RDS, ElastiCache, OpenSearch
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── monitoring/
│       ├── main.tf                 # CloudWatch, X-Ray, alarms
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── shared/                         # Shared configurations
│   ├── locals.tf                   # Common local values
│   ├── data.tf                     # Data sources
│   └── versions.tf                 # Provider versions
└── scripts/                        # Automation scripts
    ├── deploy.sh                   # Deployment script
    ├── destroy.sh                  # Cleanup script
    └── validate.sh                 # Validation script
```

## 🏗️ Module Design Principles

### 1. Single Responsibility
Each module handles one logical infrastructure component:
- **networking**: VPC, subnets, routing
- **security**: Security groups, WAF, certificates
- **compute**: ECS, ALB, auto-scaling
- **database**: RDS, Redis, search engines
- **monitoring**: Logs, metrics, alerts

### 2. Input/Output Pattern
```hcl
# Module inputs (variables.tf)
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Module outputs (outputs.tf)
output "vpc_id" {
  description = "VPC ID for other modules"
  value       = aws_vpc.main.id
}
```

### 3. Environment Separation
```hcl
# environments/prod/main.tf
module "networking" {
  source = "../../modules/networking"
  
  environment     = "prod"
  vpc_cidr       = "10.0.0.0/16"
  az_count       = 3
  enable_nat_gw  = true
}
```

## 📋 File Responsibilities

### Environment Files

#### `environments/{env}/main.tf`
```hcl
# Environment entry point - orchestrates modules
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Module calls
module "networking" {
  source = "../../modules/networking"
  # ... variables
}

module "security" {
  source = "../../modules/security"
  vpc_id = module.networking.vpc_id
  # ... other variables
}
```

#### `environments/{env}/variables.tf`
```hcl
# Environment-specific variable definitions
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "sg-farmers-app"
}
```

#### `environments/{env}/terraform.tfvars`
```hcl
# Environment-specific values
aws_region   = "eu-west-2"
environment  = "prod"
project_name = "sg-farmers-app"

# Networking
vpc_cidr     = "10.0.0.0/16"
az_count     = 3

# Database
db_instance_class = "db.t3.medium"
db_allocated_storage = 100

# ECS
ecs_cpu    = 512
ecs_memory = 1024
min_capacity = 2
max_capacity = 10
```

#### `environments/{env}/backend.tf`
```hcl
# Remote state configuration
terraform {
  backend "s3" {
    bucket         = "sg-farmers-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Module Files

#### `modules/{module}/main.tf`
```hcl
# Module implementation
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Local values for complex expressions
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  common_tags = {
    Environment = var.environment
    Module      = "networking"
  }
}
```

#### `modules/{module}/variables.tf`
```hcl
# Module input variables with validation
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
  
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "AZ count must be between 2 and 6."
  }
}
```

#### `modules/{module}/outputs.tf`
```hcl
# Module outputs for other modules
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}
```

## 🔧 Best Practices Implementation

### 1. Variable Validation
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

### 2. Resource Naming Convention
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.team_name
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
  tags = local.common_tags
}
```

### 3. Data Sources
```hcl
# shared/data.tf
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
```

### 4. Version Constraints
```hcl
# shared/versions.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
```

## 🚀 Deployment Workflow

### 1. Environment Initialization
```bash
# Navigate to environment
cd terraform/environments/prod

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"
```

### 2. Module Development
```bash
# Test module in isolation
cd terraform/modules/networking
terraform init
terraform validate

# Format code
terraform fmt -recursive

# Generate documentation
terraform-docs markdown . > README.md
```

### 3. State Management
```bash
# List state resources
terraform state list

# Import existing resource
terraform import aws_vpc.main vpc-12345678

# Move resource in state
terraform state mv aws_instance.old aws_instance.new
```

## 🔒 Security Best Practices

### 1. Sensitive Variables
```hcl
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

### 2. Remote State Encryption
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:123456789:key/12345"
    dynamodb_table = "terraform-locks"
  }
}
```

### 3. IAM Policies
```hcl
data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      aws_secretsmanager_secret.db_password.arn,
      aws_kms_key.secrets.arn
    ]
  }
}
```

## 📊 Interview Key Points

### 1. **Module Design**
- Single responsibility principle
- Reusable across environments
- Clear input/output contracts
- Proper documentation

### 2. **State Management**
- Remote state with S3 + DynamoDB
- State locking for team collaboration
- Environment separation
- Backup strategies

### 3. **Security**
- Sensitive variable handling
- Least privilege IAM
- Encryption at rest/transit
- Secret management

### 4. **CI/CD Integration**
- Automated validation
- Plan review process
- Gradual rollouts
- Rollback procedures

### 5. **Troubleshooting**
- State file corruption recovery
- Resource drift detection
- Dependency resolution
- Import existing resources

This structure demonstrates enterprise-level Terraform organization with proper separation of concerns, reusability, and maintainability.