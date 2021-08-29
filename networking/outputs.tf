# --- networking/outputs.tf

output "vpc_id_out" {
  value = aws_vpc.myvpc.id
}

output "db_subnet_group_name_out" {
  value = aws_db_subnet_group.db_subnet_group.*.name
}

output "db_security_group_out" {
  value = [aws_security_group.security_group["rds"].id]
}

output "public_security_group_out" {
  value = aws_security_group.security_group["public"].id
}

output "public_subnets_out" {
  value = aws_subnet.my_public_subnet.*.id
}