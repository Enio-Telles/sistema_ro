# Conversão de unidades nas consultas analisadas

## Objetivo

Este documento identifica **quando a conversão de unidade deixa de ser opcional e passa a ser necessária** nas consultas analisadas na conversa, com foco especial em:

- ressarcimento com `C176`;
- mudança de tributação / mudança de código fiscal baseada em inventário (`H005/H010/H020`) e última entrada;
- consultas derivadas do núcleo comum (`MDC`) que comparam quantidades entre EFD, XML e Fronteira.

A regra central é simples:

> **sempre que duas quantidades forem comparadas, rateadas ou usadas para formar valor unitário, e as unidades de medida não forem comprovadamente equivalentes, a conversão passa a ser obrigatória.**

## Base estrutural disponível no acervo

O pacote já possuía a camada certa para isso:

- `sql_mdc/04_efd_produtos_0200_0220_base.sql` traz `unid_inv`, `unid_conv` e `fat_conv`;
- `sql_mdc/06_efd_c170_itens_base.sql` traz `unid` e `qtd` dos itens escriturados;
- `sql_mdc/08_efd_h005_h010_h020_inventario_base.sql` traz `unid`, `qtd` e `vl_unit` do inventário;
- `sql/03`, `sql/04`, `sql/09` e `sql/10` usam `qcom` e quantidade em ressarcimento;
- `sql_mdc/14_sitafe_nota_item_calculo_base.sql` traz `it_un_comercial` e `it_qt_comercial` do SITAFE.

## Quando a conversão é necessária

### Regra 1 — Divergência nominal de unidade
A conversão é necessária quando a unidade da origem e a unidade do destino são diferentes.

Exemplos:
- saída em `UN` e entrada em `CX`;
- inventário em `KG` e última entrada em `G`;
- SITAFE em `FD` e EFD em `UN`.

### Regra 2 — Existência de fator 0220 para o item
Mesmo quando a divergência não foi ainda demonstrada na amostra, a existência de `0220` para o item é um indício forte de que o item **circula ou é inventariado em mais de uma unidade**. Nessas hipóteses, qualquer comparação de quantidade deve verificar a unidade antes de concluir aderência.

### Regra 3 — Quantidades só fecham após aplicar fator
Quando `qtd_origem != qtd_destino`, mas a igualdade passa a existir com:

- `qtd_origem * fat_conv ≈ qtd_destino`, ou
- `qtd_origem / fat_conv ≈ qtd_destino`,

então a conversão não é apenas recomendável: ela é **materialmente necessária** para que a comparação tenha sentido fiscal.

### Regra 4 — Cálculo de valor unitário sobre quantidade heterogênea
Se o valor total está em uma base documental, mas a quantidade usada no divisor vem de outra unidade, o valor unitário fica distorcido. Isso afeta diretamente:

- ressarcimento ST por item;
- ICMS próprio unitário reconstruído;
- última entrada na mudança de tributação;
- PEPS/FIFO quando o estoque e a movimentação não usam a mesma unidade.

### Regra 5 — Mesmo item com múltiplas unidades no período
Se o mesmo `cod_item` aparece com mais de uma unidade ao longo do período, a comparação direta de quantidades passa a ser insegura mesmo quando, em uma linha isolada, a unidade parece igual.

## Aplicação por trilha

### 1. Ressarcimento (`C176`, XML, Fronteira)
A conversão deve ser tratada como necessária quando ocorrer pelo menos uma destas situações:

1. `C170.unid` da saída difere da unidade cadastral ou da unidade da última entrada;
2. `qtd_saida`, `quant_ult_e`, `qcom_saida` e `qcom_entrada` não são comparáveis na mesma unidade;
3. existe `0220` para o item envolvido;
4. a quantidade considerada no rateio (`qtd_considerada`) depende de `qcom_entrada` e `qcom_saida`, mas as unidades divergem;
5. o valor unitário do ST ou do ICMS próprio é calculado com divisor em unidade diferente da base documental.

**Impacto:** score de vínculo por quantidade, rateio de entrada, valor unitário reconstruído e valor total considerado podem ficar artificialmente errados.

### 2. Mudança de tributação / mudança de código
A conversão deve ser tratada como necessária quando:

1. `H010.unid` do inventário diverge da unidade da última entrada (`C170.unid`);
2. o item inventariado possui `0220` ativo no período;
3. `vl_unit` do inventário é comparado com valor unitário de entrada sem harmonizar a unidade;
4. a mesma mercadoria aparece inventariada por embalagem e adquirida por unidade comercial diferente.

**Impacto:** comparação entre estoque, última entrada e valor unitário fica contaminada; isso altera diagnóstico de mudança de tributação e reclassificação fiscal.

### 3. Fronteira / SITAFE / XML
A necessidade aparece quando `it_un_comercial` do SITAFE diverge da unidade usada na EFD ou no inventário do mesmo item. Nesses casos, o valor total do item pode continuar coerente, mas a quantidade e o valor unitário deixam de ser comparáveis sem conversão.

## Classificação operacional sugerida

### `SEM_CONVERSAO_NECESSARIA`
- unidades iguais; e
- não existe `0220` relevante; e
- quantidades já fecham sem fator.

### `CONVERSAO_OBRIGATORIA`
- unidades divergentes; ou
- quantidades só fecham com `fat_conv`; ou
- valor unitário depende de divisor em unidade diferente.

### `CONVERSAO_PROVAVEL`
- existe `0220`, mas a divergência ainda precisa ser comprovada no par documental analisado.

### `INVESTIGAR_SEM_FATOR`
- unidades divergentes, mas não foi localizado `0220` ou regra equivalente.

## Regra prática para auditoria

Antes de aceitar qualquer comparação de quantidade nas trilhas de ressarcimento e mudança de tributação, testar nesta ordem:

1. mesma unidade?
2. há `0220` para o item?
3. a igualdade de quantidades surge após multiplicar ou dividir por `fat_conv`?
4. o valor unitário foi calculado sobre a unidade correta?

Se a resposta for “não” em 1 e “sim” em 2 ou 3, a conversão é obrigatória.

## Arquivos adicionados para suportar essa detecção

- `sql_mdc/24_diagnostico_necessidade_conversao_unidade.sql`
- atualização do `sql_mdc/23_orquestracao_mdc_referencia.sql`
- atualização do `sql_mdc/README.md`
- atualização do `INDEX.txt`
