# Grant Registration Service - Terraform Infrastructure

This Terraform configuration deploys the complete AWS infrastructure for the Grant Registration Service.

## Architecture Components

- **VPC** with public/private subnets across 2 AZs
- **ECS Fargate** cluster for containerized services
- **RDS PostgreSQL** Multi-AZ database
- **ElastiCache Redis** for caching
- **OpenSearch** for search functionality
- **S3 + CloudFront** for frontend hosting
- **Application Load Balancer** with WAF protection
- **Route53** for DNS management
- **ACM** for SSL certificates
- **SQS/SNS** for messaging
- **Lambda + API Gateway** for chat functionality
- **CloudWatch** for monitoring and logging

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed
3. Domain registered in Route53
4. S3 bucket for Terraform state (update in main.tf)

## Deployment Steps

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Create Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

### 5. Verify Deployment

```bash
terraform output
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `eu-west-2` |
| `environment` | Environment name | `production` |
| `project_name` | Project name prefix | `grant-registration-service` |
| `domain_name` | Domain name for the application | Required |

## Post-Deployment Steps

1. **Build and push Docker images** to ECR repositories
2. **Deploy application code** to ECS services
3. **Upload frontend assets** to S3 bucket
4. **Configure DNS records** if not using Route53
5. **Set up monitoring alerts** and notification endpoints

## Security Features

- All traffic encrypted with TLS 1.3
- WAF protection against common attacks
- VPC with private subnets for backend services
- Security groups with least privilege access
- Secrets stored in AWS Secrets Manager
- Database and cache encryption at rest

## Monitoring

- CloudWatch dashboards for key metrics
- Alarms for CPU, memory, and response times
- Centralized logging with retention policies
- X-Ray tracing for distributed requests

## Cost Optimization

- Auto-scaling based on demand
- Reserved capacity for baseline load
- S3 lifecycle policies for log archival
- Right-sized instances based on workload

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data.

## Support

For issues or questions, refer to the main deployment guide or contact the development team.