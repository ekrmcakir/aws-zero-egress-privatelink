# Lookup latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_region" "current" {}

# Lookup S3 Gateway Endpoint Prefix List for granular egress rules
data "aws_prefix_list" "s3_gateway" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.s3"]
  }
}

# Security Group for Private EC2 Instance
resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-private-ec2-sg"
  description = "Security Group for Zero-Egress EC2 Instance (No SSH, Only HTTPS to VPC Endpoints)"
  vpc_id      = var.vpc_id

  # Ingress: Allow internal communication within VPC
  ingress {
    description = "Allow inbound HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Allow custom app port 8080 from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress: Allow HTTPS outbound to VPC CIDR (for Interface Endpoints like SSM & CloudWatch)
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

  # Egress: Allow HTTPS outbound to S3 Gateway Endpoint Prefix List
  egress {
    description     = "Outbound HTTPS to S3 Gateway Endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3_gateway.id]
  }

  tags = {
    Name = "${var.environment}-private-ec2-sg"
  }
}

# Launch EC2 Instance into Isolated Subnet
resource "aws_instance" "private_workload" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = var.iam_instance_profile
  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh", {
    s3_bucket_name = var.s3_bucket_name
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name        = "${var.environment}-airgapped-ec2-worker"
    Environment = var.environment
    Egress      = "Zero-Egress"
  }
}
