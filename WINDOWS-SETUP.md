# Windows Setup Guide

Since `make` is not available on Windows, use these batch files instead:

## Development Setup

```cmd
# Setup development environment
setup-dev.bat

# Start all services
start-dev.bat

# Stop all services  
stop-dev.bat
```

## Production Deployment

```cmd
# Deploy everything to AWS
deploy.bat all

# Deploy only infrastructure
deploy.bat infrastructure

# Deploy only images
deploy.bat images

# Deploy only services
deploy.bat services

# Deploy only frontend
deploy.bat frontend
```

## Prerequisites

1. **Docker Desktop** - Download from docker.com
2. **Node.js 18+** - Download from nodejs.org
3. **AWS CLI** - Download from aws.amazon.com/cli
4. **Terraform** - Download from terraform.io

## Quick Start

1. Install prerequisites above
2. Run `setup-dev.bat`
3. Edit `.env` file with your configuration
4. Run `start-dev.bat`
5. Access app at http://localhost

## Service URLs

- Frontend: http://localhost
- Registration API: http://localhost/api/farmers
- Search API: http://localhost/api/search  
- Chat API: http://localhost/api/chat

## Troubleshooting

If services fail to start:
```cmd
# Check Docker status
docker ps

# View logs
docker-compose logs [service-name]

# Restart services
stop-dev.bat
start-dev.bat
```