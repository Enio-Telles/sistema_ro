# Manifesto de dados do sistema_ro

> **Última revisão: 2026-04-18** — Alinhado ao pipeline gold_v20 real (C7).

## Fontes centrais

### Referências estáticas
- `sitafe_cest.parquet`
- `sitafe_cest_ncm.parquet`
- `sitafe_ncm.parquet`
- `sitafe_produto_sefin.parquet`
- `sitafe_produto_sefin_aux.parquet`
- dicionários oficiais de EFD, NF-e, NFC-e e CT-e

### Extrações SQL core
- lookup do contribuinte
- dados cadastrais
- registros estruturais da EFD
- itens de NFe e NFCe
- eventos de NFe
- malhas e cadastral do Fisconforme

## Regras estruturantes

1. SQL é camada bronze.
2. Parquet normalizado é camada silver.
3. Agregação, conversão, estoque e Fisconforme analítico são camada gold.
4. As referências de SEFIN entram como dimensões, não como parte da query pesada.
5. O caminho da mercadoria deve preservar `id_linha_origem`, `codigo_fonte`, `mercadoria_id`, `apresentacao_id` e `id_agrupado`.

## Parquets obrigatórios do caminho crítico

### Silver
- `efd_reg_0200_<cnpj>.parquet`
- `efd_reg_0220_<cnpj>.parquet`
- `efd_c170_<cnpj>.parquet`
- `nfe_itens_<cnpj>.parquet`
- `nfce_itens_<cnpj>.parquet`
- `bloco_h_<cnpj>.parquet`
- `fisconforme_cadastral_<cnpj>.parquet`
- `fisconforme_malhas_<cnpj>.parquet`

### Gold — produzidos pela trilha `gold_v20` (`GOLD_DATASET_NAMES_V2`)

> ℹ️ Lista reconciliada com `pipeline/persist_gold_v2.py` em 2026-04-18.

| Dataset | Produzido por `gold_v20` | Nota |
|--|--|--|
| `produtos_agrupados_<cnpj>.parquet` | ✅ | Inclui `origem_agrupamento`, `versao_agrupamento` (C2) |
| `id_agrupados_<cnpj>.parquet` | ✅ | |
| `produtos_final_<cnpj>.parquet` | ✅ | |
| `item_unidades_<cnpj>.parquet` | ✅ | Adicionado em `gold_v20`; não listado na versão anterior deste manifesto |
| `fatores_conversao_<cnpj>.parquet` | ✅ | Inclui `fator_heuristico`, `override_aplicado` (C4) |
| `log_conversao_anomalias_<cnpj>.parquet` | ✅ | Adicionado em `gold_v20`; não listado na versão anterior |
| `mov_estoque_<cnpj>.parquet` | ✅ | Join de fator por `id_agrupado+unid` (C5); inclui `factor_resolution_mode` |
| `aba_mensal_<cnpj>.parquet` | ✅ | |
| `aba_anual_<cnpj>.parquet` | ✅ | |
| `aba_periodos_<cnpj>.parquet` | ✅ | |
| `estoque_resumo_<cnpj>.parquet` | ✅ | |
| `estoque_alertas_<cnpj>.parquet` | ✅ | |
| ~~`mercadorias_canonicas_<cnpj>.parquet`~~ | ❌ | **Não produzido pelo pipeline atual** — era referência do `00` anterior; removido desta lista oficial |
| ~~`apresentacoes_mercadoria_<cnpj>.parquet`~~ | ❌ | **Não produzido pelo pipeline atual** — idem |

### Gold — metadados operacionais obrigatórios (C6)

Todo Parquet gold produzido por `persist_gold_outputs_v2` carrega:

- **`__run_id__`** — UUID do run de processamento (coluna intra-Parquet e metadata)
- **`__input_hash__`** — hash SHA-256 resumido dos inputs (coluna + metadata)
- **`__data_processamento__`** — timestamp ISO-8601 UTC (coluna + metadata)

## Organização do workspace

```text
workspace/
  sql/
  references/
  dados/
    CNPJ/
      <cnpj>/
        bronze/
        silver/
        gold/
        fisconforme/
  state/
```

## Fora do caminho crítico

Consultas diagnósticas, versões antigas (`v2`, `v3`, `v4`) e relatórios finais antigos devem permanecer em `sql/legado` ou `sql/diagnostico`, sem bloquear o pipeline principal.

## Datasets auxiliares planejados (não implementados)

Os datasets abaixo estão previstos no `33_plano_correcao` mas ainda não são produzidos:

| Dataset | Fase | Descrição |
|--|--|--|
| `log_agregacao_ambiguidades` | Fase 2 | Grupos com NCM/unidades heterogêneos |
| `log_aplicacao_mapa_manual` | Fase 2 | Rastreio de overrides de agrupamento |
| `log_conversao_overrides` | Fase 3 | Overrides de fator aplicados |
| `log_conversao_conflitos` | Fase 3 | Conflitos de diagnóstico de conversão |
| `log_mov_estoque_factor_fallback` | Fase 4 | Linhas que usaram fallback de fator |
