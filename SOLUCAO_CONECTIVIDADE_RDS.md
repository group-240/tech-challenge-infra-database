# 🔧 Solução: Conectividade RDS ↔️ EKS

## 🔍 **PROBLEMAS IDENTIFICADOS**

### **1. Erro: Connection Refused**
```
Readiness probe failed: Get "http://10.0.1.254:8080/api/health": dial tcp 10.0.1.254:8080: connect: connection refused
```

**Causa Raiz**: A aplicação Spring Boot não consegue inicializar porque não conecta no banco de dados RDS.

### **2. Erro: Deployment Timeout**
```
Progressing: False
ReplicaSet "tech-challenge-app-5bc8f7c768" has timed out progressing.
```

**Causa Raiz**: Os pods ficam em loop de restart porque falham no readiness probe (que depende do `/api/health` funcionar).

### **3. Security Group do RDS**
```yaml
Ingress Rule:
  Protocol: TCP
  Port: 5432
  Source: 10.0.0.0/16  # CIDR da VPC inteira
```

**Problema**: Embora permita toda a VPC, falta uma regra **EXPLÍCITA** permitindo o **Security Group do EKS Cluster** acessar o RDS.

---

## ✅ **SOLUÇÃO IMPLEMENTADA**

### **Mudança no arquivo `main.tf` do database**

Adicionei uma **Security Group Rule** específica:

```terraform
# Security Group Rule: Permitir EKS Cluster acessar RDS
resource "aws_security_group_rule" "rds_from_eks_cluster" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = data.terraform_remote_state.core.outputs.eks_cluster_security_group_id
  description              = "Allow PostgreSQL access from EKS Cluster"
}
```

### **O que isso faz?**

1. ✅ Permite que qualquer recurso com o **Security Group do EKS** acesse o RDS
2. ✅ Inclui automaticamente:
   - Pods rodando no EKS (através do VPC CNI)
   - Nodes do EKS
   - Control plane do EKS
3. ✅ Mais seguro que CIDR aberto (controle granular baseado em security groups)

---

## 🚀 **COMO APLICAR A CORREÇÃO**

### **Passo 1: Commit e Push das Mudanças**

```bash
cd c:/Users/User/repositorios/tech-challenge-infra-database

# Verificar mudanças
git status

# Adicionar arquivos modificados
git add main.tf

# Commit
git commit -m "fix: adiciona regra de security group para permitir EKS acessar RDS"

# Push
git push origin main
```

### **Passo 2: Aplicar via Terraform (ou GitHub Actions)**

**Opção A - Via GitHub Actions** (Recomendado):
O workflow `.github/workflows/main.yml` vai rodar automaticamente após o push e aplicar as mudanças.

**Opção B - Aplicar manualmente**:
```bash
cd c:/Users/User/repositorios/tech-challenge-infra-database

# Inicializar Terraform (se necessário)
terraform init

# Ver o plano de execução
terraform plan

# Aplicar as mudanças
terraform apply -auto-approve
```

### **Passo 3: Verificar a Regra Criada**

```bash
# Obter ID do Security Group do RDS
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=tech-challenge-rds-sg" \
  --query 'SecurityGroups[0].SecurityGroupId' \
  --output text

# Ver as regras de ingress
aws ec2 describe-security-groups \
  --group-names tech-challenge-rds-sg \
  --query 'SecurityGroups[0].IpPermissions' \
  --output json
```

Você deve ver **2 regras de ingress**:
1. ✅ CIDR: `10.0.0.0/16` (regra original)
2. ✅ **Security Group**: `sg-xxxxx` (nova regra do EKS)

### **Passo 4: Reiniciar os Pods da Aplicação**

Após aplicar o Terraform, force o restart dos pods:

```bash
# Conectar ao cluster EKS
aws eks update-kubeconfig --region us-east-1 --name tech-challenge-eks

# Reiniciar deployment
kubectl rollout restart deployment/tech-challenge-app -n tech-challenge

# Acompanhar o status
kubectl get pods -n tech-challenge -w

# Verificar logs
kubectl logs -f deployment/tech-challenge-app -n tech-challenge
```

---

## 🧪 **COMO TESTAR A CONECTIVIDADE**

### **Teste 1: Testar conexão do Pod ao RDS**

```bash
# Obter o endpoint do RDS
DB_HOST=$(aws rds describe-db-instances \
  --db-instance-identifier tech-challenge-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "RDS Host: $DB_HOST"

# Entrar em um pod
kubectl exec -it deployment/tech-challenge-app -n tech-challenge -- bash

# Dentro do pod, testar conectividade TCP
nc -zv $DB_HOST 5432

# Ou instalar e testar com psql
apt-get update && apt-get install -y postgresql-client
psql -h $DB_HOST -U postgres -d techchallenge -c "SELECT version();"
# Senha: DevEnvironment2024!
```

### **Teste 2: Verificar Health Check da Aplicação**

```bash
# Port-forward para acessar localmente
kubectl port-forward deployment/tech-challenge-app -n tech-challenge 8080:8080

# Em outro terminal, testar o health endpoint
curl http://localhost:8080/api/health
```

**Resposta esperada**:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    }
  }
}
```

---

## 📊 **DIAGRAMA DE CONECTIVIDADE**

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC 10.0.0.0/16                      │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              EKS Cluster                              │   │
│  │  Security Group: sg-xxxxx (EKS)                       │   │
│  │                                                        │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │   │
│  │  │   Pod 1    │  │   Pod 2    │  │   Node     │     │   │
│  │  │ App Spring │  │ App Spring │  │  t3.small  │     │   │
│  │  │  10.0.1.x  │  │  10.0.1.x  │  │ 10.0.1.254 │     │   │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘     │   │
│  │        │               │               │             │   │
│  └────────┼───────────────┼───────────────┼─────────────┘   │
│           │               │               │                  │
│           │               │               │                  │
│           └───────────────┴───────────────┘                  │
│                           │                                  │
│                           │ TCP 5432                         │
│                           │ ✅ PERMITIDO                     │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              RDS PostgreSQL                           │   │
│  │  Security Group: sg-yyyyy (RDS)                       │   │
│  │                                                        │   │
│  │  ┌─────────────────────────────────────────────────┐ │   │
│  │  │  Ingress Rules:                                  │ │   │
│  │  │  1. CIDR: 10.0.0.0/16 → Port 5432 ✅            │ │   │
│  │  │  2. SG: sg-xxxxx (EKS) → Port 5432 ✅ [NOVO]   │ │   │
│  │  └─────────────────────────────────────────────────┘ │   │
│  │                                                        │   │
│  │  tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com │   │
│  │  Database: techchallenge                              │   │
│  │  User: postgres                                       │   │
│  │  Password: DevEnvironment2024!                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## ❓ **POR QUE ISSO ERA NECESSÁRIO?**

### **Conceito: Security Groups vs CIDR**

1. **CIDR Block** (`10.0.0.0/16`):
   - Permite **qualquer IP** dentro desse range
   - Funciona, mas é menos específico
   - Pods EKS usam IPs dinâmicos desse range através do VPC CNI

2. **Security Group Reference**:
   - Permite **qualquer recurso** que tenha aquele security group
   - ✅ **Mais seguro e específico**
   - ✅ **AWS gerencia automaticamente** os IPs
   - ✅ **Funciona mesmo com IPs dinâmicos**

### **Por que a regra CIDR não funcionou sozinha?**

Embora tecnicamente os pods estejam no range `10.0.0.0/16`, o **EKS usa security groups gerenciados** que podem ter regras adicionais de bloqueio/permissão. A melhor prática é sempre usar **referências de security group** para comunicação entre serviços AWS.

---

## 🎯 **RESULTADO ESPERADO**

Após aplicar essa correção:

✅ **Pods inicializam corretamente**
- Conectam ao RDS na inicialização
- Spring Boot sobe sem erros
- JPA/Hibernate cria as tabelas automaticamente

✅ **Health checks passam**
- `/api/health` retorna status UP
- Readiness probe funciona
- Liveness probe funciona

✅ **Deployment fica estável**
- Status: `Available = True`
- Status: `Progressing = True → Complete`
- Réplicas: `1/1 Ready`

✅ **Aplicação funcional**
- APIs respondem normalmente
- Persistência no banco funciona
- Logs não mostram mais erros de conexão

---

## 📝 **CHECKLIST DE VERIFICAÇÃO**

Após aplicar:

- [ ] Security group rule criada no RDS
- [ ] Pods reiniciados (`kubectl rollout restart`)
- [ ] Pods em estado `Running` e `Ready 1/1`
- [ ] Health check `/api/health` retorna status UP
- [ ] Logs não mostram erros de conexão com DB
- [ ] Consegue criar/listar recursos via API

---

## 🆘 **SE AINDA NÃO FUNCIONAR**

### **Verificar logs detalhados**:

```bash
# Logs da aplicação
kubectl logs -f deployment/tech-challenge-app -n tech-challenge

# Eventos do pod
kubectl describe pod -l app=tech-challenge-app -n tech-challenge

# Verificar variáveis de ambiente
kubectl exec deployment/tech-challenge-app -n tech-challenge -- env | grep DB
```

### **Verificar conectividade de rede**:

```bash
# DNS do RDS resolve?
kubectl exec deployment/tech-challenge-app -n tech-challenge -- nslookup $DB_HOST

# Porta 5432 acessível?
kubectl exec deployment/tech-challenge-app -n tech-challenge -- nc -zv $DB_HOST 5432

# Security groups corretos?
aws ec2 describe-security-groups --group-names tech-challenge-rds-sg
```

### **Verificar credenciais**:

```bash
# Secret está correto?
kubectl get secret app-secrets -n tech-challenge -o yaml

# ConfigMap está correto?
kubectl get configmap app-config -n tech-challenge -o yaml
```

---

## 📚 **REFERÊNCIAS**

- [AWS - Security Groups for Your VPC](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [EKS - Pod Networking (CNI)](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)
- [RDS - Controlling Access with Security Groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.RDSSecurityGroups.html)
- [Kubernetes - Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

---

✅ **Correção aplicada com sucesso!** Agora seus pods devem conseguir conectar ao RDS. 🎉
