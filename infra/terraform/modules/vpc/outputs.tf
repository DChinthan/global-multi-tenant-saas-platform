output "vpc_id" {
  value = aws_vpc.this.id
}

output "azs" {
  value = local.azs
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_app_subnet_ids" {
  value = [for s in aws_subnet.private_app : s.id]
}

output "private_data_subnet_ids" {
  value = [for s in aws_subnet.private_data : s.id]
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_app_route_table_id" {
  value = aws_route_table.private_app.id
}

output "private_data_route_table_id" {
  value = aws_route_table.private_data.id
}

output "interface_endpoint_ids" {
  description = "Map of AWS service name (e.g. ecr.api) to its Interface Endpoint (PrivateLink) ID"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "vpc_endpoints_security_group_id" {
  value = try(aws_security_group.vpc_endpoints[0].id, null)
}

output "troubleshooting_lab_nacl_id" {
  description = "ID of the deliberately-broken NACL when enable_troubleshooting_lab = true (see nacl_lab.tf + docs/runbooks/nacl-eni-troubleshooting.md)"
  value       = try(aws_network_acl.lab_broken[0].id, null)
}