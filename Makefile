# SG Farmers App Makefile
# Provides convenient commands for development and deployment

.PHONY: help install build test start stop restart logs clean deploy

# Default target
help: ## Show this help message
	@echo "SG Farmers App - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development Commands
install: ## Install all dependencies
	@echo "Installing dependencies..."
	@cd services/registration-api && npm install
	@cd services/search-api && npm install
	@cd services/chat-api && npm install
	@cd services/frontend && npm install
	@echo "Dependencies installed successfully"

build: ## Build all Docker images
	@echo "Building Docker images..."
	@docker-compose build
	@echo "Images built successfully"

test: ## Run tests for all services
	@echo "Running tests..."
	@cd services/registration-api && npm test
	@cd services/search-api && npm test
	@cd services/chat-api && npm test
	@cd services/frontend && npm test
	@echo "Tests completed"

start: ## Start all services in development mode
	@echo "Starting services..."
	@chmod +x scripts/local-dev.sh
	@./scripts/local-dev.sh start

stop: ## Stop all services
	@echo "Stopping services..."
	@docker-compose down

restart: ## Restart all services
	@echo "Restarting services..."
	@docker-compose restart

logs: ## Show logs for all services
	@docker-compose logs -f

logs-api: ## Show logs for registration API
	@docker-compose logs -f registration-api

logs-search: ## Show logs for search API
	@docker-compose logs -f search-api

logs-chat: ## Show logs for chat API
	@docker-compose logs -f chat-api

logs-frontend: ## Show logs for frontend
	@docker-compose logs -f frontend

logs-db: ## Show database logs
	@docker-compose logs -f postgres

status: ## Show service status
	@docker-compose ps
	@echo ""
	@./scripts/local-dev.sh status

clean: ## Clean up containers, volumes, and images
	@echo "Cleaning up..."
	@docker-compose down -v --remove-orphans
	@docker system prune -f
	@echo "Cleanup completed"

# Database Commands
db-migrate: ## Run database migrations
	@echo "Running database migrations..."
	@docker-compose exec postgres psql -U postgres -d sg_farmers_db -f /docker-entrypoint-initdb.d/init.sql

db-seed: ## Seed database with sample data
	@echo "Seeding database..."
	@docker-compose exec postgres psql -U postgres -d sg_farmers_db -c "INSERT INTO farmers (name, email, farm_location) VALUES ('Test Farmer', 'test@example.com', 'Test Location') ON CONFLICT DO NOTHING;"

db-reset: ## Reset database
	@echo "Resetting database..."
	@docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS sg_farmers_db;"
	@docker-compose exec postgres psql -U postgres -c "CREATE DATABASE sg_farmers_db;"
	@make db-migrate

db-backup: ## Backup database
	@echo "Creating database backup..."
	@docker-compose exec postgres pg_dump -U postgres sg_farmers_db > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup created"

# Production Deployment Commands
deploy-infra: ## Deploy infrastructure only
	@echo "Deploying infrastructure..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh infrastructure

deploy-apps: ## Deploy applications only
	@echo "Deploying applications..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh images
	@./scripts/deploy.sh services

deploy-frontend: ## Deploy frontend only
	@echo "Deploying frontend..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh frontend

deploy-all: ## Deploy everything to production
	@echo "Deploying to production..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh all

# AWS Commands
aws-login: ## Login to AWS ECR
	@echo "Logging in to AWS ECR..."
	@aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.eu-west-2.amazonaws.com

aws-build-push: ## Build and push images to ECR
	@echo "Building and pushing images..."
	@chmod +x scripts/build-and-push.sh
	@./scripts/build-and-push.sh

# Terraform Commands
tf-init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	@cd terraform && terraform init

tf-plan: ## Plan Terraform deployment
	@echo "Planning Terraform deployment..."
	@cd terraform && terraform plan

tf-apply: ## Apply Terraform configuration
	@echo "Applying Terraform configuration..."
	@cd terraform && terraform apply

tf-destroy: ## Destroy Terraform infrastructure
	@echo "Destroying Terraform infrastructure..."
	@cd terraform && terraform destroy

# Security Commands
security-scan: ## Run security scan on Docker images
	@echo "Running security scan..."
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image sg-farmers-app_registration-api
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image sg-farmers-app_search-api
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image sg-farmers-app_chat-api
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image sg-farmers-app_frontend

lint: ## Run linting on all services
	@echo "Running linting..."
	@cd services/registration-api && npm run lint || true
	@cd services/search-api && npm run lint || true
	@cd services/chat-api && npm run lint || true
	@cd services/frontend && npm run lint || true

# Monitoring Commands
health-check: ## Check health of all services
	@echo "Checking service health..."
	@curl -f http://localhost/health || echo "Main health check failed"
	@curl -f http://localhost/api/farmers/health || echo "Registration API health check failed"
	@curl -f http://localhost/api/search/health || echo "Search API health check failed"
	@curl -f http://localhost/api/chat/health || echo "Chat API health check failed"

load-test: ## Run basic load test
	@echo "Running load test..."
	@ab -n 100 -c 10 http://localhost/health

# Development Utilities
shell-api: ## Open shell in registration API container
	@docker-compose exec registration-api sh

shell-db: ## Open PostgreSQL shell
	@docker-compose exec postgres psql -U postgres -d sg_farmers_db

shell-redis: ## Open Redis shell
	@docker-compose exec redis redis-cli

# Environment Setup
setup-dev: ## Setup development environment
	@echo "Setting up development environment..."
	@cp .env.example .env
	@echo "Please edit .env file with your configuration"
	@make install
	@make build
	@echo "Development environment setup complete"

setup-prod: ## Setup production environment
	@echo "Setting up production environment..."
	@cp terraform/terraform.tfvars.example terraform/terraform.tfvars
	@echo "Please edit terraform/terraform.tfvars with your configuration"
	@echo "Production environment setup complete"

# Documentation
docs: ## Generate API documentation
	@echo "Generating API documentation..."
	@echo "API documentation would be generated here"

# Backup and Restore
backup: ## Create full backup
	@echo "Creating backup..."
	@make db-backup
	@echo "Backup completed"

# Version Management
version: ## Show current version
	@echo "SG Farmers App Version Information:"
	@echo "Registration API: $(shell cd services/registration-api && node -p "require('./package.json').version")"
	@echo "Search API: $(shell cd services/search-api && node -p "require('./package.json').version")"
	@echo "Chat API: $(shell cd services/chat-api && node -p "require('./package.json').version")"
	@echo "Frontend: $(shell cd services/frontend && node -p "require('./package.json').version")"