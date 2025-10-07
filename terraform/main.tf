terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "sg-farmers-terraform-state"
    key    = "sg-farmers-app/terraform.tfstate"
    region = "eu-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "sg-farmers-app"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Random ID for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}