# SQS Queue for async processing
resource "aws_sqs_queue" "main" {
  name                      = "${var.project_name}-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = {
    Name = "${var.project_name}-main-queue"
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600
  
  tags = {
    Name = "${var.project_name}-dead-letter-queue"
  }
}

# SNS Topic for notifications
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-notifications"
  
  tags = {
    Name = "${var.project_name}-notifications"
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
  
  tags = {
    Name = "${var.project_name}-alerts"
  }
}

# SES Configuration for email notifications
resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# Route53 records for SES verification
resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# EventBridge Rule for application events
resource "aws_cloudwatch_event_rule" "application_events" {
  name        = "${var.project_name}-application-events"
  description = "Capture application events"
  
  event_pattern = jsonencode({
    source      = ["grant.registration.service"]
    detail-type = ["Application Submitted", "Application Approved", "Application Rejected"]
  })
  
  tags = {
    Name = "${var.project_name}-event-rule"
  }
}

# EventBridge Target to SNS
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.application_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.notifications.arn
}