output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the isolated Zero-Egress VPC"
}

output "isolated_subnet_ids" {
  value       = module.vpc.subnet_ids
  description = "List of isolated subnet IDs"
}

output "ec2_instance_id" {
  value       = module.compute.instance_id
  description = "EC2 Instance ID (Accessible solely via SSM Session Manager)"
}

output "ec2_private_ip" {
  value       = module.compute.private_ip
  description = "Private IP address of the EC2 instance"
}

output "lambda_function_name" {
  value       = module.lambda.lambda_function_name
  description = "VPC Lambda Sentinel function name"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.private_storage.bucket
  description = "Private S3 Bucket name"
}

output "ssm_connect_command" {
  value       = "aws ssm start-session --target ${module.compute.instance_id} --region ${var.aws_region}"
  description = "AWS CLI command to start an interactive shell on the EC2 instance without SSH/Internet"
}

output "lambda_test_command" {
  value       = "aws lambda invoke --function-name ${module.lambda.lambda_function_name} --region ${var.aws_region} response.json && cat response.json"
  description = "AWS CLI command to invoke the VPC Lambda Network Sentinel"
}
