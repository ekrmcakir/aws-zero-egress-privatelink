variable "environment" {
  type        = string
  description = "Environment identifier"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the private S3 bucket"
}
