# SG Farmers App - Complete Request Flow Architecture

## 🔄 **End-to-End Request Flow: From Frontend to Database**

### **1. User Authentication Flow**

```
[Frontend] → [Cognito] → [Auth Service] → [JWT Token] → [Client Storage]

1. User enters credentials in React frontend
2. Frontend sends login request to AWS Cognito User Pool
3. Cognito validates credentials and returns JWT tokens
4. Auth Service (Port 3004) validates and refreshes tokens
5. JWT stored in browser localStorage/sessionStorage
6. All subsequent requests include JWT in Authorization header
```

### **2. Farmer Registration Flow**

```
[Frontend] → [ALB] → [Registration API] → [PostgreSQL] → [Elasticsearch Sync]

1. User fills registration form in React frontend
2. Frontend sends POST /api/farmers/register with JWT token
3. ALB validates SSL and routes to Registration API (Port 3000)
4. Registration API validates JWT token with Auth Service
5. API validates input data and checks business rules
6. Data saved to PostgreSQL farmers table
7. Background sync updates Elasticsearch index for search
8. Success response returned to frontend
```

### **3. Search & Autocomplete Flow**

```
[Frontend] → [ALB] → [Search API] → [Redis Cache] → [Elasticsearch] → [PostgreSQL]

1. User types in search box (autocomplete after 2+ characters)
2. Frontend sends GET /api/search/autocomplete?q=john
3. ALB routes to Search API (Port 3001)
4. Search API checks Redis cache for cached results
5. If cache miss, queries Elasticsearch for suggestions
6. Elasticsearch returns fuzzy-matched suggestions
7. Results cached in Redis for 5 minutes
8. Formatted suggestions returned to frontend
9. Frontend displays dropdown with suggestions
```

### **4. Grant Application Flow**

```
[Frontend] → [ALB] → [Registration API] → [PostgreSQL] → [Notification Service]

1. Authenticated user submits grant application form
2. Frontend sends POST /api/grants/apply with JWT + form data
3. ALB routes to Registration API with JWT validation
4. API validates user permissions and application data
5. Application saved to grant_applications table
6. Document uploads stored in S3 (if any)
7. Notification sent to admin users via SNS
8. Application status returned to user
```

### **5. AI Chat Flow**

```
[Frontend] → [ALB] → [Chat API] → [OpenAI] → [PostgreSQL] → [WebSocket Response]

1. User types message in chat interface
2. Frontend sends message via WebSocket or HTTP POST
3. ALB routes to Chat API (Port 3002) with JWT validation
4. Chat API retrieves user context from PostgreSQL
5. Message + context sent to OpenAI GPT API
6. OpenAI returns AI-generated farming advice
7. Conversation saved to chat_history table
8. Response sent back to frontend via WebSocket/HTTP
9. Frontend displays AI response in chat interface
```

## 🔐 **Authentication & Authorization Flow**

### **JWT Token Validation Process**

```
[API Request] → [ALB] → [Service] → [Auth Middleware] → [JWT Validation] → [Business Logic]

1. Client includes JWT in Authorization: Bearer <token>
2. ALB forwards request to appropriate service
3. Service middleware extracts JWT from header
4. JWT signature validated using shared secret/public key
5. Token expiry and claims checked
6. User permissions validated for requested resource
7. If valid, request proceeds to business logic
8. If invalid, 401/403 error returned
```

### **Token Refresh Flow**

```
[Frontend] → [Auth Service] → [Cognito] → [New JWT] → [Frontend Update]

1. Frontend detects token expiry (before API call fails)
2. Refresh token sent to Auth Service
3. Auth Service validates refresh token with Cognito
4. New access token generated and returned
5. Frontend updates stored token
6. Original API request retried with new token
```

## 📊 **Data Flow Architecture**

### **Write Operations (Create/Update)**

```
[Frontend] → [ALB] → [API Service] → [PostgreSQL] → [Elasticsearch Sync] → [Cache Invalidation]

1. User submits form data
2. API validates and processes data
3. Data written to PostgreSQL (source of truth)
4. Background job syncs data to Elasticsearch
5. Related cache entries invalidated in Redis
6. Success response returned to frontend
```

### **Read Operations (Search/Retrieve)**

```
[Frontend] → [ALB] → [API Service] → [Redis Cache] → [Elasticsearch/PostgreSQL] → [Response]

1. User requests data (search, profile, etc.)
2. API checks Redis cache first
3. If cache hit, return cached data
4. If cache miss, query appropriate data store:
   - Elasticsearch for search/autocomplete
   - PostgreSQL for structured data
5. Results cached in Redis with TTL
6. Data returned to frontend
```

## 🚀 **Performance Optimization Flow**

### **Caching Strategy**

```
Level 1: Browser Cache (Static assets, API responses)
Level 2: CloudFront CDN (Global edge caching)
Level 3: Redis Cache (API responses, session data)
Level 4: Elasticsearch (Search index cache)
Level 5: PostgreSQL (Database query cache)
```

### **Auto-Scaling Flow**

```
[CloudWatch Metrics] → [Auto Scaling Trigger] → [ECS Service Scaling] → [Load Distribution]

1. CloudWatch monitors CPU/Memory/Request metrics
2. Scaling policies trigger when thresholds exceeded
3. ECS automatically launches new Fargate tasks
4. ALB distributes traffic across healthy instances
5. Scale-down occurs when metrics return to normal
```

## 🔍 **Search Architecture Deep Dive**

### **Elasticsearch Index Structure**

```json
{
  "farmers": {
    "mappings": {
      "properties": {
        "name": { "type": "text", "analyzer": "standard" },
        "farm_location": { "type": "text", "analyzer": "standard" },
        "crop_types": { "type": "text", "analyzer": "standard" },
        "suggest": {
          "type": "completion",
          "analyzer": "simple",
          "preserve_separators": true,
          "max_input_length": 50
        }
      }
    }
  }
}
```

### **Search Query Flow**

```
[User Input] → [Frontend Debounce] → [API Request] → [Cache Check] → [Elasticsearch Query] → [Results Processing]

1. User types in search field
2. Frontend debounces input (300ms delay)
3. API request sent with search parameters
4. Redis cache checked for existing results
5. If cache miss, Elasticsearch queried with:
   - Fuzzy matching for typos
   - Completion suggester for autocomplete
   - Multi-field search across name, location, crops
6. Results scored and ranked by relevance
7. Top 10 results returned and cached
8. Frontend displays formatted results
```

## 🛡️ **Security Flow**

### **Request Security Pipeline**

```
[Client] → [CloudFront] → [WAF] → [ALB] → [Security Groups] → [Service] → [JWT Validation] → [Authorization]

1. HTTPS enforced at CloudFront level
2. WAF filters malicious requests (SQL injection, XSS)
3. ALB terminates SSL and validates certificates
4. Security Groups allow only necessary ports/protocols
5. Service-level JWT token validation
6. Role-based authorization for resource access
7. Input validation and sanitization
8. Audit logging to CloudWatch
```

## 📈 **Monitoring & Observability Flow**

### **Metrics Collection**

```
[Application] → [CloudWatch Agent] → [CloudWatch Metrics] → [Dashboards/Alarms]

1. Applications emit custom metrics
2. CloudWatch Agent collects system metrics
3. Metrics aggregated in CloudWatch
4. Dashboards visualize key performance indicators
5. Alarms trigger on threshold breaches
6. SNS notifications sent to operations team
```

### **Distributed Tracing**

```
[Frontend Request] → [X-Ray Trace] → [Service Calls] → [Database Queries] → [End-to-End Visibility]

1. Each request assigned unique trace ID
2. X-Ray SDK instruments service calls
3. Database queries and external API calls traced
4. Performance bottlenecks identified
5. Error root cause analysis enabled
```

## 🔄 **Disaster Recovery Flow**

### **Backup Strategy**

```
[PostgreSQL] → [Automated Snapshots] → [Cross-Region Replication] → [Point-in-Time Recovery]
[Elasticsearch] → [Index Snapshots] → [S3 Storage] → [Cluster Restoration]
[Application State] → [Redis Persistence] → [AOF/RDB Files] → [Recovery]
```

### **Failover Process**

```
[Primary Region Failure] → [Route53 Health Check] → [DNS Failover] → [Secondary Region Activation]

1. Route53 monitors primary region health
2. Failure detected via health check endpoints
3. DNS automatically routes to secondary region
4. Standby resources activated in secondary region
5. Data synchronized from backups
6. Service restored with minimal downtime
```

This architecture ensures high availability, security, performance, and scalability for the SG Farmers App across all user interactions and system processes.