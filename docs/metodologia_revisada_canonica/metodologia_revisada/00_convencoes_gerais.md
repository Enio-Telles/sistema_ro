# Convenções gerais

Este documento é a fonte canônica para enums, tipos, sinais e convenções de
nomenclatura reutilizados nas demais camadas. Qualquer divergência entre os
documentos desta pasta e este aqui deve ser resolvida a favor deste.

## 1. `tipo_operacao` — enum canônico

| Código | Nome                    | Rótulo legível           | Sinal físico |
|:------:|:------------------------|:-------------------------|:------------:|
| 0      | ESTOQUE_INICIAL         | "0 - ESTOQUE INICIAL"    |  +1          |
| 1      | ENTRADA                 | "1 - ENTRADA"            |  +1          |
| 2      | SAIDA                   | "2 - SAIDA"              |  −1          |
| 3      | ESTOQUE_FINAL           | "3 - ESTOQUE FINAL"      |   0          |
| 4      | DEVOLUCAO_DE_VENDA      | "4 - DEVOLUCAO DE VENDA" |  +1          |
| 5      | DEVOLUCAO_DE_COMPRA     | "5 - DEVOLUCAO DE COMPRA"|  −1          |

- O **código inteiro** é a chave de decisão em todo o pipeline.
- O **rótulo** é apenas apresentação.
- Nunca use `str.starts_with` sobre rótulos para lógica — use o código.

## 2. `origem_evento_estoque`

Coluna **independente** de `tipo_operacao`, descrevendo a proveniência da
linha no pipeline:

| Valor                       | Significado |
|:----------------------------|:------------|
| `registro`                  | Linha original extraída de documento (C170, NF-e, NFC-e). |
| `inventario_bloco_h`        | Linha original do Bloco H (inventário declarado). |
| `estoque_inicial_derivado`  | Linha sintética com `tipo_operacao = ESTOQUE_INICIAL` replicando o inventário anterior. |
| `estoque_inicial_gerado`    | Linha sintética sem inventário anterior (fallback = 0). |
| `estoque_final_gerado`      | Linha sintética de fechamento periódico calculada pelo fluxo. |

## 3. Chaves de produto

| Campo                        | Estável? | Fonte                                                        |
|:-----------------------------|:--------:|:-------------------------------------------------------------|
| `id_linha_origem`            | Sim*     | PK da linha na fonte SQL                                     |
| `id_produto_origem`          | Sim      | `cnpj_titular || '|' || cod_item_titular`                    |
| `id_produto_agrupado_base`   | Sim      | hash determinístico da tupla (descricao_normalizada, ncm, cest, unidade_norm) |
| `id_produto_agrupado`        | Pode mudar | `base` OU override manual                                  |
| `versao_agrupamento`         | —        | Inteiro sequencial incrementado a cada alteração manual     |

\* `id_linha_origem` depende de a origem preservar PKs entre cargas; caso
contrário, ele é estável **apenas dentro de uma mesma carga**.

**Regra importante — CNPJ usado na chave.** É sempre o CNPJ do
**estabelecimento titular do SPED/NFC-e** (declarante), nunca o CNPJ do
emitente na compra. Para NF-e de entrada, o `cod_item_titular` vem do
mapeamento C170→0200 feito no cadastro do próprio titular.

## 4. Nomenclatura de colunas — sufixos

| Sufixo       | Significado                                               |
|:-------------|:----------------------------------------------------------|
| `_periodo`   | Agregado por período de inventário                        |
| `_mes`       | Agregado por mês civil                                    |
| `_ano`       | Agregado por ano civil                                    |
| `_corrente`  | Valor cronológico materializado linha a linha (sem agregação) |
| `_override`  | Valor informado manualmente pelo auditor                  |
| `_origem`    | Enum indicando a fonte do valor ao lado                   |

**Coluna única de saldo.** A `movimentacao_estoque` materializa
`saldo_estoque_corrente` (running balance linha a linha). As tabelas
derivadas (períodos/mensal/anual) extraem seus saldos a partir desta coluna
com a função agregadora adequada — **não** existe `saldo_estoque_anual`
dentro da tabela mensal.

## 5. Arredondamento

| Categoria               | Casas decimais |
|:------------------------|:--------------:|
| Quantidades, saldos     |       4        |
| Preços médios, custos   |       4        |
| MVA, alíquotas          |       2        |
| MVA ajustado            |       6        |
| Valores monetários      |       2        |

O arredondamento só é aplicado no momento da **serialização** (escrita em
Parquet / apresentação). Cálculos intermediários preservam precisão total.

## 6. Custo médio ponderado — fórmula canônica

A cada evento `e` com quantidade física sinalizada `q_e` e valor total
`v_e` (positivo):

- **Entrada (q_e > 0):**
  ```
  custo_medio_novo = (custo_medio_ant * saldo_ant + v_e) / (saldo_ant + q_e)
  saldo_novo       = saldo_ant + q_e
  ```
- **Saída (q_e < 0):** custo médio **não muda**.
  ```
  saldo_novo = saldo_ant + q_e     # q_e já é negativo
  ```
- **Devolução de compra (q_e < 0):** sai pelo **custo médio corrente**,
  não pelo valor da devolução, para não distorcer a média.
- **Inventário (tipo_operacao = ESTOQUE_FINAL):** não altera saldo nem
  custo médio — apenas registra `estoque_final_declarado` para auditoria.

## 7. Filtros "válidas" para médias

Uma linha é **entrada válida** para cálculo de `pme`/`preco_medio_entradas_*`
se **todos** os critérios abaixo valem:

1. `tipo_operacao == ENTRADA`;
2. `quantidade_fisica > 0`;
3. `excluir_estoque != True`;
4. `cfop` não é de devolução (conjunto configurável);
5. `preco_item > 0`.

Análogo para **saída válida**, trocando ENTRADA por SAIDA.

## 8. Nomenclatura de arquivos Parquet

```
dados/CNPJ/<cnpj>/
├── fontes/
│   ├── c170_<cnpj>.parquet
│   ├── nfe_<cnpj>.parquet
│   ├── nfce_<cnpj>.parquet
│   └── bloco_h_<cnpj>.parquet
├── cadastros/
│   ├── item_unidades_<cnpj>.parquet
│   ├── descricao_produtos_<cnpj>.parquet
│   └── produtos_final_<cnpj>.parquet
├── mapeamentos/
│   ├── map_produto_agrupado_<cnpj>.parquet
│   └── map_produto_agrupado_override_<cnpj>.parquet
└── analises/produtos/
    ├── movimentacao_estoque_<cnpj>.parquet
    ├── tabela_periodos_<cnpj>.parquet
    ├── tabela_mensal_<cnpj>.parquet
    └── tabela_anual_<cnpj>.parquet
```

## 9. Tabelas de referência SEFIN-RO (SITAFE)

As alíquotas internas, o regime de Substituição Tributária e a MVA são
carregados de cinco parquets SITAFE (mantidos em
``referencias/CO_SEFIN``). A integração vive em
``src/sistema_ro/sitafe.py``.

| Arquivo                              | Chave                     | Conteúdo                                                        |
| ------------------------------------ | ------------------------- | --------------------------------------------------------------- |
| ``sitafe_cest_ncm.parquet``          | ``(CEST, NCM)``           | ``co_sefin`` mais específico                                    |
| ``sitafe_cest.parquet``              | ``CEST``                  | ``co_sefin`` por CEST                                           |
| ``sitafe_ncm.parquet``               | ``NCM``                   | ``co_sefin`` por NCM (+ regulamento-ST, isento etc.)            |
| ``sitafe_produto_sefin.parquet``     | ``co_sefin``              | Catálogo de produtos SEFIN (nome + status ativo)                |
| ``sitafe_produto_sefin_aux.parquet`` | ``co_sefin`` + data       | Alíquota interna, flag ST, MVA, flags de UF, isenção, redução   |

**Precedência de ``co_sefin``**:
``(CEST, NCM)`` → ``CEST`` → ``NCM`` → ``desconhecido``.

**Vigência**: aplica-se a linha cuja ``data_inicio <= data_ref`` e
``data_final is null or data_final >= data_ref``. Em caso de
sobreposição (erro na fonte) usa-se a de ``data_inicio`` mais recente.

**Integração nas tabelas de agregação**: a função
``sitafe.parametros_fiscais_por_periodo`` devolve os DataFrames
``aliquotas_por_produto``, ``st_vigente_por_*`` e ``mva_efetivo_por_*``
no formato consumido por ``tabelas.gerar_tabela_anual`` /
``_mensal`` / ``_periodos``.
