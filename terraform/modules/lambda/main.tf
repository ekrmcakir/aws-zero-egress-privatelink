data "aws_region" "current" {}

# Lookup S3 Gateway Endpoint Prefix List
data "aws_prefix_list" "s3_gateway" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.s3"]
  }
}

# Package Python Lambda Code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/lambda"
  output_path = "${path.module}/sentinel.zip"
}

# Security Group for VPC Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "${var.environment}-vpc-lambda-sg"
  description = "Security Group for VPC Lambda Function (Zero-Egress)"
  vpc_id      = var.vpc_id

  # Egress: Allow HTTPS outbound to VPC Interface Endpoints
  egress {
    description = "Outbound HTTPS to VPC Interface Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress: Allow DNS queries to VPC Route 53 Resolver
  egress {
    description = "Outbound DNS (UDP) to VPC Resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Outbound DNS (TCP) to VPC Resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress: Allow HTTPS outbound to S3 Gateway Endpoint
  egress {
    description     = "Outbound HTTPS to S3 Gateway Endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3_gateway.id]
  }

  tags = {
    Name = "${var.environment}-vpc-lambda-sg"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.environment}-network-sentinel"
  retention_in_days = 14

  tags = {
    Name = "${var.environment}-sentinel-logs"
  }
}

# VPC Lambda Function
resource "aws_lambda_function" "network_sentinel" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-network-sentinel"
  role             = var.lambda_role_arn
  handler          = "sentinel.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      S3_BUCKET_NAME = var.s3_bucket_name
      ENVIRONMENT    = var.environment
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = {
    Name = "${var.environment}-network-sentinel"
  }
}
