# SG Farmers App - AWS Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                     │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              ROUTE 53 (DNS)                                    │
│                          sg-farmers-app.com                                    │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         AWS CERTIFICATE MANAGER                                │
│                            SSL/TLS Certificates                                │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
        ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
        │   CLOUDFRONT    │  │      WAF        │  │   API GATEWAY   │
        │   (Frontend)    │  │  Protection     │  │   (Optional)    │
        │                 │  │                 │  │                 │
        └─────────────────┘  └─────────────────┘  └─────────────────┘
                    │                   │                   │
                    ▼                   ▼                   ▼
        ┌─────────────────┐  ┌─────────────────────────────────────┐
        │   S3 BUCKET     │  │     APPLICATION LOAD BALANCER      │
        │  (Static Web)   │  │         (ALB + Target Groups)      │
        │                 │  │                                     │
        └─────────────────┘  └─────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                         │
│                              10.0.0.0/16                                       │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                          PUBLIC SUBNETS                                 │   │
│  │                                                                         │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │   │
│  │  │   AZ-1a         │  │   AZ-1b         │  │   NAT GATEWAY   │        │   │
│  │  │ 10.0.1.0/24     │  │ 10.0.2.0/24     │  │   (Multi-AZ)    │        │   │
│  │  │                 │  │                 │  │                 │        │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘        │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         PRIVATE SUBNETS                                 │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    ECS FARGATE CLUSTER                         │   │   │
│  │  │                                                                 │   │   │
│  │  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │   │   │
│  │  │  │Registration │ │  Search     │ │   Chat      │              │   │   │
│  │  │  │    API      │ │   API       │ │   API       │              │   │   │
│  │  │  │   :3000     │ │  :3001      │ │  :3002      │              │   │   │
│  │  │  │             │ │             │ │             │              │   │   │
│  │  │  └─────────────┘ └─────────────┘ └─────────────┘              │   │   │
│  │  │                                                                 │   │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐   │   │   │
│  │  │  │              AUTO SCALING GROUPS                       │   │   │   │
│  │  │  │         (CPU/Memory based scaling)                     │   │   │   │
│  │  │  └─────────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                      DATABASE TIER                             │   │   │
│  │  │                                                                 │   │   │
│  │  │  ┌─────────────────┐              ┌─────────────────┐          │   │   │
│  │  │  │   RDS POSTGRES  │              │  ELASTICACHE    │          │   │   │
│  │  │  │   Multi-AZ      │              │     REDIS       │          │   │   │
│  │  │  │   Primary/      │              │   Cluster Mode  │          │   │   │
│  │  │  │   Standby       │              │                 │          │   │   │
│  │  │  │                 │              │                 │          │   │   │
│  │  │  └─────────────────┘              └─────────────────┘          │   │   │
│  │  │                                                                 │   │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐   │   │   │
│  │  │  │                DB SUBNET GROUP                         │   │   │   │
│  │  │  │            10.0.10.0/24, 10.0.11.0/24                 │   │   │   │
│  │  │  └─────────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SUPPORTING SERVICES                               │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │   CLOUDWATCH    │  │  SECRETS MGR    │  │      ECR        │                │
│  │   Monitoring    │  │   Database      │  │  Docker Images  │                │
│  │   Logging       │  │   API Keys      │  │                 │                │
│  │   Alerts        │  │   JWT Secrets   │  │                 │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │      SNS        │  │      SQS        │  │    X-RAY        │                │
│  │  Notifications  │  │   Message       │  │   Tracing       │                │
│  │                 │  │   Queues        │  │                 │                │
│  │                 │  │                 │  │                 │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                                DATA FLOW                                       │
│                                                                                 │
│  User Request → Route53 → CloudFront/ALB → ECS Services → RDS/Redis            │
│                                                                                 │
│  1. Frontend (React) served via CloudFront from S3                             │
│  2. API requests routed through ALB to ECS Fargate services                    │
│  3. Services communicate with PostgreSQL and Redis in private subnets          │
│  4. All logs aggregated in CloudWatch                                          │
│  5. Secrets managed via AWS Secrets Manager                                    │
│  6. Container images stored in ECR                                             │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SECURITY LAYERS                                   │
│                                                                                 │
│  • WAF - Web Application Firewall protection                                   │
│  • Security Groups - Network-level access control                              │
│  • NACLs - Subnet-level access control                                         │
│  • IAM Roles - Service-level permissions                                       │
│  • Encryption at rest - RDS, S3, EBS volumes                                   │
│  • Encryption in transit - TLS 1.3 everywhere                                  │
│  • VPC Flow Logs - Network traffic monitoring                                  │
│  • CloudTrail - API call auditing                                              │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                            HIGH AVAILABILITY                                   │
│                                                                                 │
│  • Multi-AZ deployment across 2 availability zones                             │
│  • Auto Scaling Groups for ECS services                                        │
│  • RDS Multi-AZ with automatic failover                                        │
│  • ElastiCache Redis cluster mode                                              │
│  • Application Load Balancer health checks                                     │
│  • CloudFront global edge locations                                            │
│  • Route53 health checks and failover routing                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Architecture Components

### **Frontend Tier**
- **CloudFront CDN** - Global content delivery
- **S3 Bucket** - Static website hosting
- **Route53** - DNS management

### **Application Tier**
- **Application Load Balancer** - Traffic distribution
- **ECS Fargate Cluster** - Containerized services
- **Auto Scaling Groups** - Dynamic scaling
- **ECR** - Container image registry

### **Data Tier**
- **RDS PostgreSQL** - Primary database (Multi-AZ)
- **ElastiCache Redis** - Caching layer
- **S3** - File storage and backups

### **Security & Monitoring**
- **WAF** - Web application firewall
- **Secrets Manager** - Credential management
- **CloudWatch** - Monitoring and logging
- **X-Ray** - Distributed tracing

### **Networking**
- **VPC** - Isolated network environment
- **Public Subnets** - Internet-facing resources
- **Private Subnets** - Backend services
- **NAT Gateway** - Outbound internet access

## Cost Optimization Features

- **Reserved Instances** for predictable workloads
- **Spot Instances** for development environments
- **Auto Scaling** to match demand
- **S3 Lifecycle Policies** for log archival
- **CloudWatch Log Retention** policies

## Estimated Monthly Costs (Production)

| Service | Cost Range |
|---------|------------|
| ECS Fargate | $150-300 |
| RDS PostgreSQL | $100-200 |
| ElastiCache Redis | $50-100 |
| Application Load Balancer | $25 |
| CloudFront | $10-50 |
| Route53 | $1 |
| **Total** | **$336-676/month** |