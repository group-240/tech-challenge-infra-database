resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group para RDS PostgreSQL"
  vpc_id      = data.terraform_remote_state.core.outputs.vpc_id

  # Permitir acesso PostgreSQL APENAS de dentro da VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.core.outputs.vpc_cidr_block]
    description = "PostgreSQL access from VPC"
  }

  # Permitir todo tráfego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

# ------------------------------------------------------------------
# DB Subnet Group (usando subnets privadas do core)
# ------------------------------------------------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = data.terraform_remote_state.core.outputs.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-rds-subnet-group"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

# ------------------------------------------------------------------
# RDS PostgreSQL Instance
# ------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"
  
  # Engine
  engine         = "postgres"
  engine_version = "14.12"
  instance_class = "db.t3.micro"
  
  # Storage
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false  # PRIVADO - apenas dentro da VPC

  # Backup
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # Snapshots
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot"
  copy_tags_to_snapshot     = true

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # Proteção
  deletion_protection = false  # Dev environment

  tags = {
    Name        = "${var.project_name}-db"
    ManagedBy   = "terraform"
    Environment = "dev"
  }

  depends_on = [
    aws_db_subnet_group.rds_subnet_group,
    aws_security_group.rds_sg,
    aws_cloudwatch_log_group.rds_postgresql,
    aws_cloudwatch_log_group.rds_upgrade
  ]
}

# CloudWatch Log Groups para RDS (1 dia para custo mínimo)
resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name              = "/aws/rds/instance/${var.project_name}-db/postgresql"
  retention_in_days = 1

  tags = {
    Name        = "${var.project_name}-rds-postgresql-logs"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

resource "aws_cloudwatch_log_group" "rds_upgrade" {
  name              = "/aws/rds/instance/${var.project_name}-db/upgrade"
  retention_in_days = 1

  tags = {
    Name        = "${var.project_name}-rds-upgrade-logs"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}
