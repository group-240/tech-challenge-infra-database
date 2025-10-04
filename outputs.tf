# ------------------------------------------------------------------
# Outputs do módulo database
# ------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS instance address (sem porta)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "Username do RDS"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "security_group_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds_sg.id
}

output "db_subnet_group_name" {
  description = "Nome do DB Subnet Group"
  value       = aws_db_subnet_group.rds_subnet_group.name
}
