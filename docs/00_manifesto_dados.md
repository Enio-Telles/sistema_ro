# Manifesto de dados do sistema_ro

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

### Gold
- `mercadorias_canonicas_<cnpj>.parquet`
- `apresentacoes_mercadoria_<cnpj>.parquet`
- `produtos_agrupados_<cnpj>.parquet`
- `id_agrupados_<cnpj>.parquet`
- `produtos_final_<cnpj>.parquet`
- `fatores_conversao_<cnpj>.parquet`
- `mov_estoque_<cnpj>.parquet`
- `aba_mensal_<cnpj>.parquet`
- `aba_anual_<cnpj>.parquet`
- `aba_periodos_<cnpj>.parquet`
- `estoque_resumo_<cnpj>.parquet`
- `estoque_alertas_<cnpj>.parquet`

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
