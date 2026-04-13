# Plano de implementação — fases 05 a 08

## Fase 05 — Conversão de unidades

### Etapa 5.1 — Fator estrutural e referência
- gerar `item_unidades_<cnpj>.parquet`
- escolher `unid_ref` por regra explícita e fallback controlado
- calcular fator estrutural por embalagem, volume, peso e multiplicidade
- registrar `tipo_fator`, `fonte_fator` e `confianca_fator`
- persistir `fatores_conversao_<cnpj>.parquet`

### Etapa 5.2 — Override e reconciliação
- preservar `fator_manual` e `unid_ref_manual`
- recalcular fatores quando a unidade de referência mudar
- criar log de produtos sem preço médio utilizável
- criar log de reconciliação após reagrupamento
- bloquear propagação automática de fator ambíguo

## Fase 06 — Enriquecimento fiscal e SEFIN

### Etapa 6.1 — Classificação fiscal auxiliar
- carregar `sitafe_cest.parquet`, `sitafe_cest_ncm.parquet` e `sitafe_ncm.parquet`
- carregar `sitafe_produto_sefin.parquet`
- inferir `co_sefin` por `CEST+NCM`, `CEST` e `NCM`
- registrar descrição do `co_sefin` inferido
- salvar logs de classificação sem correspondência

### Etapa 6.2 — Vigência tributária
- carregar `sitafe_produto_sefin_aux.parquet`
- resolver vigência por data de emissão/saída
- anexar `it_pc_interna`, `it_in_st`, `it_pc_mva` e demais parâmetros
- distinguir atributos `inferido` e atributos de origem auxiliar
- persistir datasets enriquecidos para consumo do estoque

## Fase 07 — Movimentação de estoque

### Etapa 7.1 — Construção da `mov_estoque`
- integrar `c170`, `nfe`, `nfce`, `bloco_h` e linhas `gerado`
- aplicar `id_agrupado`, `unid_ref` e `fator`
- calcular `q_conv`, `preco_unit` e sinal da operação
- produzir `saldo_estoque_anual`, `entr_desac_anual` e `custo_medio_anual`
- preservar flags de devolução, repetição e exclusão de estoque

### Etapa 7.2 — Período de inventário
- criar `periodo_inventario` por reinício de estoque inicial
- calcular `saldo_estoque_periodo`
- calcular `entr_desac_periodo`
- calcular `custo_medio_periodo`
- salvar `mov_estoque_<cnpj>.parquet` pronta para agregações derivadas

## Fase 08 — Derivações analíticas de estoque

### Etapa 8.1 — Tabela mensal
- gerar `aba_mensal_<cnpj>.parquet`
- resumir entradas, saídas, estoque e custo médio por mês
- calcular `ICMS_entr_desacob` com regra de ST do mês
- materializar campos `_periodo` na visão mensal
- incluir listas de unidades do mês e unidades de referência do mês

### Etapa 8.2 — Tabelas anual e por período
- gerar `aba_anual_<cnpj>.parquet`
- gerar `aba_periodos_<cnpj>.parquet`
- calcular `saidas_desacob` e `estoque_final_desacob`
- calcular `ICMS_saidas_desac` e `ICMS_estoque_desac`
- produzir `estoque_resumo_<cnpj>.parquet` e `estoque_alertas_<cnpj>.parquet`
