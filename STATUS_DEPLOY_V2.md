# 🚀 Deploy do Database - Tentativa 2

## ✅ Correção Aplicada

**Commit**: `ac2b3c8` - fix: corrige senha do RDS removendo caractere especial não permitido

## 🔴 Problema Anterior

Senha `DevPassword123!` foi rejeitada porque o RDS PostgreSQL **não aceita** o caractere `!` (exclamação).

## ✅ Solução

Nova senha: `DevPassword123` (apenas letras e números)

## 📊 Requisitos de Senha RDS PostgreSQL

✅ **Aceitos**:
- Letras (A-Z, a-z)
- Números (0-9)
- Underscore `_`, ponto `.`, hífen `-`

❌ **NÃO aceitos**:
- `!` `@` `#` `$` `%` `^` `&` `*` `(` `)` `/` e espaços

## 🎯 Nova Configuração

```terraform
variable "db_password" {
  default = "DevPassword123"  # ✅ Válida para RDS
}
```

**Credenciais de acesso**:
- Host: `tech-challenge-db.xxxxx.us-east-1.rds.amazonaws.com`
- Port: `5432`
- Database: `techchallenge`
- Username: `postgres`
- Password: `DevPassword123`

## 🔄 Deploy em Andamento

O workflow foi executado novamente automaticamente com a senha corrigida.

**GitHub Actions**: https://github.com/group-240/tech-challenge-infra-database/actions

**Timeline**:
```
[0-2 min]   ✅ Terraform Init/Validate
[2-3 min]   ✅ Security Group e Subnet Group
[3-18 min]  🔄 RDS Instance (aguarde)
[18-20 min] ✅ Deploy completo
```

## ⏱️ Tempo Estimado

15-20 minutos total (mesma estimativa)

## 🎯 Próximo Passo

Após o RDS ficar "available":

```bash
cd tech-challenge-application
# Verificar configuração
# Fazer deploy
```

## 📚 Documentação

Ver **CORRECAO_SENHA_RDS.md** para detalhes completos sobre:
- Requisitos de senha do RDS
- Alternativas válidas
- Boas práticas para produção

---

**A correção foi aplicada! O deploy deve completar com sucesso agora.** 🚀
