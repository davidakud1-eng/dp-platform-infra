output "vpc_id" {
  description = "ID of the DP VPC"
  value       = aws_vpc.dp_vpc.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

output "availability_zones" {
  value = keys(var.public_subnets)
}
output "internet_gateway_id" {
  value = aws_internet_gateway.dp_igw.id
}
output "public_route_table_id" {
  value = aws_route_table.public.id
}
output "jenkins_public_ip" {
  description = "Public IP address of the DP Jenkins Controller"
  value       = aws_instance.jenkins_controller.public_ip
}

output "build_agent_public_ip" {
  description = "Public IP address of the DP Permanent Jenkins Build Agent"
  value       = aws_instance.build_agent.public_ip
}

output "platform_ops_public_ip" {
  description = "Public IP address of the DP Platform Operations Server"
  value       = aws_instance.platform_ops.public_ip
}