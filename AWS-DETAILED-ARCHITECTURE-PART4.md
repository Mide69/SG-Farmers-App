# AWS Detailed Architecture - Part 4: Security, Monitoring & External Services

## 7. Security & Identity Management Layer

### AWS Secrets Manager
```
┌─────────────────────────────────────┐
│         AWS Secrets Manager        │
├─────────────────────────────────────┤
│ • Database Credentials             │
│   - RDS master password            │
│   - Application DB users           │
│ • API Keys & Tokens                │
│   - OpenAI API key                 │
│   - JWT signing secrets            │
│ • Redis Authentication             │
│ • Automatic Rotation               │
│   - 30-day rotation policy         │
│   - Lambda-based rotation          │
└─────────────────────────────────────┘
```

### IAM Roles & Policies
```
ECS Task Execution Role
├── AmazonECSTaskExecutionRolePolicy
├── CloudWatchLogsFullAccess
└── SecretsManagerReadWrite

ECS Task Role (per service)
├── Registration API
│   ├── RDS Connect
│   ├── Redis Access
│   └── S3 Document Upload
├── Search API
│   ├── OpenSearch Access
│   ├── Redis Access
│   └── RDS Read-only
└── Chat API
    ├── OpenAI API Access
    ├── RDS Read/Write
    └── Redis Session Storage
```

### Security Groups
```
ALB Security Group (sg-alb)
├── Inbound: 443 (HTTPS) from 0.0.0.0/0
├── Inbound: 80 (HTTP) from 0.0.0.0/0
└── Outbound: 3000-3002 to ECS SG

ECS Security Group (sg-ecs)
├── Inbound: 3000-3002 from ALB SG
└── Outbound: 443 to 0.0.0.0/0

Database Security Group (sg-db)
├── Inbound: 5432 from ECS SG
├── Inbound: 6379 from ECS SG (Redis)
└── Inbound: 443 from ECS SG (OpenSearch)
```

## 8. Monitoring & Observability Layer

### CloudWatch Metrics & Alarms
```
┌─────────────────────────────────────┐
│           CloudWatch                │
├─────────────────────────────────────┤
│ Application Metrics                 │
│ ├── API Response Times             │
│ │   - P50, P95, P99 latency        │
│ │   - Error rate (4xx, 5xx)        │
│ ├── ECS Service Metrics            │
│ │   - CPU utilization              │
│ │   - Memory utilization           │
│ │   - Task count                   │
│ └── Custom Business Metrics        │
│     - Farmer registrations/hour    │
│     - Grant applications/day       │
│     - Chat interactions/minute     │
│                                     │
│ Infrastructure Metrics             │
│ ├── RDS Performance                │
│ │   - Connection count             │
│ │   - Query execution time         │
│ │   - Database CPU/Memory          │
│ ├── Redis Performance              │
│ │   - Cache hit ratio              │
│ │   - Memory usage                 │
│ │   - Connection count             │
│ └── ALB Metrics                    │
│     - Request count                │
│     - Target response time         │
│     - Healthy/Unhealthy targets    │
└─────────────────────────────────────┘
```

### CloudWatch Alarms
```
Critical Alarms (SNS → PagerDuty)
├── API Error Rate > 5%
├── Database CPU > 80%
├── ECS Service < 2 healthy tasks
└── ALB 5xx errors > 10/minute

Warning Alarms (SNS → Email)
├── API Response Time > 1000ms
├── Cache Hit Ratio < 80%
├── Database Connections > 80%
└── ECS CPU > 70%
```

### AWS X-Ray Distributed Tracing
```
Request Flow Tracing
┌─────────────────────────────────────┐
│ User Request → ALB → ECS Service    │
├─────────────────────────────────────┤
│ Trace Segments:                     │
│ ├── HTTP Request (ALB)              │
│ ├── Application Logic (ECS)         │
│ ├── Database Query (RDS)            │
│ ├── Cache Lookup (Redis)            │
│ └── External API Call (OpenAI)      │
│                                     │
│ Performance Insights:               │
│ ├── End-to-end latency breakdown    │
│ ├── Service dependency map          │
│ ├── Error root cause analysis       │
│ └── Performance bottleneck ID       │
└─────────────────────────────────────┘
```

### CloudWatch Logs
```
Log Groups Structure
├── /aws/ecs/sg-farmers-registration
│   ├── Application logs
│   ├── Error logs
│   └── Access logs
├── /aws/ecs/sg-farmers-search
├── /aws/ecs/sg-farmers-chat
├── /aws/rds/sg-farmers-db
│   ├── Error logs
│   ├── Slow query logs
│   └── General logs
└── /aws/elasticache/sg-farmers-redis
```

## 9. External Integrations Layer

### OpenAI Integration
```
┌─────────────────────────────────────┐
│            OpenAI API               │
├─────────────────────────────────────┤
│ Chat API Service Integration        │
│ ├── GPT-4 Model                     │
│ │   - Context: Singapore farming    │
│ │   - Max tokens: 4096              │
│ │   - Temperature: 0.7              │
│ ├── Rate Limiting                   │
│ │   - 3,500 requests/minute         │
│ │   - Token bucket algorithm        │
│ ├── Error Handling                  │
│ │   - Retry with exponential backoff│
│ │   - Fallback responses            │
│ └── Cost Optimization               │
│     - Request caching (Redis)       │
│     - Context compression           │
│     - Usage monitoring              │
└─────────────────────────────────────┘
```

### Third-Party Services
```
Email Service (SES)
├── Farmer registration confirmations
├── Grant application notifications
├── Password reset emails
└── System alerts

SMS Service (SNS)
├── OTP verification
├── Critical notifications
└── Application status updates

File Storage (S3)
├── Document uploads
├── Profile images
├── Grant application attachments
└── System backups
```

## 10. Backup & Disaster Recovery Layer

### RDS Automated Backups
```
┌─────────────────────────────────────┐
│         Backup Strategy             │
├─────────────────────────────────────┤
│ Automated Backups                   │
│ ├── Daily snapshots (7-day retention)│
│ ├── Point-in-time recovery (35 days) │
│ ├── Cross-region backup replication  │
│ └── Backup window: 03:00-04:00 UTC   │
│                                     │
│ Manual Snapshots                    │
│ ├── Pre-deployment snapshots        │
│ ├── Monthly archival snapshots      │
│ └── Long-term retention (1 year)    │
└─────────────────────────────────────┘
```

### Multi-AZ Deployment
```
Primary AZ (eu-west-2a)          Secondary AZ (eu-west-2b)
├── RDS Primary Instance         ├── RDS Standby Instance
├── ElastiCache Primary          ├── ElastiCache Replica
├── ECS Tasks (50%)              ├── ECS Tasks (50%)
└── NAT Gateway                  └── NAT Gateway

Failover Process:
├── Automatic RDS failover (60-120s)
├── ElastiCache automatic failover
├── ECS tasks redistribute
└── ALB health checks redirect traffic
```

## 11. Cost Optimization Layer

### Resource Optimization
```
┌─────────────────────────────────────┐
│        Cost Optimization            │
├─────────────────────────────────────┤
│ ECS Fargate                         │
│ ├── Right-sizing: 0.5 vCPU, 1GB RAM │
│ ├── Auto-scaling: 2-10 tasks        │
│ └── Spot capacity (dev environment) │
│                                     │
│ RDS Optimization                    │
│ ├── Reserved Instance (1-year)      │
│ ├── Storage optimization            │
│ └── Performance Insights            │
│                                     │
│ S3 Cost Management                  │
│ ├── Intelligent Tiering             │
│ ├── Lifecycle policies              │
│ └── CloudFront caching              │
└─────────────────────────────────────┘
```

### Estimated Monthly Costs
```
Production Environment:
├── ECS Fargate (6 tasks avg): $180
├── RDS Multi-AZ (db.t3.medium): $150
├── ElastiCache (cache.t3.micro): $45
├── OpenSearch (t3.small.search): $60
├── Application Load Balancer: $25
├── CloudFront: $15
├── Route53: $1
├── CloudWatch: $20
├── Secrets Manager: $5
└── Data Transfer: $30
    Total: ~$531/month

Development Environment:
├── ECS Fargate (2 tasks): $60
├── RDS Single-AZ (db.t3.micro): $25
├── ElastiCache (cache.t3.micro): $15
└── Other services: $20
    Total: ~$120/month
```

This completes the comprehensive left-to-right AWS architecture design for the SG Farmers App, covering all layers from user interaction to cost optimization.