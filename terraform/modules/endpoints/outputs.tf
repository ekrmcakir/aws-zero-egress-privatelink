output "endpoints_security_group_id" {
  value       = aws_security_group.endpoints_sg.id
  description = "Security Group ID attached to Interface Endpoints"
}

output "interface_endpoint_ids" {
  value       = { for k, v in aws_vpc_endpoint.interface_endpoints : k => v.id }
  description = "Map of Interface Endpoint IDs"
}

output "s3_gateway_endpoint_id" {
  value       = aws_vpc_endpoint.s3_gateway.id
  description = "The ID of the S3 Gateway Endpoint"
}
