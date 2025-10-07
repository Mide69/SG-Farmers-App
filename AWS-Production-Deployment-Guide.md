# Grant Registration Service - AWS Production Deployment Guide

This guide provides step-by-step instructions to deploy the Grant Registration Service on AWS in a production-ready environment.

## Prerequisites

- AWS Account with administrative access
- AWS CLI installed and configured
- Terraform >= 1.0
- Docker installed
- Node.js >= 18.x
- Git

## Phase 1: Initial AWS Setup

### 1.1 AWS Account Configuration

```bash
# Configure AWS CLI
aws configure
# Enter: Access Key ID, Secret Access Key, Region (eu-west-2), Output format (json)

# Verify configuration
aws sts get-caller-identity
```

### 1.2 Create S3 Bucket for Terraform State

```bash
# Create unique bucket name
BUCKET_NAME="grant-service-terraform-state-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME --region eu-west-2
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
```

## Phase 2: Infrastructure as Code Setup

### 2.1 Create Terraform Configuration

Create `terraform/main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "grant-service/terraform.tfstate"
    region = "eu-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  default = "eu-west-2"
}

variable "environment" {
  default = "production"
}

variable "project_name" {
  default = "grant-registration-service"
}
```

### 2.2 Network Infrastructure

Create `terraform/network.tf`:

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "Private"
  }
}

# NAT Gateways
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

### 2.3 Security Groups

Create `terraform/security.tf`:

```hcl
# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-ecs-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  
  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
```

### 2.4 Database Setup

Create `terraform/database.tf`:

```hcl
# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = "grantservice"
  username = "dbadmin"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = true
  publicly_accessible    = false
  
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  tags = {
    Name = "${var.project_name}-database"
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store DB password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}/database/password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.db_password.result
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}
```

### 2.5 ECS Cluster

Create `terraform/ecs.tf`:

```hcl
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = false
  
  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Groups
resource "aws_lb_target_group" "registration_api" {
  name     = "${var.project_name}-reg-api"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "${var.project_name}-reg-api-tg"
  }
}

resource "aws_lb_target_group" "search_api" {
  name     = "${var.project_name}-search-api"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "${var.project_name}-search-api-tg"
  }
}

# ALB Listeners
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.registration_api.arn
  }
}

# Listener Rules
resource "aws_lb_listener_rule" "search_api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.search_api.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/search/*"]
    }
  }
}
```

## Phase 3: Application Deployment

### 3.1 Build and Push Docker Images

Create `scripts/build-and-push.sh`:

```bash
#!/bin/bash
set -e

# Variables
AWS_REGION="eu-west-2"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
PROJECT_NAME="grant-registration-service"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Create ECR repositories if they don't exist
aws ecr describe-repositories --repository-names "${PROJECT_NAME}-registration-api" --region $AWS_REGION || \
aws ecr create-repository --repository-name "${PROJECT_NAME}-registration-api" --region $AWS_REGION

aws ecr describe-repositories --repository-names "${PROJECT_NAME}-search-api" --region $AWS_REGION || \
aws ecr create-repository --repository-name "${PROJECT_NAME}-search-api" --region $AWS_REGION

aws ecr describe-repositories --repository-names "${PROJECT_NAME}-frontend" --region $AWS_REGION || \
aws ecr create-repository --repository-name "${PROJECT_NAME}-frontend" --region $AWS_REGION

# Build and push Registration API
echo "Building Registration API..."
cd services/registration-api
docker build -t $ECR_REGISTRY/${PROJECT_NAME}-registration-api:latest .
docker push $ECR_REGISTRY/${PROJECT_NAME}-registration-api:latest

# Build and push Search API
echo "Building Search API..."
cd ../search-api
docker build -t $ECR_REGISTRY/${PROJECT_NAME}-search-api:latest .
docker push $ECR_REGISTRY/${PROJECT_NAME}-search-api:latest

# Build and push Frontend
echo "Building Frontend..."
cd ../frontend
docker build -t $ECR_REGISTRY/${PROJECT_NAME}-frontend:latest .
docker push $ECR_REGISTRY/${PROJECT_NAME}-frontend:latest

echo "All images built and pushed successfully!"
```

### 3.2 ECS Task Definitions

Create `terraform/ecs-tasks.tf`:

```hcl
# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Registration API Task Definition
resource "aws_ecs_task_definition" "registration_api" {
  family                   = "${var.project_name}-registration-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "registration-api"
      image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-registration-api:latest"
      
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3000"
        }
      ]
      
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.registration_api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      
      essential = true
    }
  ])
  
  tags = {
    Name = "${var.project_name}-registration-api-task"
  }
}

# Search API Task Definition
resource "aws_ecs_task_definition" "search_api" {
  family                   = "${var.project_name}-search-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "search-api"
      image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-search-api:latest"
      
      portMappings = [
        {
          containerPort = 3001
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3001"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.search_api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      
      essential = true
    }
  ])
  
  tags = {
    Name = "${var.project_name}-search-api-task"
  }
}

data "aws_caller_identity" "current" {}
```

### 3.3 ECS Services

Create `terraform/ecs-services.tf`:

```hcl
# Registration API Service
resource "aws_ecs_service" "registration_api" {
  name            = "${var.project_name}-registration-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.registration_api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.registration_api.arn
    container_name   = "registration-api"
    container_port   = 3000
  }
  
  depends_on = [aws_lb_listener.https]
  
  tags = {
    Name = "${var.project_name}-registration-api-service"
  }
}

# Search API Service
resource "aws_ecs_service" "search_api" {
  name            = "${var.project_name}-search-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.search_api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.search_api.arn
    container_name   = "search-api"
    container_port   = 3001
  }
  
  depends_on = [aws_lb_listener.https]
  
  tags = {
    Name = "${var.project_name}-search-api-service"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "registration_api" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.registration_api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "registration_api_cpu" {
  name               = "${var.project_name}-registration-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.registration_api.resource_id
  scalable_dimension = aws_appautoscaling_target.registration_api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.registration_api.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
```

## Phase 4: Frontend and CDN

### 4.1 S3 and CloudFront

Create `terraform/frontend.tf`:

```hcl
# S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "${var.project_name}-frontend"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  aliases = [var.domain_name]
  
  tags = {
    Name = "${var.project_name}-cloudfront"
  }
}

resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${var.project_name} frontend"
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}
```

## Phase 5: Monitoring and Logging

### 5.1 CloudWatch Setup

Create `terraform/monitoring.tf`:

```hcl
# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "registration_api" {
  name              = "/ecs/${var.project_name}-registration-api"
  retention_in_days = 30
  
  tags = {
    Name = "${var.project_name}-registration-api-logs"
  }
}

resource "aws_cloudwatch_log_group" "search_api" {
  name              = "/ecs/${var.project_name}-search-api"
  retention_in_days = 30
  
  tags = {
    Name = "${var.project_name}-search-api-logs"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.registration_api.name, "ClusterName", aws_ecs_cluster.main.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Service Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  
  dimensions = {
    ServiceName = aws_ecs_service.registration_api.name
    ClusterName = aws_ecs_cluster.main.name
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}
```

## Phase 6: Deployment Commands

### 6.1 Deploy Infrastructure

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan -var="domain_name=your-domain.com"

# Apply infrastructure
terraform apply -var="domain_name=your-domain.com"
```

### 6.2 Deploy Applications

```bash
# Make build script executable
chmod +x scripts/build-and-push.sh

# Build and push Docker images
./scripts/build-and-push.sh

# Update ECS services to use new images
aws ecs update-service --cluster grant-registration-service-cluster \
  --service grant-registration-service-registration-api \
  --force-new-deployment

aws ecs update-service --cluster grant-registration-service-cluster \
  --service grant-registration-service-search-api \
  --force-new-deployment
```

### 6.3 Deploy Frontend

```bash
# Build React application
cd services/frontend
npm run build

# Sync to S3
aws s3 sync build/ s3://your-frontend-bucket-name/

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## Phase 7: Post-Deployment

### 7.1 Verify Deployment

```bash
# Check ECS services
aws ecs describe-services --cluster grant-registration-service-cluster \
  --services grant-registration-service-registration-api grant-registration-service-search-api

# Check ALB health
aws elbv2 describe-target-health --target-group-arn YOUR_TARGET_GROUP_ARN

# Test endpoints
curl -k https://your-domain.com/api/health
curl -k https://your-domain.com/api/search/health
```

### 7.2 Set up Monitoring

```bash
# Create CloudWatch dashboard URL
echo "Dashboard URL: https://console.aws.amazon.com/cloudwatch/home?region=eu-west-2#dashboards:name=grant-registration-service-dashboard"

# Set up log insights queries
aws logs start-query --log-group-name "/ecs/grant-registration-service-registration-api" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/'
```

## Environment Variables

Create `.env` file for each service:

```bash
# Registration API
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://username:password@host:5432/database
JWT_SECRET=your-jwt-secret
COMPANIES_HOUSE_API_KEY=your-api-key

# Search API
NODE_ENV=production
PORT=3001
ELASTICSEARCH_URL=https://your-elasticsearch-endpoint
ROYAL_MAIL_API_KEY=your-api-key
```

## Security Checklist

- [ ] All traffic encrypted with TLS 1.3
- [ ] Database passwords stored in AWS Secrets Manager
- [ ] Security groups follow least privilege principle
- [ ] WAF rules configured for common attacks
- [ ] CloudTrail enabled for audit logging
- [ ] VPC Flow Logs enabled
- [ ] ECS tasks run with minimal IAM permissions
- [ ] S3 buckets have public access blocked
- [ ] Regular security updates scheduled

## Cost Optimization

- [ ] Reserved instances purchased for baseline capacity
- [ ] Auto-scaling configured to match demand
- [ ] S3 lifecycle policies for log archival
- [ ] CloudWatch log retention set appropriately
- [ ] Unused resources cleaned up regularly

## Troubleshooting

### Common Issues

1. **ECS Service Won't Start**
   ```bash
   aws ecs describe-services --cluster CLUSTER_NAME --services SERVICE_NAME
   aws logs filter-log-events --log-group-name LOG_GROUP_NAME
   ```

2. **Database Connection Issues**
   ```bash
   aws rds describe-db-instances --db-instance-identifier DB_IDENTIFIER
   aws secretsmanager get-secret-value --secret-id SECRET_NAME
   ```

3. **Load Balancer Health Check Failures**
   ```bash
   aws elbv2 describe-target-health --target-group-arn TARGET_GROUP_ARN
   ```

## Maintenance

### Regular Tasks

- Weekly: Review CloudWatch metrics and logs
- Monthly: Update container images with security patches
- Quarterly: Review and optimize costs
- Annually: Disaster recovery testing

This guide provides a complete production deployment process for the Grant Registration Service on AWS. Customize the domain names, resource sizes, and configurations based on your specific requirements.