# Análise modular da rotina `Ressar_front_calc_ate_2022.sql`

## 1. Escopo do material

Este documento aplica à consulta `Ressar_front_calc_ate_2022.sql` o mesmo método usado nas trilhas anteriores do pacote, mas com uma diferença decisiva: aqui a lógica foi construída para um **cenário anterior à consolidação da validação item a item do Fronteira a partir de janeiro/2022**.

A própria base documental do projeto destaca que, nas mercadorias sujeitas à antecipação com encerramento de fase (receita 1231), **a partir de janeiro/2022** passou a existir possibilidade de validar o valor informado no campo 17 do `C176` com apoio do Fronteira item a item, pelas tabelas `sitafe.sitafe_nfe_item` e `sitafe.sitafe_nfe_calculo_item`. Antes disso, a auditoria precisava reconstruir o valor com mais inferência, combinando XML, cadastro fiscal, produto Sefin e até rateio de frete/ICMS do frete. Por isso esta quarta trilha é historicamente diferente da abordagem pós-2022. ([Ressarcimento_apresentacao.pdf](sql/69_query_original_ressarc_front_calc_ate_2022_referencia.sql) - referência lógica do pacote; base normativa/documental do projeto: LC 87/96, Convênio ICMS 142/2018, RICMS/RO Anexo VI, IN 22/2018, material institucional do Núcleo ST.)

A consulta original não é uma rotina de apuração mensal completa. Ela é uma **rotina pericial por chave**, desenhada para “bater” uma nota ou um conjunto pequeno de chaves e reconstruir um valor de ST item a item, inclusive quando:

- o valor unitário do ST não está individualizado na NF-e de entrada;
- o Fronteira ainda não oferece, de forma madura, o cálculo item a item que a trilha pós-2022 já consegue ler diretamente;
- é necessário distribuir frete e ICMS do frete do CTe entre notas e itens para recompor a base econômica do cálculo;
- o produto Sefin e a classificação fiscal vigente precisam ser recuperados a partir do `sitafe_nfe_item` e da tabela auxiliar de classificação.

Em resumo: esta SQL não é apenas “mais uma consulta de ressarcimento”. Ela é a trilha de **reconstrução analítica do ST anterior a 2022**, fortemente dependente de heurística operacional.

---

## A. Objetivo da consulta

### A.1. Objetivo técnico

A consulta procura responder, para uma ou mais chaves de NF-e de entrada selecionadas manualmente:

1. qual é o item fiscal/documental da nota;
2. qual o produto Sefin vigente e os parâmetros fiscais associados;
3. qual o crédito presumido ou ICMS próprio calculado da operação;
4. qual frete e qual ICMS do frete devem ser rateados ao item, a partir do CTe vinculado;
5. qual o valor de ST reconstruído para o item, distinguindo emitente do Simples e regime normal, base simples e base dupla, MVA ajustada ou não;
6. quais são os valores documentais existentes no XML (`vICMS`, `vICMSST`, `vICMSSubstituto`, `vICMSSTRet`) e como eles se comparam ao cálculo refeito.

### A.2. Objetivo tributário aparente

O objetivo tributário é auditar ressarcimento ou validação de ICMS-ST em Rondônia em mercadorias submetidas à antecipação com encerramento de fase, especialmente em contexto anterior à melhora da granularidade do Fronteira pós-2022. O fundamento material permanece o mesmo da trilha de ressarcimento:

- art. 10 da LC 87/1996: restituição do imposto pago por substituição tributária quando o fato gerador presumido não se realizar;
- cláusula décima quinta do Convênio ICMS 142/2018: possibilidade de ressarcimento segundo a disciplina da UF do contribuinte;
- arts. 20 a 24 do Anexo VI do RICMS/RO: hipóteses e modalidades de ressarcimento;
- IN 22/2018: disciplina da escrituração em `C170/C176`, critério da entrada correspondente e, subsidiariamente, das entradas mais recentes suficientes.

A grande particularidade desta query é que ela tenta reconstruir, por engenharia reversa, o valor unitário do tributo quando a documentação de entrada ou o extrato do Fronteira ainda não oferecem o detalhe item a item da forma como ocorre no cenário posterior.

---

## B. Tabelas e fontes utilizadas

### B.1. Tabelas físicas

**BI / XML**
- `bi.fato_nfe_detalhe`: base estruturada item a item das NF-e.
- `bi.nfe_xml`: XML bruto em CLOB, lido com `XMLTABLE` para extrair `vICMSSubstituto` e `vICMSSTRet`.

**SITAFE / SEFIN**
- `sitafe.sitafe_produto_sefin_aux`: classificação fiscal e parâmetros de ST/MVA por vigência.
- `sitafe.sitafe_nfe_item`: item fiscal do Fronteira, usado aqui como base principal do cálculo pré-2022.
- `sitafe.sitafe_cte_itens`: vínculo entre CTe e NF-e para rateio de frete.
- `sitafe.sitafe_cte`: total do frete e ICMS do frete do CTe.

**Tabelas auxiliares do ambiente**
- `qvw.tbl_aliq_ufs`: alíquota interestadual por UF, usada na CTE `CREDITO_CALCULADO`.

### B.2. CTEs da consulta original

1. `TAB_AUX_CLASSIFICACAO`
2. `chaves`
3. `portalfiscal`
4. `CREDITO_CALCULADO`
5. `RATEIO_FRETE_ETAPA_A`
6. `RATEIO_FRETE_ETAPA_B`
7. `RATEIO_FRETE_ETAPA_C`
8. `SELECT FINAL`

Ao contrário das trilhas anteriores, esta SQL não nasce do `C176`. Ela nasce de uma lista de chaves-alvo e tenta reconstituir o cálculo do ST diretamente na nota de entrada.

---

## C. Filtros identificados

### C.1. Filtro principal por chave

A query trabalha com um conjunto manual de chaves de NF-e, definido na CTE `chaves`. Este é o primeiro ponto crítico: trata-se de uma rotina de perícia dirigida, e não de uma auditoria massiva por período/CNPJ.

### C.2. Filtro documental do XML

A CTE `chaves` usa `bi.fato_nfe_detalhe` com `seq_nitem = 1` apenas para localizar/documentar as chaves-alvo. Já a CTE `portalfiscal` abre o XML bruto dessas chaves para todos os itens via `XMLTABLE('//det')`.

### C.3. Filtro de vigência fiscal

`TAB_AUX_CLASSIFICACAO` converte `IT_DA_INICIO` e `IT_DA_FINAL` em datas e depois o `JOIN` final exige que `DHEMI` da NF esteja dentro da vigência. Isso é correto do ponto de vista fiscal: MVA, alíquota interna, indicador de ST e demais flags têm natureza temporal.

### C.4. Filtro do rateio de frete

No rateio, a query exige:

- `IT_NU_CHAVE_CTE` presente no conjunto de CTe vinculado às chaves analisadas;
- `nfe.seq_nitem = 1` para compor a base total da nota;
- identidade entre a raiz do CNPJ do tomador do frete e a raiz do CNPJ destinatário da NF.

Esse último filtro é operacional, não normativo. Ele tenta evitar que o rateio use notas de terceiros ou relações documentais estranhas ao mesmo contribuinte econômico.

---

## D. Regras de negócio implícitas e explícitas

### D.1. Regras explícitas da query

1. Ler o XML bruto para recuperar campos que não são confiáveis ou não estão estruturados no BI.
2. Calcular um `CRED_CALC` (crédito calculado) por item.
3. Localizar o CTe vinculado à nota e repartir frete/ICMS-frete entre as notas e depois entre os itens.
4. Escolher a fórmula de `CALC_ST` conforme:
   - mercadoria sujeita ou não a ST;
   - emitente do Simples (`CO_CRT IN ('1','4')`) ou regime normal;
   - existência de MVA ajustada.
5. Expor, lado a lado, os valores documentais do XML e o cálculo refeito.

### D.2. Regras implícitas

1. O cálculo pré-2022 depende mais de reconstrução do que de prova direta.
2. `sitafe_nfe_item` é tratado como fonte estrutural da mercadoria e do cálculo, mas não como valor final já pronto do ressarcimento.
3. O frete e o ICMS do frete entram na recomposição econômica da operação.
4. O cálculo do ICMS próprio é aproximado por uma regra operacional de alíquota por UF/origem, e não por uma captura direta universal do valor jurídico apropriável.

### D.3. Regra crítica de transição histórica

O material institucional do projeto é claro: **a partir de janeiro/2022** já existe a possibilidade de validar o campo 17 do `C176` porque o Fronteira passou a registrar cálculo item a item. Isso significa que a presente query representa uma solução mais antiga, necessária quando esse detalhe ainda não estava disponível ou não era suficiente. Logo, ela é adequada para auditoria histórica, mas não deve substituir automaticamente a trilha pós-2022 quando o dado itemizado já existir.

---

## E. Atomização da consulta em etapas menores

### E.1. Etapa 1 — parâmetros, chaves e classificação fiscal
**Arquivo:** `sql/60_parametros_chaves_classificacao_fronteira_ate_2022.sql`

Função:
- transformar a lista de chaves em base auditável;
- abrir a vigência da classificação fiscal do produto Sefin.

### E.2. Etapa 2 — extração do XML bruto
**Arquivo:** `sql/61_xml_portalfiscal_extraido_ate_2022.sql`

Função:
- extrair `vICMSSubstituto`, `vICMSSTRet` e o `cProd` documental item a item.

### E.3. Etapa 3 — crédito calculado operacional
**Arquivo:** `sql/62_credito_calculado_operacional.sql`

Função:
- reproduzir a lógica do `CREDITO_CALCULADO` da consulta original.
- Este módulo deve ser tratado como **regra operacional do projeto**, e não como transcrição literal da legislação.

### E.4. Etapa 4 — vínculo do CTe e rateio por nota
**Arquivo:** `sql/63_rateio_frete_cte_notas.sql`

Função:
- localizar CTe vinculado às NF-e analisadas;
- repartir frete total e ICMS do frete entre as notas do conjunto.

### E.5. Etapa 5 — rateio do frete por item
**Arquivo:** `sql/64_rateio_frete_cte_itens.sql`

Função:
- distribuir o frete rateado da nota para cada item.

### E.6. Etapa 6 — base documental e fiscal pré-2022
**Arquivo:** `sql/65_base_documental_fronteira_ate_2022.sql`

Função:
- integrar XML estruturado, XML extraído, `sitafe_nfe_item`, classificação fiscal e rateio de frete.

### E.7. Etapa 7 — cálculo refeito do ST
**Arquivo:** `sql/66_calculo_st_pre_2022.sql`

Função:
- aplicar as fórmulas de ST por regime e tipo de base.

### E.8. Etapa 8 — resultado final de auditoria
**Arquivo:** `sql/67_resultado_final_fronteira_ate_2022.sql`

Função:
- expor os valores documentais e o `CALC_ST` refeito em painel item a item.

### E.9. Etapa 9 — reconciliação com Bloco E (opcional)
**Arquivo:** `sql/68_reconciliacao_bloco_e_fronteira_ate_2022.sql`

Função:
- agregar a trilha pré-2022 ao nível mensal e confrontar com `E111`, `E210` e `E220` quando a chave analisada fizer parte de uma apuração efetivamente escriturada.

### E.10. Referência da query original
**Arquivo:** `sql/69_query_original_ressarc_front_calc_ate_2022_referencia.sql`

---

## F. Comparação com a legislação/documentação tributária

### F.1. Onde a query está aderente

1. **Direito material ao ressarcimento**: a consulta trabalha dentro do universo de restituição/ressarcimento de ST previsto na LC 87/1996, no Convênio 142/2018 e no RICMS/RO.
2. **Relevância do documento de entrada e do valor efetivamente retido/antecipado**: a IN 22/2018 manda usar a entrada correspondente ou, se impossível, as entradas mais recentes suficientes.
3. **Importância do Fronteira em receita 1231**: o material institucional destaca que, nas mercadorias sujeitas à antecipação com encerramento de fase, o valor do ST não fica individualizado na nota e precisa ser buscado no ambiente estadual.

### F.2. Onde a query extrapola a norma e entra em heurística

1. **Lista manual de chaves**: não é regra legal, é técnica pericial.
2. **Cálculo de crédito por alíquota de UF**: é atalho operacional do projeto.
3. **Rateio de frete e ICMS do frete**: a recomposição faz sentido econômico, mas não aparece dessa forma literal na IN 22/2018.
4. **Fórmulas de base simples/base dupla**: refletem racionalidade fiscal e engenharia do tributo, mas ainda são reconstrução analítica, não “valor jurídico pronto” fornecido pelo leiaute do C176.

### F.3. Diferença histórica em relação à trilha pós-2022

A trilha pós-2022 consegue usar `sitafe_nfe_calculo_item` como evidência superior do valor itemizado do ST. A trilha pré-2022 não tem essa vantagem e, por isso, depende mais de `sitafe_nfe_item`, XML bruto e rateio de frete. Em termos de auditoria, isso significa **mais risco de divergência e mais necessidade de revisão humana**.

---

## G. Críticas e riscos

### G.1. Fragilidades técnicas

1. hardcode de chaves na própria SQL;
2. dependência de `ALTER SESSION` para leitura do XML;
3. ausência de parametrização do rateio de frete;
4. uso de `over()` sem partição explícita no rateio por conjunto, o que exige extremo cuidado quando mais de um CTe estiver presente;
5. fórmula densa e de difícil manutenção em `CALC_ST`.

### G.2. Fragilidades tributárias

1. a query não nasce do `C176`, então não prova sozinha que a apropriação foi escriturada corretamente;
2. não há elegibilidade jurídica explícita do ICMS próprio por hipótese de `cod_mot_res`;
3. não trata conversão de unidade;
4. não distingue claramente o que é valor documental e o que é valor refeito;
5. depende de premissas operacionais sobre frete que podem não coincidir com a metodologia oficialmente aceita pela fiscalização em todos os casos.

### G.3. Risco central

O maior risco desta rotina é ser usada como “valor definitivo” quando, na verdade, ela é mais apropriada como **cálculo pericial de apoio** para nota histórica, especialmente em ambiente anterior à disponibilidade do detalhamento itemizado do Fronteira pós-2022.

---

## H. Melhorias recomendadas

1. substituir a lista hardcoded de chaves por tabela de staging ou parâmetro externo;
2. separar o rateio do frete em módulo reutilizável para todas as rotinas históricas;
3. parametrizar a fórmula de crédito calculado;
4. identificar explicitamente a natureza do item como:
   - valor documental do XML;
   - valor do SITAFE;
   - valor reconstruído;
5. integrar a trilha pré-2022 à matriz de elegibilidade do ICMS próprio do módulo 14;
6. sempre que houver dado itemizado pós-2022 disponível, priorizar a trilha 3 do pacote.

---

## I. Versão reestruturada da lógica SQL, quando aplicável

A melhor forma de usar esta consulta não é mantê-la monolítica. É operar em quatro camadas:

1. **camada documental**: chave, XML estruturado, XML bruto, item do Fronteira;
2. **camada econômica**: crédito calculado, frete rateado, ICMS do frete rateado;
3. **camada fiscal**: produto Sefin, ST, MVA, regime do emitente, base simples/dupla;
4. **camada pericial**: `CALC_ST`, comparação com XML e eventual reconciliação com Bloco E.

---

## 2. Explicação detalhada de cada novo arquivo SQL

### `sql/60_parametros_chaves_classificacao_fronteira_ate_2022.sql`

**Objetivo**
- Preparar a lista de chaves-alvo e a tabela auxiliar de classificação fiscal vigente.

**Entradas**
- tabela ou CTE de chaves-alvo;
- `sitafe.sitafe_produto_sefin_aux`.

**Saídas**
- uma base com chaves documentais e a vigência/classificação pronta para o restante do pipeline.

**Base legal aplicável**
- Não cria direito material novo. É uma etapa preparatória.
- A relevância da vigência vem do fato de que MVA, ST e alíquota interna são atributos temporais da mercadoria no regime de ST.

**Risco**
- se a chave estiver errada, todo o cálculo posterior fica comprometido.

### `sql/61_xml_portalfiscal_extraido_ate_2022.sql`

**Objetivo**
- Abrir o XML bruto e extrair campos que o BI estruturado nem sempre expõe bem, como `vICMSSubstituto` e `vICMSSTRet`.

**Base legal aplicável**
- O XML é prova documental primária da operação.
- Na disciplina do ressarcimento, a entrada correspondente e os valores que sustentam o tributo precisam ser identificáveis documentalmente.

**Risco**
- sensível a namespace, formato numérico e integridade do XML armazenado.

### `sql/62_credito_calculado_operacional.sql`

**Objetivo**
- Reproduzir a regra operacional do projeto para estimar o crédito do ICMS próprio.

**Base legal aplicável**
- Há aderência indireta ao conceito de crédito da operação própria “quando for o caso”, mas a fórmula não é a reprodução literal da IN 22/2018.

**Risco**
- deve ser tratado como estimativa operacional e validado caso a caso.

### `sql/63_rateio_frete_cte_notas.sql`

**Objetivo**
- Encontrar CTe e distribuir o frete total/ICMS-frete entre as NF-e relacionadas.

**Base legal aplicável**
- Não há comando literal na IN 22/2018 mandando esse rateio dessa forma; trata-se de metodologia analítica para reconstituir a base econômica do item.

**Risco**
- critérios de rateio podem ser discutíveis em fiscalização.

### `sql/64_rateio_frete_cte_itens.sql`

**Objetivo**
- Espalhar o frete já repartido da nota pelos itens da NF-e.

**Base legal aplicável**
- Complementar à etapa anterior; é técnica de custeio/rateio, não dispositivo normativo expresso.

### `sql/65_base_documental_fronteira_ate_2022.sql`

**Objetivo**
- Unificar XML estruturado, XML extraído, item SITAFE, classificação e rateio.

**Base legal aplicável**
- Serve à reconstrução da “entrada correspondente” exigida pela IN 22/2018.

### `sql/66_calculo_st_pre_2022.sql`

**Objetivo**
- Aplicar a fórmula de ST conforme regime do emitente e parâmetros fiscais vigentes.

**Base legal aplicável**
- Inspira-se na engenharia do ICMS-ST (base presumida, MVA, alíquota interna, crédito da operação própria), mas ainda é cálculo reconstruído.

**Risco**
- é o coração heurístico da trilha; exige validação humana.

### `sql/67_resultado_final_fronteira_ate_2022.sql`

**Objetivo**
- Entregar o painel final por item, com campos do XML e valor refeito.

**Base legal aplicável**
- útil para auditoria, mas não substitui a escrituração em `C176/E111/E210/E220`.

### `sql/68_reconciliacao_bloco_e_fronteira_ate_2022.sql`

**Objetivo**
- Agregar o resultado por período e confrontar com o Bloco E, quando aplicável.

**Base legal aplicável**
- No material institucional, o valor mensal do ressarcimento deve ser levado aos ajustes estaduais (`RO020022`, `RO020023` e correlatos, conforme cenário e vigência).

### `sql/69_query_original_ressarc_front_calc_ate_2022_referencia.sql`

**Objetivo**
- Preservar a consulta original como evidência histórica do ponto de partida.

---

## 3. Conclusão executiva

A rotina `Ressar_front_calc_ate_2022.sql` é a trilha histórica de reconstrução do ST em ambiente anterior à maturidade do Fronteira item a item. Ela é valiosa justamente porque explicita o que, naquele cenário, precisava ser inferido: crédito calculado, rateio de frete, base econômica do item e cálculo do ST por fórmula.

Mas o uso correto dessa trilha é **pericial e comparativo**, não automático. Sempre que houver dado itemizado do Fronteira disponível no período auditado, a abordagem pós-2022 do pacote deve ser preferida. Quando não houver, esta quarta trilha oferece a melhor forma de reconstrução auditável da lógica econômica e fiscal da operação.
