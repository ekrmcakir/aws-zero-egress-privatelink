output "lambda_function_name" {
  value       = aws_lambda_function.network_sentinel.function_name
  description = "Name of the Network Sentinel Lambda Function"
}

output "lambda_arn" {
  value       = aws_lambda_function.network_sentinel.arn
  description = "ARN of the Network Sentinel Lambda Function"
}

output "lambda_security_group_id" {
  value       = aws_security_group.lambda_sg.id
  description = "Security Group ID of the VPC Lambda Function"
}
