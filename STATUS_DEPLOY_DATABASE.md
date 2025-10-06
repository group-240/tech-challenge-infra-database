# 🚀 Deploy do Database em Andamento

## ✅ Commit Enviado

**Commit**: `211517d` - chore: adiciona terraform_wrapper false e valida config - deploy database

**Repositório**: tech-challenge-infra-database

**GitHub Actions**: https://github.com/group-240/tech-challenge-infra-database/actions

## 📊 O que Está Sendo Criado

### 1. Security Group (RDS)
- Nome: `tech-challenge-rds-sg`
- Porta 5432 aberta apenas para a VPC
- Privado (sem acesso externo)

### 2. DB Subnet Group
- Nome: `tech-challenge-rds-subnet-group`
- 2 subnets privadas (us-east-1a, us-east-1b)
- Multi-AZ para alta disponibilidade

### 3. RDS PostgreSQL Instance
- **Identifier**: tech-challenge-db
- **Engine**: PostgreSQL 14.12
- **Instance**: db.t3.micro (mais barato)
- **Storage**: 20GB gp3, autoscaling até 100GB
- **Network**: Privado (dentro da VPC)
- **Backup**: 7 dias
- **Logs**: CloudWatch (retenção 1 dia)

### 4. CloudWatch Log Groups
- `/aws/rds/instance/tech-challenge-db/postgresql`
- `/aws/rds/instance/tech-challenge-db/upgrade`

## ⏱️ Timeline Esperada

```
[0-2 min]   ✅ Terraform Plan
            └── Validando configuração
            └── Verificando remote state do infra-core

[2-3 min]   🔄 Criando Security Group e Subnet Group
            └── Recursos de rede prontos rapidamente

[3-18 min]  🔄 Criando RDS Instance
            └── Provisionando db.t3.micro
            └── Configurando storage
            └── Aplicando security settings
            └── Habilitando backups
            
[18-20 min] ✅ Deploy Completo
            └── RDS disponível
            └── Endpoint pronto para conexão
```

**Tempo total estimado**: 15-20 minutos

## 🔍 Como Acompanhar

### Via GitHub Actions

1. Acesse: https://github.com/group-240/tech-challenge-infra-database/actions
2. Procure pelo workflow "Database Infrastructure CI/CD"
3. Veja os logs em tempo real

**Etapas do workflow**:
- ✅ Checkout
- ✅ Setup Terraform 1.5.0
- ✅ Configure AWS Credentials
- ✅ Terraform Init
- ✅ Terraform Validate
- 🔄 Terraform Apply (demora mais)

### Via AWS Console

#### RDS Dashboard
https://console.aws.amazon.com/rds/home?region=us-east-1#databases:

**Status esperados**:
1. `creating` (10-15 minutos)
2. `backing-up` (2-3 minutos) 
3. `available` ✅

#### Security Groups
https://console.aws.amazon.com/vpc/home?region=us-east-1#securityGroups:

Procure por: `tech-challenge-rds-sg`

## 📊 Outputs Esperados

Após o deploy, você terá acesso a:

```terraform
rds_endpoint        = "tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com:5432"
rds_address         = "tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com"
rds_port            = 5432
rds_db_name         = "techchallenge"
rds_username        = "postgres" (sensitive)
security_group_id   = "sg-xxxxx"
db_subnet_group_name = "tech-challenge-rds-subnet-group"
```

## 🔗 Conectividade

O RDS será acessível **apenas** de dentro da VPC:

### ✅ Podem conectar:
- Pods no EKS cluster
- Instâncias EC2 na VPC
- Lambda functions com VPC config

### ❌ NÃO podem conectar:
- Internet pública
- Seu computador local (sem VPN/bastion)
- Outros serviços fora da VPC

## 🎯 Validação Pós-Deploy

### 1. Verificar RDS Status

```bash
aws rds describe-db-instances \
  --db-instance-identifier tech-challenge-db \
  --region us-east-1 \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address,Endpoint.Port]'
```

**Esperado**: `["available", "tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com", 5432]`

### 2. Verificar Outputs do Terraform

No GitHub Actions, ao final do apply, você verá:

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:
rds_endpoint = "tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com:5432"
...
```

### 3. Testar Conectividade (do EKS)

Depois que a aplicação for deployada, você pode testar:

```bash
# De dentro de um pod no cluster
kubectl run postgres-test --rm -it --image=postgres:14 -- bash
psql -h tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com \
     -U postgres -d techchallenge
# Senha: DevPassword123!
```

## 💰 Custo

Com o RDS rodando:

| Recurso | Custo/hora | Custo/mês |
|---------|-----------|-----------|
| db.t3.micro | $0.017 | $12.41 |
| Storage 20GB gp3 | $0.003 | $2.30 |
| Backup (incluído) | $0 | $0 |
| **TOTAL** | **$0.020** | **~$14.71** |

## 🚨 Troubleshooting

### Se o deploy falhar:

1. **Timeout do RDS**
   - Normal se demorar mais de 20 minutos
   - RDS pode levar até 30 minutos em casos raros

2. **Erro "subnet group invalid"**
   - Verificar se infra-core tem outputs corretos
   - Verificar se subnets privadas existem

3. **Erro de quota AWS**
   - Verificar limite de RDS instances na conta
   - Conta AWS Academy tem limites

### Comandos de Debug

```bash
# Ver logs do Terraform
# (disponível no GitHub Actions)

# Ver estado do RDS
aws rds describe-db-instances --db-instance-identifier tech-challenge-db

# Ver eventos do RDS
aws rds describe-events \
  --source-type db-instance \
  --source-identifier tech-challenge-db
```

## 🚀 Próximos Passos

Quando o deploy completar (status "available"):

### 1. ✅ Validar Outputs
- Anotar o endpoint do RDS
- Guardar credentials (postgres / DevPassword123!)

### 2. 🚀 Deploy da Application
```bash
cd tech-challenge-application
git add -A
git commit -m "chore: deploy application to kubernetes"
git push
```

**O que será criado**:
- Kubernetes Deployment (aplicação Java)
- Service (ClusterIP)
- Ingress (com Load Balancer)
- ConfigMaps e Secrets (com conexão ao RDS)

**Tempo estimado**: 5-10 minutos

### 3. 🚀 Deploy do Gateway (Opcional)
```bash
cd tech-challenge-infra-gateway-lambda
git add -A
git commit -m "chore: deploy API Gateway"
git push
```

## 📚 Documentação

- **VALIDACAO_CONFIG.md** - Validação completa da configuração
- **main.tf** - Código Terraform do RDS
- **outputs.tf** - Outputs disponíveis

## 🎯 Estado Atual da Infraestrutura

```
✅ COMPLETO    tech-challenge-infra-core       (VPC, EKS, LB, Cognito, ECR)
🔄 DEPLOY      tech-challenge-infra-database   (RDS PostgreSQL)
⏳ PENDENTE    tech-challenge-application      (K8s Deployment)
⏳ PENDENTE    tech-challenge-infra-gateway    (API Gateway)
```

---

**Aguarde ~15-20 minutos e verifique o status no GitHub Actions!** 🚀

O RDS está sendo provisionado. Quando ficar "available", você pode prosseguir com o deploy da aplicação!
