# ------------------------------------------------------------------
# Arquivo: main.tf
# Descrição: Ponto de entrada principal do Terraform para o banco de dados.
# ------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "fiap-tech-challenge-tfstate-bucket"
    key            = "database/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Utiliza Data Source para buscar informações da infraestrutura core (VPC)
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "fiap-tech-challenge-tfstate-bucket"
    key    = "core/terraform.tfstate"
    region = var.aws_region
  }
}

# Grupo de segurança para o RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Permite acesso ao RDS a partir da VPC"
  vpc_id      = data.terraform_remote_state.core.outputs.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.core.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

# Subnet Group para o RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = data.terraform_remote_state.core.outputs.private_subnet_ids

  tags = {
    Name    = "${var.project_name}-rds-subnet-group"
    Project = var.project_name
  }
}

# Instância do RDS PostgreSQL
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  engine_version       = "14.9"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  publicly_accessible = false
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  tags = {
    Name    = "${var.project_name}-db"
    Project = var.project_name
  }
}

# Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}