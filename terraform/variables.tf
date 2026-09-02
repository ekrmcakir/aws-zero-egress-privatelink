variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the isolated VPC"
  default     = "10.0.0.0/16"
}

variable "isolated_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for isolated subnets (no IGW, no NAT Gateway)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones to deploy subnets in"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the private workload"
  default     = "t3.micro"
}
