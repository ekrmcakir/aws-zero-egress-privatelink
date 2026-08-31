variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "isolated_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the isolated subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnets"
}

variable "environment" {
  type        = string
  description = "Environment identifier"
}
