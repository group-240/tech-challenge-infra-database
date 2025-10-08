# 🗄️ Tech Challenge - Infraestrutura de Banco de Dados

Terraform para RDS PostgreSQL com deploy automático via **GitHub Actions**.

## 📋 Recursos Provisionados

- **Amazon RDS PostgreSQL** (instância db.t3.micro)
- **DB Subnet Group** nas subnets privadas
- **Security Group** restringindo acesso à VPC
- **Backups automáticos** com retenção de 7 dias

## 🚀 Deploy Automático


### GitHub Secrets Necessários

```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
DB_PASSWORD=MinhaSenh@123!
```

### Fluxo CI/CD

1. **Pull Request** → Terraform plan no comentário
2. **Merge para main** → Terraform apply automático
3. **Rollback** → Revert commit

### Workflow Automático

```yaml
# .github/workflows/main.yml
- name: Terraform Apply
  run: |
    terraform init
    terraform plan -var="db_password=${{ secrets.DB_PASSWORD }}"
    terraform apply -auto-approve
```

## 🔧 Configuração

### Variáveis Principais

- `db_name`: techchallenge
- `db_username`: postgres
- `db_password`: Via GitHub Secret (`DB_PASSWORD`)

### Configurações de Segurança

- Banco em **subnets privadas** apenas
- Acesso restrito ao **CIDR da VPC**
- **Criptografia em repouso** habilitada
- **Senha via GitHub Secret** (`DB_PASSWORD`)
- **Backups automáticos** configurados

## 📁 Estrutura

```
├── main.tf            # RDS PostgreSQL
├── variables.tf       # Variáveis de entrada
└── .github/workflows/ # Pipeline CI/CD
    └── main.yml
```

## 📤 Outputs

Este módulo exporta:

- `rds_endpoint`: Endpoint de conexão do banco
- `rds_port`: Porta de conexão (5432)

## 🔗 Dependências

Este módulo depende dos outputs do `tech-challenge-infra-core`:

- `vpc_id`: ID da VPC
- `private_subnet_ids`: IDs das subnets privadas
- `vpc_cidr_block`: CIDR da VPC

## 🔧 Configuração de Conexão

### Para Aplicação Spring Boot

```yaml
# application.yml
spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST}:5432/techchallenge
    username: postgres
    password: ${DB_PASSWORD}
```

### Variáveis de Ambiente

```bash
DB_HOST=tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com
DB_PASSWORD=MinhaSenh@123!
DB_NAME=techchallenge
DB_USER=postgres
```

## 🛡️ Segurança

- **Acesso restrito** apenas da VPC
- **Criptografia** em repouso e em trânsito
- **Backups automáticos** para recuperação
- **Senha gerenciada** via GitHub Secrets