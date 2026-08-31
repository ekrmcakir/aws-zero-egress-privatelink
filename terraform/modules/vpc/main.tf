resource "aws_vpc" "isolated" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-zero-egress-vpc"
    Type        = "AirGapped-Isolated"
    Description = "Air-gapped VPC with zero internet egress (No IGW, No NAT Gateway)"
  }
}

resource "aws_subnet" "isolated" {
  count                   = length(var.isolated_subnet_cidrs)
  vpc_id                  = aws_vpc.isolated.id
  cidr_block              = var.isolated_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-isolated-subnet-${var.availability_zones[count.index]}"
    Tier = "Isolated"
  }
}

# Route table containing only local VPC routing (10.0.0.0/16 -> local)
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.isolated.id

  tags = {
    Name = "${var.environment}-isolated-rt"
    Type = "Local-Only"
  }
}

resource "aws_route_table_association" "isolated" {
  count          = length(aws_subnet.isolated)
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

# Network ACL for Air-Gapped Subnets
resource "aws_network_acl" "isolated" {
  vpc_id     = aws_vpc.isolated.id
  subnet_ids = aws_subnet.isolated[*].id

  # Allow all inbound traffic (Route Tables and Security Groups enforce zero-egress boundary)
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow all outbound traffic
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.environment}-isolated-nacl"
  }
}
