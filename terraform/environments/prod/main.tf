terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  availability_zones = local.availability_zones
}

# Security Module
module "security" {
  source = "../../modules/security"
  
  vpc_id      = module.networking.vpc_id
  name_prefix = local.name_prefix
  common_tags = local.common_tags
  domain_name = var.domain_name
}

# Database Module
module "database" {
  source = "../../modules/database"
  
  vpc_id                    = module.networking.vpc_id
  database_subnet_group     = module.networking.database_subnet_group_name
  database_security_group   = module.security.database_security_group_id
  name_prefix              = local.name_prefix
  common_tags              = local.common_tags
  
  # Database configuration
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_engine_version        = var.db_engine_version
  
  # Redis configuration
  redis_node_type          = var.redis_node_type
  redis_num_cache_nodes    = var.redis_num_cache_nodes
}

# Compute Module
module "compute" {
  source = "../../modules/compute"
  
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  alb_security_group   = module.security.alb_security_group_id
  ecs_security_group   = module.security.ecs_security_group_id
  name_prefix          = local.name_prefix
  common_tags          = local.common_tags
  
  # ECS configuration
  ecs_cpu              = var.ecs_cpu
  ecs_memory           = var.ecs_memory
  min_capacity         = var.min_capacity
  max_capacity         = var.max_capacity
  
  # Database connection
  database_url         = module.database.database_url
  redis_url           = module.database.redis_url
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  
  name_prefix = local.name_prefix
  common_tags = local.common_tags
  
  # ECS cluster for monitoring
  ecs_cluster_name = module.compute.ecs_cluster_name
  ecs_service_names = module.compute.ecs_service_names
}