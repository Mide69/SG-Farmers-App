 # SG Farmers App - High-Level System Design

## 🎯 **System Overview**

The SG Farmers App is a comprehensive digital platform for Singapore farmers to register for government grants, access AI-powered farming assistance, and search for agricultural resources. The system supports 10,000+ concurrent users with sub-200ms response times and 99.9% availability.

## 📋 **Functional Requirements**

### **Core Features**
- **Farmer Registration** - Multi-step registration with document upload
- **Grant Applications** - Digital grant submission and tracking
- **AI Chat Support** - Context-aware farming assistance
- **Advanced Search** - Real-time autocomplete and filtering
- **Document Management** - Secure file upload and storage
- **Admin Dashboard** - Application review and management

### **User Personas**
- **Farmers** - Primary users applying for grants and seeking advice
- **Government Officials** - Reviewing applications and managing programs
- **System Administrators** - Managing platform operations

## 🏗️ **Technology Stack & Justifications**

### **Frontend Layer**
```
Technology: React 18 + TypeScript + Material-UI
Justification:
✓ Component reusability and maintainability
✓ Strong TypeScript support for type safety
✓ Material-UI provides accessible components
✓ Large ecosystem and community support
✓ Excellent performance with React 18 features
```

### **API Gateway & Load Balancing**
```
Technology: AWS Application Load Balancer + AWS WAF
Justification:
✓ Native AWS integration with ECS
✓ SSL termination and certificate management
✓ Advanced routing and health checks
✓ Built-in DDoS protection via WAF
✓ Cost-effective compared to API Gateway for high traffic
```

### **Microservices Architecture**
```
Technology: Node.js + Express + TypeScript
Justification:
✓ JavaScript ecosystem consistency (frontend/backend)
✓ High performance for I/O intensive operations
✓ Rich package ecosystem (npm)
✓ Excellent async/await support
✓ Fast development cycles
✓ Strong community and enterprise adoption
```

### **Container Orchestration**
```
Technology: AWS ECS Fargate
Justification:
✓ Serverless containers - no infrastructure management
✓ Auto-scaling based on demand
✓ Pay-per-use pricing model
✓ Integrated with AWS ecosystem
✓ Better cost efficiency than EKS for this scale
✓ Simplified operations compared to EC2
```

### **Database Layer**
```
Primary: PostgreSQL 15 (AWS RDS Multi-AZ)
Justification:
✓ ACID compliance for financial/grant data
✓ Rich data types (JSON, arrays, full-text search)
✓ Excellent performance for complex queries
✓ Strong consistency guarantees
✓ Mature ecosystem and tooling
✓ Multi-AZ for high availability

Search: Elasticsearch 8.11
Justification:
✓ Sub-100ms search response times
✓ Advanced autocomplete capabilities
✓ Fuzzy matching and typo tolerance
✓ Horizontal scaling capabilities
✓ Rich query DSL for complex searches
```

### **Caching Layer**
```
Technology: Redis 7 (AWS ElastiCache)
Justification:
✓ In-memory performance (sub-1ms latency)
✓ Support for complex data structures
✓ Session storage capabilities
✓ Pub/Sub for real-time features
✓ Cluster mode for high availability
✓ Automatic failover and backup
```

### **Authentication & Authorization**
```
Technology: AWS Cognito + JWT
Justification:
✓ Managed service - reduces operational overhead
✓ Built-in security features (MFA, password policies)
✓ GDPR compliance capabilities
✓ Social login integration
✓ Scalable to millions of users
✓ Cost-effective pricing model
```

### **File Storage**
```
Technology: AWS S3 + CloudFront CDN
Justification:
✓ 99.999999999% durability guarantee
✓ Global CDN for fast content delivery
✓ Lifecycle policies for cost optimization
✓ Versioning and encryption at rest
✓ Integration with other AWS services
✓ Pay-per-use pricing
```

### **AI/ML Services**
```
Technology: OpenAI GPT-4 API
Justification:
✓ State-of-the-art language understanding
✓ Context-aware responses
✓ Multilingual support (English/Chinese/Malay)
✓ Rapid deployment without ML infrastructure
✓ Continuous model improvements
✓ Cost-effective for moderate usage
```

## 🏛️ **System Architecture**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                 CLIENT LAYER                                   │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │   Web Browser   │  │   Mobile App    │  │   Admin Panel   │                │
│  │   React SPA     │  │   React Native  │  │   React Admin   │                │
│  │                 │  │                 │  │                 │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                 CDN LAYER                                      │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        AWS CLOUDFRONT                                  │   │
│  │                                                                         │   │
│  │  • Global Edge Locations (200+ worldwide)                              │   │
│  │  • Static Asset Caching (CSS, JS, Images)                              │   │
│  │  • Gzip Compression                                                     │   │
│  │  • SSL/TLS Termination                                                  │   │
│  │  • DDoS Protection                                                      │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SECURITY LAYER                                    │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │   AWS WAF       │  │   Route53       │  │   ACM           │                │
│  │   • SQL Inject  │  │   • DNS         │  │   • SSL Certs   │                │
│  │   • XSS Filter  │  │   • Health      │  │   • Auto Renew  │                │
│  │   • Rate Limit  │  │   • Failover    │  │   • Wildcard    │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            LOAD BALANCER LAYER                                 │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                   APPLICATION LOAD BALANCER                            │   │
│  │                                                                         │   │
│  │  • Multi-AZ Deployment                                                  │   │
│  │  • Health Check Endpoints                                               │   │
│  │  • SSL Termination                                                      │   │
│  │  • Path-based Routing                                                   │   │
│  │  • Sticky Sessions Support                                              │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
        ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
        │  REGISTRATION   │  │     SEARCH      │  │      CHAT       │
        │     SERVICE     │  │    SERVICE      │  │    SERVICE      │
        │   Port 3000     │  │   Port 3001     │  │   Port 3002     │
        └─────────────────┘  └─────────────────┘  └─────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                            MICROSERVICES LAYER                                 │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        ECS FARGATE CLUSTER                             │   │
│  │                                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │Registration │ │   Search    │ │    Chat     │ │    Auth     │      │   │
│  │  │   Service   │ │   Service   │ │   Service   │ │   Service   │      │   │
│  │  │             │ │             │ │             │ │             │      │   │
│  │  │• Farmer Reg │ │• Elasticsearch│ │• OpenAI    │ │• JWT Issue │      │   │
│  │  │• Grant Apps │ │• Autocomplete│ │• WebSocket │ │• Token Val │      │   │
│  │  │• Document   │ │• Full-text  │ │• Context   │ │• Refresh   │      │   │
│  │  │  Upload     │ │  Search     │ │  Aware     │ │  Tokens    │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  │                                                                         │   │
│  │  Auto Scaling: 2-20 instances per service based on CPU/Memory          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                        │
│                                                                                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   PostgreSQL    │ │   Elasticsearch │ │     Redis       │ │      S3         ││
│  │   RDS Multi-AZ  │ │   OpenSearch    │ │  ElastiCache    │ │   File Store    ││
│  │                 │ │                 │ │                 │ │                 ││
│  │• Primary DB     │ │• Search Index   │ │• Session Store  │ │• Documents      ││
│  │• ACID Compliant │ │• Autocomplete   │ │• API Cache      │ │• Images         ││
│  │• Backup/Restore │ │• Analytics      │ │• Rate Limiting  │ │• Static Assets  ││
│  │• Read Replicas  │ │• 3-Node Cluster │ │• Pub/Sub        │ │• CDN Origin     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔐 **Security Architecture**

### **Multi-Layer Security Model**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SECURITY LAYERS                                   │
│                                                                                 │
│  Layer 1: Network Security                                                     │
│  ├── VPC with Private/Public Subnets                                           │
│  ├── Security Groups (Stateful Firewall)                                       │
│  ├── NACLs (Network Access Control Lists)                                      │
│  └── VPC Flow Logs for Monitoring                                              │
│                                                                                 │
│  Layer 2: Application Security                                                 │
│  ├── WAF (Web Application Firewall)                                            │
│  ├── DDoS Protection via CloudFront                                            │
│  ├── Rate Limiting per IP/User                                                 │
│  └── Input Validation & Sanitization                                           │
│                                                                                 │
│  Layer 3: Authentication & Authorization                                       │
│  ├── AWS Cognito User Pools                                                    │
│  ├── JWT Token-based Authentication                                            │
│  ├── Role-based Access Control (RBAC)                                          │
│  └── Multi-Factor Authentication (MFA)                                         │
│                                                                                 │
│  Layer 4: Data Security                                                        │
│  ├── Encryption at Rest (AES-256)                                              │
│  ├── Encryption in Transit (TLS 1.3)                                           │
│  ├── Database Connection Encryption                                            │
│  └── Secrets Manager for Credentials                                           │
│                                                                                 │
│  Layer 5: Compliance & Monitoring                                              │
│  ├── GDPR Compliance (Data Protection)                                         │
│  ├── Audit Logging (CloudTrail)                                                │
│  ├── Security Monitoring (GuardDuty)                                           │
│  └── Vulnerability Scanning (Inspector)                                        │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 📊 **Non-Functional Requirements**

### **Performance Requirements**
```
Metric                    Target          Justification
─────────────────────────────────────────────────────────────
API Response Time         < 200ms         User experience expectation
Search Autocomplete       < 100ms         Real-time user interaction
Page Load Time           < 2 seconds      Web performance standards
Database Query Time       < 50ms          Efficient data retrieval
File Upload Speed        10MB/min         Document processing needs
Concurrent Users         10,000+          Peak usage estimation
```

### **Availability Requirements**
```
Component                 SLA             Implementation
─────────────────────────────────────────────────────────────
Overall System           99.9%           Multi-AZ deployment
Database                 99.95%          RDS Multi-AZ with failover
Search Service           99.9%           Elasticsearch cluster
Cache Layer              99.9%           Redis cluster mode
CDN                      99.99%          CloudFront global network
```

### **Scalability Requirements**
```
Dimension                Current         Target (2 years)
─────────────────────────────────────────────────────────────
Registered Users         10,000          100,000
Daily Active Users       2,000           20,000
API Requests/day         1M              10M
Data Storage             100GB           1TB
Search Queries/day       100K            1M
```

### **Security Requirements**
```
Requirement              Implementation
─────────────────────────────────────────────────────────────
Data Encryption          AES-256 at rest, TLS 1.3 in transit
Authentication           Multi-factor authentication
Authorization            Role-based access control
Audit Logging            All actions logged to CloudWatch
Compliance               GDPR, SOC 2 Type II
Vulnerability Mgmt       Regular security scans
```

### **Accessibility Requirements**
```
Standard                 Implementation
─────────────────────────────────────────────────────────────
WCAG 2.1 AA             Material-UI accessible components
Screen Reader           ARIA labels and semantic HTML
Keyboard Navigation     Full keyboard accessibility
Color Contrast          4.5:1 minimum ratio
Multi-language          English, Chinese, Malay support
Mobile Responsive       Progressive Web App (PWA)
```

## 💰 **Cost Analysis**

### **Monthly Cost Breakdown (Production)**
```
Service                  Cost Range      Justification
─────────────────────────────────────────────────────────────
ECS Fargate             $200-400        Auto-scaling containers
RDS PostgreSQL          $150-300        Multi-AZ, backup included
ElastiCache Redis       $80-150         Cluster mode for HA
Elasticsearch           $200-400        3-node cluster
S3 + CloudFront         $50-100         Storage + CDN
ALB + WAF               $30-50          Load balancing + security
Cognito                 $20-40          User authentication
OpenAI API              $100-200        AI chat functionality
Monitoring              $50-100         CloudWatch + X-Ray
─────────────────────────────────────────────────────────────
Total Monthly           $880-1,740      Scales with usage
```

### **Cost Optimization Strategies**
- **Reserved Instances** for predictable workloads (30% savings)
- **Spot Instances** for development environments (70% savings)
- **S3 Lifecycle Policies** for log archival (50% storage savings)
- **Auto-scaling** to match demand (20-40% compute savings)
- **CloudWatch Log Retention** policies (30% logging savings)

## 🚀 **Deployment Strategy**

### **Environment Pipeline**
```
Development → Staging → Production
     ↓           ↓          ↓
   Local      Pre-prod   Live
   Docker     AWS ECS    AWS ECS
   Testing    E2E Tests  Monitoring
```

### **Deployment Process**
1. **Code Commit** → GitHub repository
2. **CI Pipeline** → GitHub Actions triggered
3. **Build & Test** → Docker images created
4. **Security Scan** → Vulnerability assessment
5. **Deploy Staging** → Automated deployment
6. **Integration Tests** → End-to-end validation
7. **Deploy Production** → Blue/Green deployment
8. **Health Checks** → Service validation
9. **Monitoring** → Performance tracking

### **Rollback Strategy**
- **Blue/Green Deployment** for zero-downtime rollbacks
- **Database Migrations** with rollback scripts
- **Feature Flags** for gradual feature rollout
- **Automated Health Checks** trigger rollbacks
- **Point-in-Time Recovery** for data restoration

## 📈 **Monitoring & Observability**

### **Key Metrics Dashboard**
```
Business Metrics:
├── User Registrations/day
├── Grant Applications/day
├── Chat Interactions/day
├── Search Queries/day
└── Document Uploads/day

Technical Metrics:
├── API Response Times (P50, P95, P99)
├── Error Rates by Service
├── Database Connection Pool Usage
├── Cache Hit Rates
└── Infrastructure Costs

Security Metrics:
├── Failed Authentication Attempts
├── WAF Blocked Requests
├── Suspicious Activity Alerts
├── SSL Certificate Expiry
└── Vulnerability Scan Results
```

### **Alerting Strategy**
- **Critical Alerts** → PagerDuty (immediate response)
- **Warning Alerts** → Slack (within 15 minutes)
- **Info Alerts** → Email (daily digest)
- **Business Metrics** → Weekly reports

This high-level design ensures a robust, scalable, and secure platform that meets all functional and non-functional requirements while maintaining cost efficiency and operational excellence.