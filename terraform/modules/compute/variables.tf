variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC"
}

variable "subnet_id" {
  type        = string
  description = "Isolated Subnet ID to place the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance type"
  default     = "t3.micro"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM Instance Profile Name for SSM"
}

variable "s3_bucket_name" {
  type        = string
  description = "Private S3 bucket name for test uploads and artifacts"
}

variable "environment" {
  type        = string
  description = "Environment identifier"
}
