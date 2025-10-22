# ECR Repositories
resource "aws_ecr_repository" "registration_api" {
  name                 = "${var.project_name}-registration-api"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-registration-api-repo"
  }
}

resource "aws_ecr_repository" "search_api" {
  name                 = "${var.project_name}-search-api"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-search-api-repo"
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-frontend-repo"
  }
}

# Registration API Task Definition
resource "aws_ecs_task_definition" "registration_api" {
  family                   = "${var.project_name}-registration-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "registration-api"
      image = "${aws_ecr_repository.registration_api.repository_url}:latest"
      
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
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"
        }
      ]
      
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:endpoint::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
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
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "search-api"
      image = "${aws_ecr_repository.search_api.repository_url}:latest"
      
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
        },
        {
          name  = "OPENSEARCH_URL"
          value = "https://${aws_opensearch_domain.main.endpoint}"
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"
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

# ECS Services
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

resource "aws_appautoscaling_target" "search_api" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.search_api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "search_api_cpu" {
  name               = "${var.project_name}-search-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.search_api.resource_id
  scalable_dimension = aws_appautoscaling_target.search_api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.search_api.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Chat API ECR Repository
resource "aws_ecr_repository" "chat_api" {
  name                 = "${var.project_name}-chat-api"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-chat-api-repo"
  }
}

# Chat API Task Definition
resource "aws_ecs_task_definition" "chat_api" {
  family                   = "${var.project_name}-chat-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "chat-api"
      image = "${aws_ecr_repository.chat_api.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 3002
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
          value = "3002"
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"
        }
      ]
      
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:endpoint::"
        },
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "${aws_secretsmanager_secret.openai_key.arn}::"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.chat_api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      
      essential = true
    }
  ])
  
  tags = {
    Name = "${var.project_name}-chat-api-task"
  }
}

# Chat API Service
resource "aws_ecs_service" "chat_api" {
  name            = "${var.project_name}-chat-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.chat_api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.chat_api.arn
    container_name   = "chat-api"
    container_port   = 3002
  }
  
  depends_on = [aws_lb_listener.https]
  
  tags = {
    Name = "${var.project_name}-chat-api-service"
  }
}