# SG Farmers App - Production Deployment Guide

## Quick Deploy Commands

```bash
# 1. Setup environment
cp .env.example .env
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# 2. Edit configuration files with your values

# 3. Deploy everything
make deploy-all

# 4. Local development
make start
```

## Services Overview

- **Registration API** (3000) - Farmer registration & grants
- **Search API** (3001) - Search & filtering  
- **Chat API** (3002) - AI assistance
- **Frontend** (3003) - React UI
- **Database** - PostgreSQL
- **Cache** - Redis
- **Proxy** - Nginx

## AWS Infrastructure

- ECS Fargate cluster
- RDS PostgreSQL Multi-AZ
- ElastiCache Redis
- Application Load Balancer
- CloudFront + S3
- Route53 DNS
- ACM SSL certificates

## Key Files

- `docker-compose.yml` - Local development
- `terraform/` - AWS infrastructure
- `scripts/deploy.sh` - Production deployment
- `scripts/local-dev.sh` - Local development
- `Makefile` - Common commands

## Production URLs

After deployment:
- Frontend: `https://your-domain.com`
- API: `https://your-domain.com/api/*`

## Monitoring

- CloudWatch dashboards
- Health check endpoints
- Automated alerts
- Centralized logging