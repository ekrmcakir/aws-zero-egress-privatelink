# Security Group for VPC Interface Endpoints
resource "aws_security_group" "endpoints_sg" {
  name        = "${var.environment}-vpc-endpoints-sg"
  description = "Controls HTTPS traffic to AWS VPC Interface Endpoints (PrivateLink)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS inbound from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound inside VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-vpc-endpoints-sg"
  }
}

locals {
  interface_services = {
    ssm         = "com.amazonaws.${var.aws_region}.ssm"
    ssmmessages = "com.amazonaws.${var.aws_region}.ssmmessages"
    ec2messages = "com.amazonaws.${var.aws_region}.ec2messages"
    logs        = "com.amazonaws.${var.aws_region}.logs"
    monitoring  = "com.amazonaws.${var.aws_region}.monitoring"
    lambda      = "com.amazonaws.${var.aws_region}.lambda"
  }
}

# AWS PrivateLink Interface Endpoints
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each            = local.interface_services
  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-vpce-${each.key}"
    Type = "AWS-PrivateLink"
  }
}

# S3 Gateway Endpoint (High-throughput, free data transfer for S3 in VPC)
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = {
    Name = "${var.environment}-vpce-s3-gateway"
    Type = "AWS-Gateway-Endpoint"
  }
}
