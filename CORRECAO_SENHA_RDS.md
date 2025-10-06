# Correção do Erro "Invalid master password"

## 🔴 Erro Identificado

```
Error: creating RDS DB Instance (tech-challenge-db): 
operation error RDS: CreateDBInstance, 
api error InvalidParameterValue: Invalid master password
```

## 📋 Causa Raiz

A senha `DevPassword123!` não é aceita pelo RDS PostgreSQL.

### Requisitos de Senha do RDS PostgreSQL

Segundo a documentação AWS:

✅ **Permitido**:
- Letras maiúsculas e minúsculas (A-Z, a-z)
- Números (0-9)
- Alguns caracteres especiais: `_` (underscore), `.` (ponto), `-` (hífen)

❌ **NÃO Permitido**:
- `!` (exclamação)
- `@` (arroba)
- `#` (hashtag)
- `$` (cifrão)
- `%` (porcentagem)
- `^` (circunflexo)
- `&` (e comercial)
- `*` (asterisco)
- `(` `)` (parênteses)
- `/` (barra)
- Espaços

### Requisitos de Comprimento

- **Mínimo**: 8 caracteres
- **Máximo**: 30 caracteres (PostgreSQL) / 128 (outros engines)

## ✅ Correção Aplicada

### Antes (Com Erro)
```terraform
variable "db_password" {
  default = "DevPassword123!"  # ❌ Caractere ! não aceito
}
```

### Depois (Corrigido)
```terraform
variable "db_password" {
  default = "DevPassword123"  # ✅ Apenas letras e números
}
```

## 🎯 Nova Senha

**Senha corrigida**: `DevPassword123`

**Características**:
- ✅ 14 caracteres (dentro do limite 8-30)
- ✅ Contém letras maiúsculas (D, P)
- ✅ Contém letras minúsculas (e, v, a, s, s, w, o, r, d)
- ✅ Contém números (1, 2, 3)
- ✅ Sem caracteres especiais problemáticos
- ✅ Atende requisitos do RDS PostgreSQL

## 🔐 Alternativas Válidas

Se precisar de senha mais forte no futuro:

```terraform
# Opção 1: Com underscore
default = "Dev_Password_123"

# Opção 2: Com ponto
default = "Dev.Password.123"

# Opção 3: Com hífen
default = "Dev-Password-123"

# Opção 4: Mais longa
default = "DevPasswordForRDS2024"
```

## 📊 Outros Requisitos do RDS

Além da senha, o RDS PostgreSQL valida:

1. **Username não pode ser**:
   - ❌ `admin` (reservado)
   - ❌ `rdsadmin` (reservado)
   - ✅ `postgres` (OK - estamos usando)

2. **Database name**:
   - ✅ Apenas letras, números e underscores
   - ✅ Começar com letra
   - ✅ `techchallenge` (OK)

3. **Identifier**:
   - ✅ Apenas letras minúsculas, números e hífens
   - ✅ `tech-challenge-db` (OK)

## 🚀 Próximos Passos

1. ✅ **Correção aplicada** em `variables.tf`
2. 🔄 **Commit e push** para reaplica
3. ⏱️ **Aguardar** novo deploy (15-20 minutos)
4. ✅ **RDS será criado** com senha válida

## 🔧 Como Testar a Conexão

Após o deploy, a conexão será:

```bash
# De dentro de um pod no EKS
psql -h tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d techchallenge \
     -W
# Quando pedir senha, digite: DevPassword123
```

## 💡 Importante

**Em produção**, você deve:

1. **Usar AWS Secrets Manager**:
   ```terraform
   data "aws_secretsmanager_secret_version" "db_password" {
     secret_id = "rds-password"
   }
   
   resource "aws_db_instance" "main" {
     password = data.aws_secretsmanager_secret_version.db_password.secret_string
   }
   ```

2. **Ou usar variável de ambiente**:
   ```terraform
   variable "db_password" {
     type      = string
     sensitive = true
     # Sem default - forçar passar via -var ou TF_VAR_
   }
   ```

3. **Habilitar rotação automática** de senhas

Para este projeto **educacional/desenvolvimento**, a senha hardcoded simples é aceitável.

## 📚 Referências

- [AWS RDS Password Requirements](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html#RDS_Limits.Constraints)
- [PostgreSQL Password Constraints](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreatePostgreSQLInstance.html)

## ✅ Resumo

**Problema**: Senha com caractere `!` não aceito pelo RDS PostgreSQL

**Solução**: Simplificada para `DevPassword123` (apenas letras e números)

**Status**: Pronto para novo deploy!
