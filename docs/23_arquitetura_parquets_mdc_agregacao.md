# Arquitetura de Parquets — MDC, Agregação e Gold

## Objetivo

Este documento consolida a arquitetura recomendada de Parquets do projeto considerando a diretriz funcional de que **toda análise de produtos deve considerar a agregação**.

Em consequência:
- o MDC materializa a base canônica bruta;
- a agregação é uma camada obrigatória de identidade do produto;
- todas as análises de produto, conversão, estoque e fiscalidade passam a consumir fontes enriquecidas com `id_agrupado`.

## 1. Princípio central

A trilha operacional recomendada passa a ser:

```text
Oracle/SQL -> Parquets MDC base -> Agregação obrigatória -> Fontes *_agr -> Gold analítico
```

Isso significa que as tabelas analíticas de produto não devem consumir diretamente os Parquets brutos do MDC quando o objeto de análise envolver identidade, quantidade, preço médio, conversão, estoque, ST ou ICMS por mercadoria.

## 2. Camadas propostas

### 2.1 Camada `mdc_base`

Camada canônica de extração, contendo fatos e dimensões mínimas auditáveis.

Parquets recomendados:
- `efd_entregas_base`
- `efd_participantes_base`
- `efd_produtos_base`
- `efd_documentos_base`
- `efd_itens_base`
- `efd_c176_ressarcimento_base`
- `efd_inventario_base`
- `efd_ajustes_documentais_base`
- `efd_apuracao_base`
- `efd_ajustes_apuracao_base`
- `bi_documentos_base`
- `bi_xml_campos_extras_base`
- `sitafe_nota_item_base`
- `sitafe_lancamento_pagamento_base`
- `dim_cfop_ajustes_base`
- `dim_fiscal_sefin_base`
- `arrecadacao_pendencias_base`
- `cte_rateio_frete_base`
- `diagnostico_conversao_unidade_base`

### 2.2 Camada `agregacao`

Camada obrigatória de identidade do produto.

Saídas obrigatórias:
- `mapa_manual_agregacao`
- `map_produto_agrupado`
- `produtos_agrupados`
- `id_agrupados`
- `produtos_final`

Regras:
- agrupamento automático estrito por `descricao_normalizada`;
- `descr_item` e `descr_compl` semanticamente separados;
- qualquer associação entre descrições diferentes ocorre apenas por mapa manual.

### 2.3 Camada `fontes_agr`

Camada de fontes fiscais enriquecidas com `id_agrupado`.

Saídas obrigatórias:
- `c170_agr`
- `nfe_agr`
- `nfce_agr`
- `bloco_h_agr`

Auditorias recomendadas:
- `c170_agr_sem_id_agrupado`
- `nfe_agr_sem_id_agrupado`
- `nfce_agr_sem_id_agrupado`
- `bloco_h_agr_sem_id_agrupado`

### 2.4 Camada `gold_produtos`

Camada analítica de produto. Deve consumir apenas as fontes agregadas.

Saídas recomendadas:
- `item_unidades`
- `fatores_conversao`
- `log_conversao_anomalias`
- `mov_estoque`
- `aba_mensal`
- `aba_anual`
- `aba_periodos`
- `estoque_resumo`
- `estoque_alertas`

## 3. Sequência recomendada

1. materializar `mdc_base`;
2. gerar `codigo_fonte`, `id_linha_origem` e `descricao_normalizada` nas fontes-base;
3. construir `agregacao`;
4. enriquecer `c170`, `nfe`, `nfce`, `bloco_h` para `fontes_agr`;
5. só então executar `gold_produtos`.

## 4. Regras de governança

- sem produto bruto em análise final;
- `id_agrupado` é obrigatório nas tabelas de produto da trilha principal;
- `descr_compl` não entra em `lista_descricoes`;
- `mapa_manual_agregacao` prevalece sobre o agrupamento automático;
- identificação fiscal final do item (`co_sefin`) ocorre sobre identidade agregada.

## 5. Benefícios esperados

- rastreabilidade uniforme entre SQL, Parquet e análise;
- menor risco de comparar quantidades entre produtos semanticamente diferentes;
- base melhor para conversão de unidades;
- estoque e derivação fiscal mais consistentes;
- revisão manual de agregação desacoplada da extração bruta.
