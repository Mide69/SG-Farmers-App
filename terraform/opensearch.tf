# OpenSearch Domain
resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.project_name}-search"
  engine_version = "OpenSearch_2.3"
  
  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 3
    
    dedicated_master_enabled = true
    master_instance_type     = "t3.small.search"
    master_instance_count    = 3
    
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 2
    }
  }
  
  vpc_options {
    security_group_ids = [aws_security_group.opensearch.id]
    subnet_ids         = aws_subnet.private[*].id
  }
  
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }
  
  encrypt_at_rest {
    enabled = true
  }
  
  node_to_node_encryption {
    enabled = true
  }
  
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
  
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.project_name}-search/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = [
              "10.0.0.0/16"
            ]
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-opensearch"
  }
}