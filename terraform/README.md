# SG Farmers App - Terraform Infrastructure

## 🏗️ Enterprise-Grade Infrastructure as Code

This repository contains the complete AWS infrastructure for the SG Farmers App, organized using Terraform best practices with modular architecture, environment separation, and enterprise-level security.

## 📁 Directory Structure

```
terraform/
├── environments/           # Environment-specific configurations
│   ├── dev/               # Development environment
│   ├── staging/           # Staging environment
│   └── prod/              # Production environment
├── modules/               # Reusable infrastructure modules
│   ├── networking/        # VPC, subnets, routing
│   ├── security/          # Security groups, WAF, ACM
│   ├── compute/           # ECS, ALB, auto-scaling
│   ├── database/          # RDS, ElastiCache, OpenSearch
│   └── monitoring/        # CloudWatch, X-Ray, alarms
├── shared/                # Shared configurations
└── scripts/               # Deployment automation
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- S3 bucket for remote state storage
- DynamoDB table for state locking

### Deploy Infrastructure

```bash
# Navigate to environment
cd environments/prod

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"
```

### Using Deployment Script

```bash
# Make script executable
chmod +x scripts/deploy.sh

# Deploy to production
./scripts/deploy.sh prod apply

# Plan development changes
./scripts/deploy.sh dev plan

# Destroy staging environment
./scripts/deploy.sh staging destroy
```

## 🏗️ Module Architecture

### Networking Module
- **VPC** with public, private, and database subnets
- **Multi-AZ** deployment across 2-3 availability zones
- **NAT Gateways** for private subnet internet access
- **Route Tables** with proper routing configuration

### Security Module
- **Security Groups** with least privilege access
- **AWS WAF** with OWASP protection rules
- **SSL Certificates** via AWS Certificate Manager
- **IAM Roles** with minimal required permissions

### Compute Module
- **ECS Fargate** cluster for containerized services
- **Application Load Balancer** with path-based routing
- **Auto Scaling** based on CPU/memory metrics
- **Service Discovery** for microservices communication

### Database Module
- **RDS PostgreSQL** with Multi-AZ deployment
- **ElastiCache Redis** for caching and sessions
- **OpenSearch** for search functionality
- **Automated backups** and point-in-time recovery

### Monitoring Module
- **CloudWatch** metrics, logs, and dashboards
- **X-Ray** distributed tracing
- **Custom alarms** for proactive monitoring
- **SNS notifications** for critical alerts

## 🌍 Environment Configurations

### Development
- **Cost-optimized** with smaller instance sizes
- **Single AZ** deployment to reduce costs
- **No NAT Gateway** (public subnets only)
- **Minimal auto-scaling** (1-3 tasks)

### Staging
- **Production-like** configuration for testing
- **Multi-AZ** deployment for reliability testing
- **Moderate scaling** (1-5 tasks)
- **Full monitoring** enabled

### Production
- **High availability** with Multi-AZ deployment
- **Auto-scaling** (2-10 tasks) for peak loads
- **Enhanced monitoring** and alerting
- **Automated backups** and disaster recovery

## 🔐 Security Best Practices

### State Management
- **Remote state** stored in encrypted S3 bucket
- **State locking** with DynamoDB table
- **Versioning** enabled for state file recovery
- **Access logging** for audit trails

### Secrets Management
- **AWS Secrets Manager** for sensitive data
- **Automatic rotation** for database passwords
- **IAM policies** with least privilege access
- **Encryption** at rest and in transit

### Network Security
- **Private subnets** for application and database tiers
- **Security groups** with minimal required ports
- **NACLs** for additional network-level protection
- **VPC Flow Logs** for network monitoring

## 📊 Cost Optimization

### Resource Sizing
- **Right-sized** instances based on environment
- **Reserved Instances** for predictable workloads
- **Spot Instances** for development environments
- **Auto-scaling** to match demand

### Storage Optimization
- **GP3 volumes** for better price/performance
- **S3 Lifecycle policies** for log archival
- **Database storage** auto-scaling
- **CloudWatch log retention** policies

## 🔧 Maintenance & Operations

### Regular Tasks
- **Weekly**: Review CloudWatch metrics and costs
- **Monthly**: Update Terraform providers and modules
- **Quarterly**: Security audit and compliance review
- **Annually**: Disaster recovery testing

### Troubleshooting
```bash
# Check Terraform state
terraform state list

# Import existing resource
terraform import aws_vpc.main vpc-12345678

# Refresh state
terraform refresh

# Show current state
terraform show
```

### State Recovery
```bash
# List state backups
aws s3 ls s3://terraform-state-bucket/prod/

# Restore from backup
aws s3 cp s3://terraform-state-bucket/prod/terraform.tfstate.backup terraform.tfstate
```

## 📈 Monitoring & Alerting

### Key Metrics
- **Application**: Response time, error rate, throughput
- **Infrastructure**: CPU, memory, disk, network
- **Database**: Connection count, query performance
- **Cost**: Daily spend, resource utilization

### Alert Thresholds
- **Critical**: Error rate > 5%, Database CPU > 90%
- **Warning**: Response time > 1s, Memory > 80%
- **Info**: New deployments, scaling events

## 🤝 Contributing

### Development Workflow
1. Create feature branch
2. Make infrastructure changes
3. Test in development environment
4. Create pull request with plan output
5. Review and approve changes
6. Deploy to staging for validation
7. Deploy to production

### Code Standards
- **Terraform fmt** for consistent formatting
- **Variable validation** for input constraints
- **Resource tagging** for cost allocation
- **Documentation** for all modules

## 📞 Support

### Emergency Contacts
- **DevOps Team**: devops@sg-farmers-app.com
- **On-Call**: +65-XXXX-XXXX
- **Slack**: #infrastructure-alerts

### Runbooks
- **Database Failover**: docs/runbooks/db-failover.md
- **ECS Service Recovery**: docs/runbooks/ecs-recovery.md
- **SSL Certificate Renewal**: docs/runbooks/ssl-renewal.md

---

**Infrastructure managed with ❤️ by the DevOps Team**