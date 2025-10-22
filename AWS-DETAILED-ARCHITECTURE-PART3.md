## 🐳 **Layer 6: Container Orchestration (ECS Fargate)**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           ECS FARGATE CLUSTER                                  │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        CLUSTER OVERVIEW                                │   │
│  │                                                                         │   │
│  │  Name: sg-farmers-app-cluster                                           │   │
│  │  Capacity Providers: FARGATE, FARGATE_SPOT                             │   │
│  │  Container Insights: ENABLED                                            │   │
│  │  Execute Command: ENABLED                                               │   │
│  │  Configuration: Service Connect ENABLED                                 │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         SERVICES LAYER                                 │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                   REGISTRATION SERVICE                         │   │   │
│  │  │                                                                 │   │   │
│  │  │  Task Definition: sg-farmers-app-registration-api              │   │   │
│  │  │  ├── CPU: 512 (0.5 vCPU)                                       │   │   │
│  │  │  ├── Memory: 1024 MB                                            │   │   │
│  │  │  ├── Network Mode: awsvpc                                       │   │   │
│  │  │  └── Platform: Linux/x86_64                                     │   │   │
│  │  │                                                                 │   │   │
│  │  │  Container Configuration:                                       │   │   │
│  │  │  ├── Image: ECR/sg-farmers-app-registration-api:latest         │   │   │
│  │  │  ├── Port: 3000                                                 │   │   │
│  │  │  ├── Health Check: /health endpoint                             │   │   │
│  │  │  ├── Logging: CloudWatch Logs                                   │   │   │
│  │  │  └── Secrets: DB credentials, JWT secret                        │   │   │
│  │  │                                                                 │   │   │
│  │  │  Service Configuration:                                         │   │   │
│  │  │  ├── Desired Count: 2 (Min: 2, Max: 10)                        │   │   │
│  │  │  ├── Deployment: Rolling update                                 │   │   │
│  │  │  ├── Auto Scaling: CPU > 70%                                    │   │   │
│  │  │  └── Load Balancer: Registration TG                             │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                     SEARCH SERVICE                             │   │   │
│  │  │                                                                 │   │   │
│  │  │  Task Definition: sg-farmers-app-search-api                    │   │   │
│  │  │  ├── CPU: 512 (0.5 vCPU)                                       │   │   │
│  │  │  ├── Memory: 1024 MB                                            │   │   │
│  │  │  ├── Network Mode: awsvpc                                       │   │   │
│  │  │  └── Platform: Linux/x86_64                                     │   │   │
│  │  │                                                                 │   │   │
│  │  │  Container Configuration:                                       │   │   │
│  │  │  ├── Image: ECR/sg-farmers-app-search-api:latest               │   │   │
│  │  │  ├── Port: 3001                                                 │   │   │
│  │  │  ├── Health Check: /health endpoint                             │   │   │
│  │  │  ├── Logging: CloudWatch Logs                                   │   │   │
│  │  │  └── Environment: OpenSearch URL, Redis URL                     │   │   │
│  │  │                                                                 │   │   │
│  │  │  Service Configuration:                                         │   │   │
│  │  │  ├── Desired Count: 2 (Min: 2, Max: 10)                        │   │   │
│  │  │  ├── Deployment: Rolling update                                 │   │   │
│  │  │  ├── Auto Scaling: CPU > 70%                                    │   │   │
│  │  │  └── Load Balancer: Search TG                                   │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                      CHAT SERVICE                              │   │   │
│  │  │                                                                 │   │   │
│  │  │  Task Definition: sg-farmers-app-chat-api                      │   │   │
│  │  │  ├── CPU: 512 (0.5 vCPU)                                       │   │   │
│  │  │  ├── Memory: 1024 MB                                            │   │   │
│  │  │  ├── Network Mode: awsvpc                                       │   │   │
│  │  │  └── Platform: Linux/x86_64                                     │   │   │
│  │  │                                                                 │   │   │
│  │  │  Container Configuration:                                       │   │   │
│  │  │  ├── Image: ECR/sg-farmers-app-chat-api:latest                 │   │   │
│  │  │  ├── Port: 3002                                                 │   │   │
│  │  │  ├── Health Check: /health endpoint                             │   │   │
│  │  │  ├── Logging: CloudWatch Logs                                   │   │   │
│  │  │  └── Secrets: OpenAI API key, DB credentials                    │   │   │
│  │  │                                                                 │   │   │
│  │  │  Service Configuration:                                         │   │   │
│  │  │  ├── Desired Count: 2 (Min: 2, Max: 10)                        │   │   │
│  │  │  ├── Deployment: Rolling update                                 │   │   │
│  │  │  ├── Auto Scaling: CPU > 70%                                    │   │   │
│  │  │  └── Load Balancer: Chat TG                                     │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
```

## 🗄️ **Layer 7: Data Storage & Management**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                        │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      PRIMARY DATABASE                                  │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    RDS POSTGRESQL                               │   │   │
│  │  │                                                                 │   │   │
│  │  │  Configuration:                                                 │   │   │
│  │  │  ├── Engine: PostgreSQL 15.4                                   │   │   │
│  │  │  ├── Instance: db.t3.medium (2 vCPU, 4 GB RAM)                │   │   │
│  │  │  ├── Storage: 100 GB GP3 (Auto-scaling to 1 TB)               │   │   │
│  │  │  ├── Multi-AZ: ENABLED (Primary + Standby)                     │   │   │
│  │  │  └── Encryption: AES-256 at rest                               │   │   │
│  │  │                                                                 │   │   │
│  │  │  Database Schema:                                               │   │   │
│  │  │  ├── farmers (UUID, name, email, location, crops)              │   │   │
│  │  │  ├── grant_applications (UUID, farmer_id, type, status)        │   │   │
│  │  │  ├── chat_history (UUID, farmer_id, messages, timestamp)       │   │   │
│  │  │  ├── documents (UUID, farmer_id, file_path, metadata)          │   │   │
│  │  │  └── admin_users (UUID, username, role, permissions)           │   │   │
│  │  │                                                                 │   │   │
│  │  │  Backup & Recovery:                                             │   │   │
│  │  │  ├── Automated Backups: 7 days retention                       │   │   │
│  │  │  ├── Backup Window: 03:00-04:00 SGT                            │   │   │
│  │  │  ├── Maintenance Window: Sunday 04:00-05:00 SGT                │   │   │
│  │  │  └── Point-in-Time Recovery: Up to 7 days                      │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                       CACHING LAYER                                    │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                   ELASTICACHE REDIS                            │   │   │
│  │  │                                                                 │   │   │
│  │  │  Configuration:                                                 │   │   │
│  │  │  ├── Engine: Redis 7.0                                          │   │   │
│  │  │  ├── Node Type: cache.t3.micro                                  │   │   │
│  │  │  ├── Replication: 1 Primary + 1 Replica                        │   │   │
│  │  │  ├── Multi-AZ: ENABLED                                          │   │   │
│  │  │  └── Encryption: In-transit + At-rest                           │   │   │
│  │  │                                                                 │   │   │
│  │  │  Use Cases:                                                     │   │   │
│  │  │  ├── Session Storage (JWT tokens, user sessions)               │   │   │
│  │  │  ├── API Response Caching (5-minute TTL)                       │   │   │
│  │  │  ├── Search Results Caching (10-minute TTL)                    │   │   │
│  │  │  ├── Rate Limiting Counters                                     │   │   │
│  │  │  └── Real-time Chat Message Queue                               │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                       SEARCH ENGINE                                    │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    OPENSEARCH                                   │   │   │
│  │  │                                                                 │   │   │
│  │  │  Configuration:                                                 │   │   │
│  │  │  ├── Version: OpenSearch 2.3                                    │   │   │
│  │  │  ├── Instance: t3.small.search (3 nodes)                       │   │   │
│  │  │  ├── Storage: 20 GB EBS per node                                │   │   │
│  │  │  ├── Multi-AZ: 3 AZ deployment                                  │   │   │
│  │  │  └── Encryption: At-rest + In-transit                           │   │   │
│  │  │                                                                 │   │   │
│  │  │  Indexes:                                                       │   │   │
│  │  │  ├── farmers_index (Name, location, crops autocomplete)        │   │   │
│  │  │  ├── grants_index (Grant types, status, full-text search)      │   │   │
│  │  │  └── documents_index (File content, metadata search)           │   │   │
│  │  │                                                                 │   │   │
│  │  │  Features:                                                      │   │   │
│  │  │  ├── Autocomplete: <100ms response time                        │   │   │
│  │  │  ├── Fuzzy Search: Typo tolerance                              │   │   │
│  │  │  ├── Faceted Search: Multi-criteria filtering                  │   │   │
│  │  │  └── Analytics: Search patterns and trends                     │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```