output "vpc_id" {
  value       = aws_vpc.isolated.id
  description = "The ID of the isolated VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.isolated.cidr_block
  description = "The CIDR block of the isolated VPC"
}

output "subnet_ids" {
  value       = aws_subnet.isolated[*].id
  description = "List of IDs of the isolated subnets"
}

output "route_table_id" {
  value       = aws_route_table.isolated.id
  description = "The ID of the local-only route table"
}
