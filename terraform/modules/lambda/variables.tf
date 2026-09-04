variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for Lambda VPC attachment"
}

variable "lambda_role_arn" {
  type        = string
  description = "IAM Role ARN for Lambda"
}

variable "s3_bucket_name" {
  type        = string
  description = "Private S3 bucket name"
}

variable "environment" {
  type        = string
  description = "Environment identifier"
}
