#!/bin/bash
set -e

# Variables
AWS_REGION="${AWS_REGION:-eu-west-2}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
PROJECT_NAME="${PROJECT_NAME:-sg-farmers-app}"
VERSION="${VERSION:-latest}"

echo "Building and pushing Docker images for SG Farmers App..."
echo "Registry: $ECR_REGISTRY"
echo "Project: $PROJECT_NAME"
echo "Version: $VERSION"

# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Create ECR repositories if they don't exist
create_repo() {
    local repo_name=$1
    echo "Checking repository: $repo_name"
    
    if ! aws ecr describe-repositories --repository-names "$repo_name" --region $AWS_REGION >/dev/null 2>&1; then
        echo "Creating repository: $repo_name"
        aws ecr create-repository --repository-name "$repo_name" --region $AWS_REGION
        
        # Set lifecycle policy to keep only 10 images
        aws ecr put-lifecycle-policy --repository-name "$repo_name" --region $AWS_REGION --lifecycle-policy-text '{
            "rules": [
                {
                    "rulePriority": 1,
                    "description": "Keep only 10 images",
                    "selection": {
                        "tagStatus": "any",
                        "countType": "imageCountMoreThan",
                        "countNumber": 10
                    },
                    "action": {
                        "type": "expire"
                    }
                }
            ]
        }'
    else
        echo "Repository $repo_name already exists"
    fi
}

# Create repositories
create_repo "${PROJECT_NAME}-registration-api"
create_repo "${PROJECT_NAME}-search-api"
create_repo "${PROJECT_NAME}-chat-api"
create_repo "${PROJECT_NAME}-frontend"

# Build and push Registration API
echo "Building Registration API..."
cd services/registration-api
docker build -t $ECR_REGISTRY/${PROJECT_NAME}-registration-api:$VERSION .
docker push $ECR_REGISTRY/${PROJECT_NAME}-registration-api:$VERSION
echo "Registration API pushed successfully"

# Build and push Search API
echo "Building Search API..."
cd ../search-api
docker build -t $ECR_REGISTRY/${PROJECT_NAME}-search-api:$VERSION .
docker push $ECR_REGISTRY/${PROJECT_NAME}-search-api:$VERSION
echo "Search API pushed successfully"

# Build and push Chat API
echo "Building Chat API..."
cd ../chat-api
docker build -t $ECR_REGISTRY/${PROJECT_NAME}-chat-api:$VERSION .
docker push $ECR_REGISTRY/${PROJECT_NAME}-chat-api:$VERSION
echo "Chat API pushed successfully"

# Build and push Frontend
echo "Building Frontend..."
cd ../frontend
docker build -t $ECR_REGISTRY/${PROJECT_NAME}-frontend:$VERSION .
docker push $ECR_REGISTRY/${PROJECT_NAME}-frontend:$VERSION
echo "Frontend pushed successfully"

cd ../..

echo "All images built and pushed successfully!"
echo ""
echo "Image URIs:"
echo "Registration API: $ECR_REGISTRY/${PROJECT_NAME}-registration-api:$VERSION"
echo "Search API: $ECR_REGISTRY/${PROJECT_NAME}-search-api:$VERSION"
echo "Chat API: $ECR_REGISTRY/${PROJECT_NAME}-chat-api:$VERSION"
echo "Frontend: $ECR_REGISTRY/${PROJECT_NAME}-frontend:$VERSION"