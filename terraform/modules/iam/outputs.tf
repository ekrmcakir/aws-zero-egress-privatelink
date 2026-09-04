output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "Name of the IAM Instance Profile for EC2"
}

output "ec2_role_arn" {
  value       = aws_iam_role.ec2_role.arn
  description = "ARN of the EC2 IAM Role"
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "ARN of the Lambda IAM Role"
}
