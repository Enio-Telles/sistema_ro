# Consultas básicas compartilhadas entre as seis abordagens

## 1. Objetivo

Este documento reúne as consultas-base que servem às seis trilhas do pacote:

1. **ressarcimento de ICMS-ST por saída com C176 e reconstrução robusta do item da entrada**;
2. **mudança de tributação com inventário no Bloco H**;
3. **ressarcimento pós-2022 com Fronteira, extração direta do XML e apuração ouro unitária**;
4. **ressarcimento / reconstrução histórica do ST do Fronteira até 2022, com rateio de frete e cálculo pericial por item**;
5. **auditoria EFD x documentos eletrônicos (55, 65 e 57) por período**;
6. **conciliação completa NFe x SITAFE / Fronteira**.

A ideia é manter uma camada comum de prova documental, saneamento e parâmetros.

## 2. Núcleo comum

### 2.1. Seleção da EFD válida
As trilhas que dependem da escrituração fiscal precisam identificar qual arquivo EFD vale para cada período.

### 2.2. Normalização do `cod_item`
As trilhas com comparação entre entradas, saídas e inventário dependem de reduzir ruído cadastral.

### 2.3. Cadastro `0200`
As trilhas de ressarcimento e mudança de tributação precisam da identificação cadastral do item.

### 2.4. Itens de documentos (`C100/C170`)
As trilhas baseadas em EFD precisam abrir documentos item a item.

### 2.5. Base XML / BI
O XML é prova complementar ou principal em várias rotinas.

### 2.6. Inventário do Bloco H
A abordagem 2 depende diretamente do Bloco H. As demais podem usá-lo como validação.

### 2.7. Bloco E
As trilhas que chegam a crédito/débito ou reconciliação de apuração precisam olhar o Bloco E.

### 2.8. Fronteira / SITAFE
As abordagens 1, 3, 4 e 6 dependem de uma camada comum para o SITAFE/Fronteira.

### 2.9. Produto Sefin, MVA e vigência
As trilhas de Fronteira e de inferência fiscal precisam traduzir NCM/CEST em regra estadual aplicável.

## 3. Arquivos SQL compartilhados

### `sql_basicas/00_base_parametros_arquivos_efd.sql`
Camada única de parâmetros e ranking do `reg_0000`.

### `sql_basicas/01_base_normalizacao_cod_item.sql`
Template de normalização de `cod_item` e chaves auxiliares.

### `sql_basicas/02_base_produtos_0200.sql`
Base cadastral padronizada de produtos.

### `sql_basicas/03_base_documentos_c100_c170.sql`
Abertura documental mínima dos itens de entradas e saídas.

### `sql_basicas/04_base_xml_nfe_itens.sql`
Base XML/BI item a item.

### `sql_basicas/05_base_inventario_h005_h010_h020.sql`
Camada mínima do Bloco H.

### `sql_basicas/06_base_ajustes_bloco_e.sql`
Camada mínima de `E111`, `E210` e `E220`.

### `sql_basicas/07_base_xml_extraido_nfe.sql`
Extração direta de campos do XML bruto via `XMLTABLE`.

### `sql_basicas/08_base_sitafe_fronteira.sql`
Base comum do cálculo item a item do Fronteira/SITAFE.

### `sql_basicas/09_base_produto_sefin_vigencia.sql`
Base comum para tradução NCM/CEST -> código Sefin + parâmetros de ST/MVA por vigência.

### `sql_basicas/10_base_sitafe_nfe_item_pre_2022.sql`
Base do item fiscal do SITAFE para trilhas históricas anteriores à granularidade pós-2022.

### `sql_basicas/11_base_cte_rateio_frete.sql`
Template compartilhado para localizar CTe e repartir frete / ICMS-frete entre notas e itens.

### `sql_basicas/12_base_cte_tomador_efetivo.sql`
Base compartilhada para resolver o tomador efetivo do CT-e.

### `sql_basicas/13_base_documentos_bi_por_chave.sql`
Consolidado mínimo dos documentos eletrônicos do BI/XML por chave de acesso.

### `sql_basicas/14_base_efd_documentos_por_chave.sql`
Consolidado mínimo da EFD por chave de acesso.

### `sql_basicas/15_base_eventos_manifestacao.sql`
Base compartilhada dos eventos de manifestação do destinatário.

### `sql_basicas/16_base_sitafe_fronteira_lancamentos.sql`
Base compartilhada de nota, lançamento, guia, receita, valor devido, valor pago e situação no SITAFE.

### `sql_basicas/17_base_sitafe_mercadoria_produto.sql`
Base compartilhada de item fiscal, item do lançamento, mercadoria/classificação estadual e produto Sefin.

## 4. Como cada abordagem consome a camada compartilhada

### 4.1. Abordagem 1 — ressarcimento com C176 e score de vínculo
Usa principalmente `00`, `01`, `02`, `03`, `04`, `06`, `08` e `09`.

### 4.2. Abordagem 2 — mudança de tributação com inventário
Usa principalmente `00`, `01`, `02`, `03`, `04`, `05`, `06` e `09`.

### 4.3. Abordagem 3 — Fronteira pós-2022 com apuração ouro
Usa principalmente `00`, `02`, `03`, `04`, `06`, `07`, `08` e `09`.

### 4.4. Abordagem 4 — Fronteira até 2022 com cálculo reconstruído
Usa principalmente `04`, `07`, `10` e `11`, além da classificação fiscal e do XML estruturado.

### 4.5. Abordagem 5 — auditoria EFD x documentos eletrônicos
Usa principalmente `12`, `13`, `14` e `15`, além de `00` e de filtros por período e papel do contribuinte.

### 4.6. Abordagem 6 — conciliação completa NFe x SITAFE / Fronteira
Usa principalmente `13`, `16` e `17`, podendo ser combinada com `08` e `09` quando houver necessidade de aprofundar cálculo fiscal estadual.

## 5. Benefício de unir as consultas básicas

Unir as consultas básicas traz consistência, manutenção mais simples, melhor auditoria e governança.

## 6. Limite importante

A camada compartilhada não substitui a regra tributária específica. Ela apenas prepara a prova documental mínima.
