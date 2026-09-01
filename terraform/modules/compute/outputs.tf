output "instance_id" {
  value       = aws_instance.private_workload.id
  description = "ID of the private EC2 instance"
}

output "private_ip" {
  value       = aws_instance.private_workload.private_ip
  description = "Private IP address of the EC2 instance"
}

output "security_group_id" {
  value       = aws_security_group.ec2_sg.id
  description = "Security Group ID of the EC2 instance"
}
