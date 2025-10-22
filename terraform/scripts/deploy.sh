#!/bin/bash

# SG Farmers App - Terraform Deployment Script
# Usage: ./deploy.sh <environment> [plan|apply|destroy]

set -e

ENVIRONMENT=${1:-prod}
ACTION=${2:-plan}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../environments/$ENVIRONMENT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy|validate|fmt)$ ]]; then
    error "Invalid action: $ACTION. Must be plan, apply, destroy, validate, or fmt."
fi

# Check if Terraform directory exists
if [[ ! -d "$TERRAFORM_DIR" ]]; then
    error "Terraform directory not found: $TERRAFORM_DIR"
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    error "AWS CLI not configured or credentials invalid"
fi

log "Starting Terraform $ACTION for $ENVIRONMENT environment"

# Navigate to environment directory
cd "$TERRAFORM_DIR"

# Initialize Terraform
log "Initializing Terraform..."
terraform init -upgrade

# Validate configuration
log "Validating Terraform configuration..."
terraform validate

# Format code
if [[ "$ACTION" == "fmt" ]]; then
    log "Formatting Terraform code..."
    terraform fmt -recursive ../../
    log "Terraform formatting completed"
    exit 0
fi

# Plan or Apply
case "$ACTION" in
    "plan")
        log "Creating Terraform plan..."
        terraform plan -var-file="terraform.tfvars" -out="tfplan"
        log "Terraform plan completed. Review the plan above."
        ;;
    "apply")
        log "Applying Terraform configuration..."
        if [[ -f "tfplan" ]]; then
            terraform apply "tfplan"
        else
            terraform apply -var-file="terraform.tfvars" -auto-approve
        fi
        log "Terraform apply completed successfully"
        ;;
    "destroy")
        warn "This will destroy all resources in $ENVIRONMENT environment!"
        read -p "Are you sure? Type 'yes' to continue: " -r
        if [[ $REPLY == "yes" ]]; then
            log "Destroying Terraform resources..."
            terraform destroy -var-file="terraform.tfvars" -auto-approve
            log "Terraform destroy completed"
        else
            log "Destroy cancelled"
        fi
        ;;
    "validate")
        log "Terraform validation completed successfully"
        ;;
esac

log "Terraform $ACTION completed for $ENVIRONMENT environment"