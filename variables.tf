variable "aws_region" {
  description = "Região da AWS - fixo em us-east-1"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "tech-challenge"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "techchallenge"
}

variable "db_username" {
  description = "Username para o banco de dados"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Password para o banco de dados RDS - HARDCODED para ambiente DEV (apenas estudo)"
  type        = string
  sensitive   = true
  default     = "DevPassword123!"  # Mínimo 8 chars com pelo menos 1 caractere especial
}
