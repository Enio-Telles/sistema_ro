# Plano de implementação — fases 01 a 04

## Fase 01 — Fundação do projeto

### Etapa 1.1 — Inicialização técnica
- consolidar `pyproject.toml`, `.env.example` e `.gitignore`
- criar estrutura `backend/`, `pipeline/`, `sql/`, `references/` e `docs/`
- definir convenção de nomes para bronze, silver e gold
- padronizar raiz de dados por `CNPJ_ROOT`
- documentar política de versionamento dos contratos

### Etapa 1.2 — Manifestos e governança
- criar manifesto de fontes SQL e Parquets obrigatórios
- classificar consultas em `core`, `auxiliares`, `diagnostico` e `legado`
- registrar referências estáticas SEFIN e suas vigências
- definir critérios de aceite por domínio
- definir backlog inicial de implementação do repositório

## Fase 02 — Extração bronze

### Etapa 2.1 — SQL core do contribuinte e EFD
- criar `lookup_contribuinte.sql`
- criar `dados_cadastrais.sql`
- criar `efd_reg_0000.sql`, `efd_reg_0150.sql` e `efd_reg_0190.sql`
- criar `efd_reg_0200.sql`, `efd_reg_0205.sql` e `efd_reg_0220.sql`
- criar `efd_c100.sql`, `efd_c170.sql`, `efd_c176.sql`, `efd_c190.sql`, `efd_c197.sql`

### Etapa 2.2 — SQL core documental e Fisconforme
- criar `efd_bloco_h.sql` e `efd_h005.sql`
- criar `nfe_itens.sql` e `nfce_itens.sql`
- criar `nfe_eventos.sql`
- criar `fisconforme_cadastral.sql`
- criar `fisconforme_malhas.sql`

## Fase 03 — Normalização silver

### Etapa 3.1 — Harmonização de chaves e tipos
- implementar normalização de CNPJ, IE e CPF
- implementar normalização de datas e períodos
- padronizar tipos numéricos e colunas monetárias
- gerar `id_linha_origem` por fonte
- gerar `codigo_fonte` por item fiscal

### Etapa 3.2 — Deduplicação e qualidade
- deduplicar documentos por chave fiscal e item
- deduplicar linhas EFD repetidas por arquivo e documento
- registrar anomalias de schema e colunas ausentes
- produzir relatórios de integridade por domínio
- persistir Parquets silver padronizados

## Fase 04 — Núcleo de mercadorias

### Etapa 4.1 — Identidade canônica da mercadoria
- criar `mercadoria_id` como chave estável de identidade
- criar `apresentacao_id` para separar embalagem/unidade física
- preservar `id_linha_origem` e `codigo_fonte` na ponte analítica
- definir `match_rule`, `match_confidence` e `match_version`
- registrar evidências de agrupamento e fallback

### Etapa 4.2 — Agregação rastreável
- separar `lista_descricoes` e `lista_desc_compl`
- gerar `produtos_agrupados_<cnpj>.parquet`
- gerar `id_agrupados_<cnpj>.parquet`
- gerar `produtos_final_<cnpj>.parquet`
- implementar log de merge manual e reversão por snapshot
