# Lucid Chart Prompt: SG Farmers App High-Level System Design

## 📋 **Prompt for Lucid Chart Creation**

**Title**: "SG Farmers App - Production Infrastructure & System Architecture"

**Description**: Create a comprehensive high-level system design diagram for a Singapore government farmers' grant registration platform with AI chat support. The system must handle 10,000+ concurrent users with enterprise-grade security, performance, and scalability.

---

## 🎯 **System Requirements to Visualize**

### **Functional Components**
1. **User Registration System** - Multi-step farmer registration with document upload
2. **Grant Application Portal** - Digital grant submission and tracking workflow
3. **AI-Powered Chat Support** - Context-aware farming assistance using OpenAI GPT-4
4. **Advanced Search Engine** - Real-time autocomplete and filtering with Elasticsearch
5. **Document Management** - Secure file upload, storage, and retrieval
6. **Admin Dashboard** - Government officials' application review interface

### **User Types to Show**
- **Primary Users**: Singapore Farmers (10,000+ concurrent)
- **Secondary Users**: Government Officials (100+ concurrent)
- **System Administrators**: Platform operators (10+ concurrent)

---

## 🏗️ **Architecture Layers to Diagram**

### **Layer 1: Client Layer**
```
Components to Draw:
├── Web Browser (React SPA)
├── Mobile App (React Native)
├── Admin Panel (React Admin Dashboard)
└── API Testing Tools (Postman/Swagger)

Visual Elements:
- User icons with device representations
- Arrows showing HTTPS requests
- Labels for different user types
```

### **Layer 2: CDN & Edge Layer**
```
Components to Draw:
├── AWS CloudFront (Global CDN)
├── Edge Locations (200+ worldwide)
├── Static Asset Caching
└── DDoS Protection Shield

Visual Elements:
- Global map showing edge locations
- Cache symbols for static assets
- Security shield icons
```

### **Layer 3: Security & DNS Layer**
```
Components to Draw:
├── AWS Route53 (DNS Management)
├── AWS WAF (Web Application Firewall)
├── AWS Certificate Manager (SSL/TLS)
└── Security Groups & NACLs

Visual Elements:
- DNS resolution flow
- Firewall filtering symbols
- SSL certificate icons
- Security barrier representations
```

### **Layer 4: Load Balancing Layer**
```
Components to Draw:
├── Application Load Balancer (Multi-AZ)
├── Target Groups for each service
├── Health Check Endpoints
└── SSL Termination Point

Visual Elements:
- Load balancer distributing traffic
- Health check status indicators
- Multiple availability zones
```

### **Layer 5: Microservices Layer**
```
Components to Draw:
├── Registration Service (Port 3000)
│   ├── Farmer Registration API
│   ├── Grant Application API
│   ├── Document Upload Handler
│   └── JWT Authentication
├── Search Service (Port 3001)
│   ├── Elasticsearch Integration
│   ├── Autocomplete API
│   ├── Full-text Search
│   └── Redis Caching
├── Chat Service (Port 3002)
│   ├── OpenAI GPT-4 Integration
│   ├── WebSocket Support
│   ├── Context Management
│   └── Chat History Storage
└── Auth Service (Port 3004)
    ├── JWT Token Management
    ├── AWS Cognito Integration
    ├── Role-based Access Control
    └── Session Management

Visual Elements:
- Containerized services (Docker icons)
- API endpoint labels
- Service communication arrows
- Auto-scaling indicators
```

### **Layer 6: Container Orchestration**
```
Components to Draw:
├── AWS ECS Fargate Cluster
├── Auto Scaling Groups (2-20 instances per service)
├── Service Discovery
└── Container Health Monitoring

Visual Elements:
- ECS cluster representation
- Scaling arrows (up/down)
- Container orchestration symbols
```

### **Layer 7: Data Layer**
```
Components to Draw:
├── PostgreSQL RDS (Multi-AZ)
│   ├── Primary Database
│   ├── Read Replicas
│   ├── Automated Backups
│   └── Point-in-Time Recovery
├── Elasticsearch Cluster (3-node)
│   ├── Search Indexes
│   ├── Autocomplete Data
│   └── Analytics Storage
├── Redis ElastiCache (Cluster Mode)
│   ├── Session Storage
│   ├── API Response Cache
│   ├── Rate Limiting Data
│   └── Pub/Sub Messaging
└── AWS S3 Storage
    ├── Document Storage
    ├── Static Assets
    ├── Backup Archives
    └── Log Storage

Visual Elements:
- Database cylinder symbols
- Replication arrows
- Cache memory symbols
- Storage bucket icons
```

---

## 🔐 **Security Architecture to Visualize**

### **Security Layers**
```
Layer 1: Network Security
├── VPC with Public/Private Subnets
├── Internet Gateway & NAT Gateways
├── Security Groups (Stateful Firewall)
└── Network ACLs (Stateless Firewall)

Layer 2: Application Security
├── AWS WAF Rules (SQL Injection, XSS)
├── Rate Limiting (per IP/User)
├── Input Validation & Sanitization
└── CORS Configuration

Layer 3: Authentication & Authorization
├── AWS Cognito User Pools
├── JWT Token Validation
├── Multi-Factor Authentication
└── Role-Based Access Control

Layer 4: Data Security
├── Encryption at Rest (AES-256)
├── Encryption in Transit (TLS 1.3)
├── AWS Secrets Manager
└── Database Connection Encryption

Visual Elements:
- Security shield icons at each layer
- Encryption symbols (lock icons)
- Authentication flow arrows
- Access control matrices
```

---

## 📊 **Performance & Scalability Elements**

### **Performance Optimizations**
```
Components to Show:
├── Multi-Level Caching Strategy
│   ├── Browser Cache (Level 1)
│   ├── CloudFront CDN (Level 2)
│   ├── Redis Cache (Level 3)
│   ├── Elasticsearch Cache (Level 4)
│   └── Database Query Cache (Level 5)
├── Auto-Scaling Policies
│   ├── CPU-based Scaling (70% threshold)
│   ├── Memory-based Scaling (80% threshold)
│   └── Request-based Scaling (1000 RPS)
└── Load Distribution
    ├── Round-robin Algorithm
    ├── Health-based Routing
    └── Geographic Routing

Visual Elements:
- Cache layers with hit/miss ratios
- Scaling arrows with metrics
- Performance monitoring dashboards
```

### **Availability & Disaster Recovery**
```
Components to Show:
├── Multi-AZ Deployment
├── Cross-Region Backup
├── Automated Failover
├── Health Check Monitoring
└── Recovery Time Objectives (RTO < 15 min)

Visual Elements:
- Geographic regions on map
- Failover arrows
- Backup symbols
- Uptime indicators (99.9%)
```

---

## 💰 **Cost Optimization Visualization**

### **Cost Breakdown**
```
Monthly Cost Components:
├── ECS Fargate: $200-400 (Auto-scaling containers)
├── RDS PostgreSQL: $150-300 (Multi-AZ database)
├── ElastiCache Redis: $80-150 (Cluster mode)
├── Elasticsearch: $200-400 (3-node cluster)
├── S3 + CloudFront: $50-100 (Storage + CDN)
├── Load Balancer: $30-50 (ALB + health checks)
├── Cognito: $20-40 (User authentication)
├── OpenAI API: $100-200 (AI chat functionality)
└── Monitoring: $50-100 (CloudWatch + X-Ray)

Total: $880-1,740/month

Visual Elements:
- Cost pie chart
- Scaling cost projections
- Optimization opportunity callouts
```

---

## 🚀 **Deployment Pipeline Visualization**

### **CI/CD Flow**
```
Pipeline Stages:
├── Source Control (GitHub)
├── Build Stage (Docker Images)
├── Test Stage (Unit + Integration)
├── Security Scan (SAST/DAST)
├── Staging Deployment
├── End-to-End Testing
├── Production Deployment (Blue/Green)
└── Monitoring & Alerting

Visual Elements:
- Pipeline flow arrows
- Stage success/failure indicators
- Deployment strategy diagrams
- Rollback mechanisms
```

---

## 📈 **Monitoring & Observability Dashboard**

### **Key Metrics to Display**
```
Business Metrics:
├── User Registrations/day: 500+
├── Grant Applications/day: 200+
├── Chat Interactions/day: 1,000+
└── Search Queries/day: 5,000+

Technical Metrics:
├── API Response Time: <200ms (P95)
├── Error Rate: <0.1%
├── Database Connections: 80% utilization
├── Cache Hit Rate: >90%
└── Infrastructure Cost: $1,200/month

Security Metrics:
├── Failed Auth Attempts: <1%
├── WAF Blocked Requests: 500+/day
├── SSL Certificate Status: Valid
└── Vulnerability Scan: Clean

Visual Elements:
- Real-time metric dashboards
- Alert threshold indicators
- Trend graphs and charts
- Status light indicators (green/yellow/red)
```

---

## 🎨 **Visual Design Guidelines**

### **Color Coding**
- **Blue**: User-facing components
- **Green**: Secure/encrypted connections
- **Orange**: Processing/compute services
- **Purple**: Data storage components
- **Red**: Security/firewall elements
- **Gray**: Infrastructure/networking

### **Icon Standards**
- **Users**: Person icons with role labels
- **Services**: Rectangular containers with service names
- **Databases**: Cylinder shapes with data type labels
- **Security**: Shield icons with protection type
- **Networking**: Cloud shapes with connection lines
- **Monitoring**: Dashboard/chart icons

### **Flow Indicators**
- **Solid arrows**: Synchronous requests
- **Dashed arrows**: Asynchronous processes
- **Thick arrows**: High-volume data flow
- **Thin arrows**: Low-volume/control signals
- **Bidirectional arrows**: Two-way communication

---

## 📝 **Diagram Annotations**

### **Performance Annotations**
- Response time targets next to each service
- Throughput capacity labels on connections
- Scaling limits on auto-scaling groups
- Cache hit ratios on caching layers

### **Security Annotations**
- Encryption protocols on connections
- Authentication methods at entry points
- Access control policies on services
- Compliance standards met

### **Cost Annotations**
- Monthly cost estimates per component
- Scaling cost implications
- Optimization opportunities highlighted
- ROI metrics where applicable

---

## 🔧 **Technical Specifications for Lucid**

### **Diagram Dimensions**
- **Canvas Size**: A1 (594 × 841 mm) for detailed view
- **Layer Separation**: 50px vertical spacing between layers
- **Component Spacing**: 30px horizontal spacing
- **Font Size**: 12pt for labels, 10pt for annotations

### **Export Requirements**
- **Format**: PNG (high resolution) + PDF (vector)
- **Resolution**: 300 DPI for presentations
- **Background**: White with subtle grid
- **Legend**: Include color coding and icon meanings

This prompt will generate a comprehensive, professional system architecture diagram that clearly communicates the technical design, infrastructure choices, and operational considerations for the SG Farmers App.