# Catálogo SQL do sistema_ro

## Organização
- `sql/core` — extrações obrigatórias do pipeline
- `sql/auxiliares` — consultas de apoio e enriquecimento
- `sql/diagnostico` — validações e investigações
- `sql/legado` — consultas antigas preservadas fora do caminho crítico

## Core mínimo
- `lookup_contribuinte.sql`
- `dados_cadastrais.sql`
- `efd_reg_0000.sql`
- `efd_reg_0150.sql`
- `efd_reg_0190.sql`
- `efd_reg_0200.sql`
- `efd_reg_0205.sql`
- `efd_reg_0220.sql`
- `efd_c100.sql`
- `efd_c170.sql`
- `efd_c176.sql`
- `efd_c190.sql`
- `efd_c197.sql`
- `efd_bloco_h.sql`
- `efd_h005.sql`
- `nfe_itens.sql`
- `nfce_itens.sql`
- `nfe_eventos.sql`
- `fisconforme_cadastral.sql`
- `fisconforme_malhas.sql`

## Regra de ouro

Nenhuma SQL core deve tentar resolver sozinha:
- agregação de mercadorias
- classificação fiscal complexa por fallback
- conversão de unidades
- saldo de estoque sequencial
- lógica final de notificação do Fisconforme

Essas etapas pertencem ao pipeline de transformação.
