locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "devops-team"
    CreatedAt   = timestamp()
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
  
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}