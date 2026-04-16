# Mínimo denominador comum das consultas analisadas

## A. Objetivo

Este bloco cria um **núcleo canônico de consultas-base** a partir do qual se pode
recompor as famílias de consultas analisadas nesta conversa sem depender de um
novo SQL monolítico para cada relatório.

A ideia central é a seguinte:
- tudo que se repetiu nas análises foi reduzido a **camadas mínimas auditáveis**;
- cada camada vira uma consulta-base estável;
- relatórios, painéis, dossiês e trilhas analíticas passam a ser **derivações**
  desse núcleo.

## B. Critério de minimalidade

O núcleo foi construído para conter apenas o que reaparece de modo estrutural nas
consultas analisadas:

1. identificação do contribuinte e da competência;
2. seleção da última EFD válida;
3. documentos e itens da EFD;
4. blocos específicos de ressarcimento (`C176`) e inventário (`H005/H010/H020`);
5. apuração e ajustes (`C197`, `E110`, `E111`, `E210`, `E220`);
6. documentos do BI/XML (modelos 55, 65 e 57);
7. extração direta de campos do XML bruto quando a fato não basta;
8. nota/item/cálculo/lançamento do SITAFE/Fronteira;
9. dimensões fiscais (CFOP, ajustes, NCM, CEST, produto SEFIN, vigências);
10. arrecadação, pendências e núcleo fiscal-cadastral de dossiê.

Esse recorte permite regenerar as consultas analisadas **no nível fiscal e
fiscal-documental**. Nos dossiês XML muito amplos, o núcleo cobre o eixo fiscal,
cadastral, conta corrente e ação fiscal; não tenta exaurir todas as consultas de
apoio administrativo não fiscais.

## C. Arquivos criados

Foram incluídos no pacote:

- `sql_mdc/00_parametros_canonicos.sql`
- `sql_mdc/01_contribuinte_localidade_base.sql`
- `sql_mdc/02_efd_reg0000_ultima_entrega_base.sql`
- `sql_mdc/03_efd_participantes_0150_base.sql`
- `sql_mdc/04_efd_produtos_0200_0220_base.sql`
- `sql_mdc/05_efd_c100_documentos_base.sql`
- `sql_mdc/06_efd_c170_itens_base.sql`
- `sql_mdc/07_efd_c176_ressarcimento_base.sql`
- `sql_mdc/08_efd_h005_h010_h020_inventario_base.sql`
- `sql_mdc/09_efd_c197_ajustes_documentais_base.sql`
- `sql_mdc/10_efd_apuracao_e110_e210_base.sql`
- `sql_mdc/11_efd_ajustes_e111_e220_base.sql`
- `sql_mdc/12_bi_documentos_55_65_57_base.sql`
- `sql_mdc/13_bi_xml_nfe_campos_extras_base.sql`
- `sql_mdc/14_sitafe_nota_item_calculo_base.sql`
- `sql_mdc/15_sitafe_lancamento_pagamento_base.sql`
- `sql_mdc/16_dimensoes_fiscais_cfop_ajustes_base.sql`
- `sql_mdc/17_dimensoes_fiscais_ncm_cest_sefin_base.sql`
- `sql_mdc/18_arrecadacao_pendencias_base.sql`
- `sql_mdc/19_cte_rateio_frete_base.sql`
- `sql_mdc/20_dossie_cadastro_conta_corrente_base.sql`
- `sql_mdc/21_dossie_historico_societario_regime_base.sql`
- `sql_mdc/22_dossie_acao_fiscal_base.sql`
- `sql_mdc/23_orquestracao_mdc_referencia.sql`
- `sql_mdc/README.md`

## D. Mapa de cobertura por família analisada

### 1. Ressarcimento C176 / versão V4
Usa principalmente:
- 02, 04, 05, 06, 07
- 12, 13, 14, 17
- e depois deriva o vínculo, o score e o cálculo final.

### 2. Mudança de tributação / Bloco H / última entrada
Usa principalmente:
- 02, 04, 05, 06, 08
- 12, 17
- 10 e 11 para fechamento com apuração.

### 3. Fronteira após 2022
Usa principalmente:
- 02, 05, 06, 07
- 12, 13, 14, 17
- e opcionalmente 11 para reconciliação com ajustes.

### 4. Fronteira até 2022
Usa principalmente:
- 12, 13, 14, 17, 19
- porque a trilha histórica depende do rateio de frete/ICMS-frete via CT-e.

### 5. Auditoria EFD x documentos eletrônicos (55, 65, 57)
Usa principalmente:
- 02, 05, 10, 11
- 12
- e 18 quando o objetivo for enriquecer com pendências ou arrecadação.

### 6. Fronteira completo
Usa principalmente:
- 12, 14, 15, 17
- podendo usar 18 para leitura financeira complementar.

### 7. Relatório XML EFD Master
Usa principalmente:
- 02, 05, 09, 10, 11, 16, 18
- com agregações e HTML de apresentação derivados.

### 8. Relatório XML Dossiê Fronteira
Usa principalmente:
- 14, 15, 17
- com agregações por comando, destinatário, nota, mercadoria e destino.

### 9. Dossiês XML de contribuinte e pessoa física
No eixo fiscal-cadastral, usam principalmente:
- 01, 18, 20, 21, 22.

## E. Por que este desenho é melhor do que repetir relatórios

Porque ele separa o que é:
- **fato fiscal bruto**;
- **dimensão interpretativa**;
- **heurística de auditoria**;
- **camada de apresentação**.

As consultas analisadas na conversa misturavam essas quatro coisas em diferentes
níveis. O MDC isola o que é estrutural. Isso reduz retrabalho, facilita auditoria
e permite regenerar relatórios sem recomeçar do zero.

## F. Limites do núcleo

1. o MDC não substitui as regras derivadas específicas, como score de vínculo,
   PEPS/FIFO, elegibilidade jurídica do ICMS próprio ou “apuração ouro”;
2. o MDC não tenta embutir HTML, subtotais de relatório e textos de UI;
3. no subbloco de dossiê, o núcleo cobre o eixo fiscal/cadastral principal, mas
   não pretende esgotar toda consulta administrativa acessória;
4. para certos ambientes, nomes físicos do SPED no Bloco H podem exigir ajuste,
   embora tenham sido mantidos conforme a convenção observada nas queries de
   mudança de tributação.

## G. Regra prática de uso

A regra recomendada é:

1. materializar o MDC em views ou tabelas temporárias;
2. construir consultas derivadas só com `JOIN` nessas views;
3. deixar heurísticas e regras jurídicas em módulos derivados separados;
4. evitar criar novos relatórios diretamente sobre o dado cru.

## H. Ordem sugerida de materialização

1. `00` a `04`
2. `05` a `11`
3. `12` a `19`
4. `20` a `22`
5. `23` como roteiro de amarração

## I. Resultado esperado

Com esse grupo de consultas, o projeto passa a ter uma **base comum única** para:
- ressarcimento;
- mudança de tributação;
- Fronteira;
- auditoria EFD x documentos;
- relatórios XML EFD/Fronteira;
- núcleo fiscal dos dossiês.

Isso transforma a coleção de SQLs analisadas em uma arquitetura reaproveitável,
rastreável e mais fácil de governar.
