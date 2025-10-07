#!/bin/bash
set -e

# Variables
AWS_REGION="${AWS_REGION:-eu-west-2}"
PROJECT_NAME="${PROJECT_NAME:-sg-farmers-app}"
ENVIRONMENT="${ENVIRONMENT:-production}"
DOMAIN_NAME="${DOMAIN_NAME:-your-domain.com}"

echo "Deploying SG Farmers App to AWS..."
echo "Region: $AWS_REGION"
echo "Environment: $ENVIRONMENT"
echo "Domain: $DOMAIN_NAME"

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed"
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        echo "Error: Terraform is not installed"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS credentials not configured"
        exit 1
    fi
    
    echo "Prerequisites check passed"
}

# Create S3 bucket for Terraform state
create_terraform_state_bucket() {
    local bucket_name="sg-farmers-terraform-state-$(date +%s)"
    echo "Creating Terraform state bucket: $bucket_name"
    
    aws s3 mb s3://$bucket_name --region $AWS_REGION
    aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket $bucket_name --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
    
    echo "Terraform state bucket created: $bucket_name"
    echo "Update terraform/main.tf with this bucket name"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f terraform.tfvars ]; then
        echo "Creating terraform.tfvars..."
        cat > terraform.tfvars << EOF
aws_region   = "$AWS_REGION"
environment  = "$ENVIRONMENT"
project_name = "$PROJECT_NAME"
domain_name  = "$DOMAIN_NAME"
EOF
    fi
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply infrastructure
    terraform apply tfplan
    
    cd ..
    echo "Infrastructure deployed successfully"
}

# Build and push Docker images
build_and_push_images() {
    echo "Building and pushing Docker images..."
    chmod +x scripts/build-and-push.sh
    ./scripts/build-and-push.sh
}

# Update ECS services
update_ecs_services() {
    echo "Updating ECS services..."
    
    local cluster_name="${PROJECT_NAME}-cluster"
    
    # Update Registration API service
    aws ecs update-service \
        --cluster $cluster_name \
        --service "${PROJECT_NAME}-registration-api" \
        --force-new-deployment \
        --region $AWS_REGION
    
    # Update Search API service
    aws ecs update-service \
        --cluster $cluster_name \
        --service "${PROJECT_NAME}-search-api" \
        --force-new-deployment \
        --region $AWS_REGION
    
    # Update Chat API service
    aws ecs update-service \
        --cluster $cluster_name \
        --service "${PROJECT_NAME}-chat-api" \
        --force-new-deployment \
        --region $AWS_REGION
    
    echo "ECS services updated successfully"
}

# Deploy frontend to S3 and CloudFront
deploy_frontend() {
    echo "Deploying frontend..."
    
    # Get S3 bucket name from Terraform output
    cd terraform
    local bucket_name=$(terraform output -raw frontend_bucket_name)
    local distribution_id=$(terraform output -raw cloudfront_distribution_id)
    cd ..
    
    # Build React application
    cd services/frontend
    npm install
    npm run build
    
    # Sync to S3
    aws s3 sync build/ s3://$bucket_name/ --delete
    
    # Invalidate CloudFront cache
    aws cloudfront create-invalidation --distribution-id $distribution_id --paths "/*"
    
    cd ../..
    echo "Frontend deployed successfully"
}

# Wait for services to be healthy
wait_for_services() {
    echo "Waiting for services to be healthy..."
    
    local cluster_name="${PROJECT_NAME}-cluster"
    local services=("${PROJECT_NAME}-registration-api" "${PROJECT_NAME}-search-api" "${PROJECT_NAME}-chat-api")
    
    for service in "${services[@]}"; do
        echo "Waiting for $service to be stable..."
        aws ecs wait services-stable --cluster $cluster_name --services $service --region $AWS_REGION
        echo "$service is stable"
    done
}

# Verify deployment
verify_deployment() {
    echo "Verifying deployment..."
    
    # Get ALB DNS name
    cd terraform
    local alb_dns=$(terraform output -raw alb_dns_name)
    cd ..
    
    # Test health endpoints
    echo "Testing health endpoints..."
    curl -f "http://$alb_dns/api/farmers/health" || echo "Registration API health check failed"
    curl -f "http://$alb_dns/api/search/health" || echo "Search API health check failed"
    curl -f "http://$alb_dns/api/chat/health" || echo "Chat API health check failed"
    
    echo "Deployment verification completed"
    echo "Application URL: https://$DOMAIN_NAME"
    echo "ALB URL: http://$alb_dns"
}

# Main deployment flow
main() {
    check_prerequisites
    
    case "${1:-all}" in
        "infrastructure")
            deploy_infrastructure
            ;;
        "images")
            build_and_push_images
            ;;
        "services")
            update_ecs_services
            wait_for_services
            ;;
        "frontend")
            deploy_frontend
            ;;
        "verify")
            verify_deployment
            ;;
        "all")
            deploy_infrastructure
            build_and_push_images
            update_ecs_services
            deploy_frontend
            wait_for_services
            verify_deployment
            ;;
        *)
            echo "Usage: $0 [infrastructure|images|services|frontend|verify|all]"
            exit 1
            ;;
    esac
    
    echo "Deployment completed successfully!"
}

main "$@"