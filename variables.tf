variable "aws_region" {
  description = "Região da AWS"
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
  description = "Usuário master do banco de dados"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
  default     = "TechChallenge2025!"
}
