# SITAFE — estado atual de implementação

## Objetivo

Este documento resume o que já está implementado no projeto em relação ao uso das tabelas SITAFE e o que ainda falta para aderir totalmente aos documentos funcionais de `mov_estoque`, anual, mensal e períodos.

## O que já está implementado

### 1. Referências carregadas por Parquet
O projeto já possui loaders para:
- `sitafe_cest_ncm.parquet`
- `sitafe_cest.parquet`
- `sitafe_ncm.parquet`
- `sitafe_produto_sefin.parquet`
- `sitafe_produto_sefin_aux.parquet`

### 2. Precedência de classificação
A inferência de `co_sefin` já segue a ordem:
1. `CEST + NCM`
2. `CEST`
3. `NCM`

### 3. Vigência histórica
O enriquecimento já anexa vigência por `data_ref` usando a tabela auxiliar do SITAFE.

### 4. Silver enriquecida
A silver enriquecida já persiste `itens_unificados_sefin`.

### 5. Execução preferencial
A execução validada principal já prefere `itens_unificados_sefin` quando ele existir.

### 6. Propagação inicial
A trilha v4 do pipeline passou a propagar para `item_unidades` e `mov_estoque` os campos:
- `co_sefin_agr`
- `co_sefin_final`
- `it_pc_interna`
- `it_in_st`
- `it_pc_mva`
- `it_in_mva_ajustado`
- `it_pc_reducao`
- `it_in_reducao_credito`

## O que ainda falta

### 1. Tornar a trilha v4 a principal de execução
Ainda falta ligar formalmente o `run_gold_pipeline_v4` à runtime principal.

### 2. Derivados fiscais mais completos
As tabelas mensal, anual e de períodos ainda não implementam integralmente:
- ST textual por período;
- `aliq_interna` com prioridade real da SEFIN;
- `ICMS_entr_desacob` da mensal;
- `ICMS_saidas_desac` e `ICMS_estoque_desac` da anual e períodos;
- lógica completa de MVA ajustado.

### 3. Integração explícita na documentação operacional principal
A documentação do fluxo principal ainda precisa destacar que o uso pleno do SITAFE depende da trilha enriquecida.

## Conclusão

O projeto já saiu do estágio de "SEFIN só como enriquecimento lateral" e passou a ter propagação real dos campos fiscais até `item_unidades` e `mov_estoque` em uma trilha nova. Ainda assim, a aderência completa aos documentos funcionais de estoque depende de fazer essa trilha virar a principal e completar as fórmulas fiscais das tabelas derivadas.
