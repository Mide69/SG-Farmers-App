# SG Farmers App - Complete Production Deployment

A comprehensive Singapore farmers grant registration and support system with AI-powered chat assistance, built for production deployment on AWS.

## 🏗️ Architecture Overview

### Services
- **Registration API** (Port 3000) - Farmer registration and grant applications
- **Search API** (Port 3001) - Advanced search and filtering capabilities
- **Chat API** (Port 3002) - AI-powered farming assistance with OpenAI integration
- **Frontend** (Port 3003) - React-based user interface
- **Database** - PostgreSQL with comprehensive schema
- **Cache** - Redis for performance optimization
- **Reverse Proxy** - Nginx for load balancing and SSL termination

### AWS Infrastructure
- **ECS Fargate** - Containerized microservices
- **RDS PostgreSQL** - Multi-AZ database with automated backups
- **ElastiCache Redis** - In-memory caching
- **Application Load Balancer** - High availability and SSL termination
- **CloudFront + S3** - Frontend hosting and CDN
- **Route53** - DNS management
- **ACM** - SSL certificate management
- **CloudWatch** - Monitoring and logging
- **Secrets Manager** - Secure credential storage

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+
- AWS CLI configured
- Terraform 1.0+

### Local Development

```bash
# Clone and navigate to project
cd SG-Farmers-App

# Start all services locally
chmod +x scripts/local-dev.sh
./scripts/local-dev.sh start

# Access the application
# Frontend: http://localhost
# APIs: http://localhost/api/*
```

### Production Deployment

```bash
# Deploy to AWS
chmod +x scripts/deploy.sh
export DOMAIN_NAME="your-domain.com"
./scripts/deploy.sh all
```

## 📁 Project Structure

```
SG-Farmers-App/
├── services/
│   ├── registration-api/     # Farmer registration & grants
│   ├── search-api/          # Search & filtering
│   ├── chat-api/            # AI chat assistance
│   └── frontend/            # React application
├── terraform/               # AWS infrastructure
├── database/               # Database schema & migrations
├── nginx/                  # Reverse proxy configuration
├── scripts/                # Deployment & utility scripts
├── docker-compose.yml      # Local development
└── README.md
```

## 🔧 Configuration

### Environment Variables

#### Registration API
```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://host:6379
JWT_SECRET=your-jwt-secret
```

#### Search API
```bash
NODE_ENV=production
PORT=3001
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://host:6379
```

#### Chat API
```bash
NODE_ENV=production
PORT=3002
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://host:6379
OPENAI_API_KEY=your-openai-key
```

#### Frontend
```bash
REACT_APP_API_URL=https://api.your-domain.com
REACT_APP_SEARCH_API_URL=https://api.your-domain.com/search
REACT_APP_CHAT_API_URL=https://api.your-domain.com/chat
```

### Terraform Variables

```hcl
aws_region   = "eu-west-2"
environment  = "production"
project_name = "sg-farmers-app"
domain_name  = "your-domain.com"
```

## 🗄️ Database Schema

### Core Tables
- **farmers** - Farmer profiles and registration data
- **grant_applications** - Grant application submissions
- **chat_history** - AI chat conversation logs
- **documents** - File uploads and attachments
- **notifications** - System notifications
- **admin_users** - Administrative access

### Key Features
- UUID primary keys for security
- Full-text search indexes
- Automatic timestamps
- Data validation constraints
- Performance optimized indexes

## 🔐 Security Features

- **TLS 1.3** encryption for all traffic
- **WAF protection** against common attacks
- **Rate limiting** on all API endpoints
- **JWT authentication** for secure sessions
- **Input validation** and sanitization
- **SQL injection** prevention
- **XSS protection** headers
- **CORS** properly configured
- **Secrets management** via AWS Secrets Manager

## 📊 Monitoring & Observability

### CloudWatch Integration
- **Application metrics** - Response times, error rates
- **Infrastructure metrics** - CPU, memory, network
- **Custom dashboards** - Business KPIs
- **Automated alerts** - Threshold-based notifications
- **Log aggregation** - Centralized logging

### Health Checks
- **Application health** endpoints on all services
- **Database connectivity** monitoring
- **Cache availability** checks
- **Load balancer** health targets

## 🚀 Deployment Options

### 1. Full Deployment
```bash
./scripts/deploy.sh all
```

### 2. Infrastructure Only
```bash
./scripts/deploy.sh infrastructure
```

### 3. Application Updates
```bash
./scripts/deploy.sh images
./scripts/deploy.sh services
```

### 4. Frontend Only
```bash
./scripts/deploy.sh frontend
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy SG Farmers App
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to AWS
        run: ./scripts/deploy.sh all
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          DOMAIN_NAME: ${{ secrets.DOMAIN_NAME }}
```

## 📈 Scaling & Performance

### Auto Scaling
- **ECS Service** auto-scaling based on CPU/memory
- **Application Load Balancer** distributes traffic
- **Multi-AZ deployment** for high availability
- **CloudFront CDN** for global content delivery

### Performance Optimizations
- **Redis caching** for frequently accessed data
- **Database indexing** for fast queries
- **Connection pooling** for database efficiency
- **Gzip compression** for reduced bandwidth
- **Static asset caching** with long TTL

## 🛠️ Development Commands

### Local Development
```bash
# Start services
./scripts/local-dev.sh start

# View logs
./scripts/local-dev.sh logs [service-name]

# Stop services
./scripts/local-dev.sh stop

# Clean up
./scripts/local-dev.sh clean
```

### Docker Commands
```bash
# Build all images
docker-compose build

# Start specific service
docker-compose up registration-api

# View service logs
docker-compose logs -f chat-api

# Execute commands in container
docker-compose exec postgres psql -U postgres -d sg_farmers_db
```

## 🧪 Testing

### API Testing
```bash
# Health checks
curl http://localhost/health
curl http://localhost/api/farmers/health
curl http://localhost/api/search/health
curl http://localhost/api/chat/health

# Register farmer
curl -X POST http://localhost/api/farmers/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","farm_location":"Kranji"}'

# Search farmers
curl "http://localhost/api/search/farmers?q=john&location=kranji"

# Chat with AI
curl -X POST http://localhost/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What crops grow well in Singapore?"}'
```

## 🔧 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker status
docker-compose ps

# View service logs
docker-compose logs [service-name]

# Restart specific service
docker-compose restart [service-name]
```

#### Database Connection Issues
```bash
# Check database status
docker-compose exec postgres pg_isready -U postgres

# Connect to database
docker-compose exec postgres psql -U postgres -d sg_farmers_db

# View database logs
docker-compose logs postgres
```

#### Port Conflicts
```bash
# Check port usage
netstat -tulpn | grep :3000

# Stop conflicting services
sudo systemctl stop [service-name]
```

## 💰 Cost Optimization

### AWS Cost Management
- **Reserved Instances** for predictable workloads
- **Spot Instances** for development environments
- **Auto Scaling** to match demand
- **S3 Lifecycle Policies** for log archival
- **CloudWatch Log Retention** policies
- **Regular resource cleanup** automation

### Estimated Monthly Costs (Production)
- **ECS Fargate**: $150-300
- **RDS PostgreSQL**: $100-200
- **ElastiCache Redis**: $50-100
- **Application Load Balancer**: $25
- **CloudFront**: $10-50
- **Route53**: $1
- **Total**: ~$336-676/month

## 📞 Support & Maintenance

### Regular Tasks
- **Weekly**: Review CloudWatch metrics and alerts
- **Monthly**: Update container images and dependencies
- **Quarterly**: Security audit and cost optimization
- **Annually**: Disaster recovery testing

### Monitoring Checklist
- [ ] All services healthy and responding
- [ ] Database performance within thresholds
- [ ] Cache hit rates optimized
- [ ] Error rates below 1%
- [ ] Response times under 500ms
- [ ] SSL certificates valid
- [ ] Backup processes working
- [ ] Security patches applied

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Singapore Government for agricultural support initiatives
- AWS for cloud infrastructure services
- OpenAI for AI chat capabilities
- Open source community for tools and libraries

---

**Ready for production deployment with enterprise-grade security, monitoring, and scalability.**