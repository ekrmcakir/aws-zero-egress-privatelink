variable "vpc_id" {
  type        = string
  description = "VPC ID where endpoints will be deployed"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs where Interface Endpoints ENIs will be placed"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Route table IDs to associate with Gateway Endpoints (e.g. S3)"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "environment" {
  type        = string
  description = "Environment identifier"
}
