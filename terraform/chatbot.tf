# Lex Bot for Chat Support
resource "aws_lexv2models_bot" "support_bot" {
  name     = "${var.project_name}-support-bot"
  role_arn = aws_iam_role.lex_bot_role.arn
  
  data_privacy {
    child_directed = false
  }
  
  idle_session_ttl_in_seconds = 300
  
  tags = {
    Name = "${var.project_name}-support-bot"
  }
}

# IAM Role for Lex Bot
resource "aws_iam_role" "lex_bot_role" {
  name = "${var.project_name}-lex-bot-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lex_bot_policy" {
  role       = aws_iam_role.lex_bot_role.name
  policy_arn = "arn:aws:iam::aws:policy/aws-service-role/LexBotPolicy"
}

# Lambda function for chat processing
resource "aws_lambda_function" "chat_processor" {
  filename         = "chat_processor.zip"
  function_name    = "${var.project_name}-chat-processor"
  role            = aws_iam_role.lambda_chat_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = aws_opensearch_domain.main.endpoint
      SQS_QUEUE_URL      = aws_sqs_queue.main.url
    }
  }
  
  tags = {
    Name = "${var.project_name}-chat-processor"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_chat_role" {
  name = "${var.project_name}-lambda-chat-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_chat_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_chat_policy" {
  name = "${var.project_name}-lambda-chat-policy"
  role = aws_iam_role.lambda_chat_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = [
          "${aws_opensearch_domain.main.arn}/*",
          aws_sqs_queue.main.arn
        ]
      }
    ]
  })
}

# API Gateway for Chat WebSocket
resource "aws_apigatewayv2_api" "chat_websocket" {
  name                       = "${var.project_name}-chat-websocket"
  protocol_type             = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  
  tags = {
    Name = "${var.project_name}-chat-websocket"
  }
}

# WebSocket Routes
resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.chat_websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.chat_websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_route" "message" {
  api_id    = aws_apigatewayv2_api.chat_websocket.id
  route_key = "message"
  target    = "integrations/${aws_apigatewayv2_integration.message.id}"
}

# WebSocket Integrations
resource "aws_apigatewayv2_integration" "connect" {
  api_id           = aws_apigatewayv2_api.chat_websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.chat_processor.invoke_arn
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id           = aws_apigatewayv2_api.chat_websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.chat_processor.invoke_arn
}

resource "aws_apigatewayv2_integration" "message" {
  api_id           = aws_apigatewayv2_api.chat_websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.chat_processor.invoke_arn
}

# WebSocket Deployment
resource "aws_apigatewayv2_deployment" "chat" {
  api_id = aws_apigatewayv2_api.chat_websocket.id
  
  depends_on = [
    aws_apigatewayv2_route.connect,
    aws_apigatewayv2_route.disconnect,
    aws_apigatewayv2_route.message
  ]
}

resource "aws_apigatewayv2_stage" "chat" {
  api_id        = aws_apigatewayv2_api.chat_websocket.id
  deployment_id = aws_apigatewayv2_deployment.chat.id
  name          = "prod"
  
  tags = {
    Name = "${var.project_name}-chat-stage"
  }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "chat_websocket" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chat_websocket.execution_arn}/*/*"
}

# DynamoDB table for chat sessions
resource "aws_dynamodb_table" "chat_sessions" {
  name           = "${var.project_name}-chat-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "connection_id"
  
  attribute {
    name = "connection_id"
    type = "S"
  }
  
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
  
  tags = {
    Name = "${var.project_name}-chat-sessions"
  }
}