# Análise modular da rotina `Ressarc_fronteira_apos_2022.sql`

## 1. Escopo do material

Este documento aplica à consulta `Ressarc_fronteira_apos_2022.sql` o mesmo método adotado nas duas trilhas anteriores do pacote:

1. decompor a SQL em etapas mínimas auditáveis;
2. separar regra documental, regra cadastral, regra fiscal e heurística analítica;
3. confrontar a lógica da consulta com a disciplina de ressarcimento de ICMS-ST em Rondônia, especialmente:
   - Registro C176;
   - validação do valor unitário de ressarcimento com apoio do Fronteira/SITAFE quando houver antecipação 1231;
   - consolidação da apuração no Bloco E;
   - uso de PEPS ou identificação específica para repartir quantidades entre entradas e saídas;
   - regime pós-2022 em Rondônia, já sob o RICMS/RO aprovado pelo Decreto nº 26.868/2022 e atos complementares.

A consulta original é mais agressiva do que a primeira trilha de ressarcimento. Ela cria um **painel de auditoria 360º** e faz, numa mesma SQL:

- leitura do SPED da saída e da entrada;
- leitura do XML da saída e da entrada;
- leitura direta do XML bruto (`bi.nfe_xml`) por `XMLTABLE` para extrair `vICMSSubstituto`;
- leitura do cálculo de fronteira no SITAFE;
- inferência fiscal por `co_sefin`, MVA e alíquota interna;
- definição de um padrão ouro de apuração unitária em 4 níveis;
- aplicação de memória FIFO/PEPS para limitar a quantidade ressarcível;
- comparação final entre o valor declarado no SPED e o valor apurado.

Essa arquitetura é tecnicamente rica, mas mistura camadas diferentes demais. A modularização proposta abaixo separa essas responsabilidades.

---

## A. Objetivo da consulta

### A.1. Objetivo técnico

A consulta procura responder, por item de saída informado em `C176`:

1. qual foi a saída escriturada no SPED;
2. qual foi a última entrada referenciada no `C176`;
3. quais são os dados documentais da saída e da entrada no XML;
4. qual valor unitário de ICMS próprio e de ICMS-ST pode ser apurado com maior confiança, usando:
   - Fronteira/SITAFE;
   - destaque da NF-e;
   - campos de substituição preenchidos no XML;
   - recálculo estimado por MVA;
5. qual quantidade da entrada pode ser efetivamente aproveitada para sustentar o ressarcimento, respeitando PEPS/FIFO;
6. qual a diferença financeira entre o valor declarado no SPED e o valor apurado pelo “padrão ouro”.

### A.2. Objetivo tributário aparente

O objetivo tributário da SQL é auditar pedidos ou apropriações de ressarcimento de ICMS-ST em Rondônia no cenário pós-2022, quando a rotina fiscal estadual passou a operar em ambiente regulatório consolidado pelo novo RICMS/RO e por atos estaduais específicos para combustíveis e ressarcimento/complemento.

A consulta está claramente focada em cenários em que:

- o contribuinte já escriturou `C176`;
- a entrada que sustenta o crédito pode estar associada a cobrança de fronteira/SITAFE;
- o valor do ST retido ou antecipado pode não estar evidenciado de forma suficiente no documento fiscal de entrada;
- a auditoria precisa optar entre várias fontes de prova do valor unitário do tributo.

Ela também tem um viés operacional importante: a query original assume que o valor do Fronteira é a fonte superior quando disponível e organiza a apuração em níveis de prioridade.

---

## B. Tabelas e fontes utilizadas

### B.1. Tabelas físicas

**SPED**
- `sped.reg_0000`: controle do arquivo válido por período;
- `sped.reg_c100`: capa do documento fiscal;
- `sped.reg_c170`: item do documento;
- `sped.reg_c176`: vínculo da saída com a última entrada;
- `sped.reg_0200`: cadastro do item.

**BI / XML**
- `bi.fato_nfe_detalhe`: dados estruturados item a item das NF-e;
- `bi.nfe_xml`: XML bruto em CLOB para extração direta via `XMLTABLE`.

**SITAFE / SEFIN**
- `sitafe.sitafe_nfe_calculo_item`: cálculo por item da fronteira;
- `sitafe.sitafe_cest_ncm`: relação NCM/CEST para código Sefin;
- `sitafe.sitafe_produto_sefin_aux`: vigência, alíquota interna, indicador de ST, MVA e MVA ajustado.

### B.2. CTEs da consulta original

1. `PARAMETROS`
2. `ARQUIVOS_RANKING`
3. `CHAVES_ENTRADA_FILTRADAS`
4. `XML_EXTRAIDO`
5. `DADOS_BASE`
6. `DADOS_ACUMULADOS`
7. `DADOS_RATEIO`
8. `SELECT FINAL`

A modularização proposta abre esses blocos em mais etapas, para reduzir mistura de regras.

---

## C. Filtros identificados

### C.1. Filtros de escopo temporal e de versão

- `reg_0000.data_entrega <= dt_corte`
- `reg_0000.dt_ini BETWEEN dt_ini_filtro AND dt_fim_filtro`
- `ROW_NUMBER() OVER (PARTITION BY cnpj, dt_ini ORDER BY data_entrega DESC, id DESC)`

**Leitura crítica:** a lógica de escolha da última EFD por período é consistente com a necessidade de trabalhar sempre com a última versão entregue do arquivo.

### C.2. Filtros do universo de entrada

- `CHAVES_ENTRADA_FILTRADAS` limita a extração do XML bruto às chaves realmente usadas no `C176`.

**Leitura crítica:** é um filtro de performance, não um filtro jurídico.

### C.3. Filtros documentais implícitos

- `LEFT JOIN bi.fato_nfe_detalhe ... seq_nitem = num_item`
- `LEFT JOIN bi.nfe_xml ... XMLTABLE('//det')`

**Leitura crítica:** a query pressupõe que o número do item escriturado no SPED é confiável o suficiente para amarrar item a item no XML. Diferentemente da V4 anterior, aqui não existe um score sofisticado de vínculo.

### C.4. Filtros e prioridades de apuração

A consulta cria duas cascatas de prova:

**ST**
1. Fronteira/SITAFE
2. `vICMSST` destacado na NF
3. `vICMSSTRet`
4. recálculo por MVA

**ICMS próprio**
1. Fronteira/SITAFE (na prática, usando o `vICMS` do XML quando há Fronteira)
2. `vICMS` destacado
3. `vICMSSubstituto`
4. zero

**Leitura crítica:** isso é uma regra de auditoria forte, mas não equivale automaticamente a hierarquia legal absoluta. Em alguns casos o documento fiscal, a entrada correspondente ou o regime da operação podem exigir leitura mais restrita.

### C.5. Filtro PEPS/FIFO

- `ORDER BY xml_dhemi_entrada ASC, chave_nfe_ultima_entrada ASC`
- rateio por quantidade acumulada anterior

**Leitura crítica:** a própria query se declara PEPS/FIFO. Isso é aderente à parte do material operacional do projeto que trata “últimas entradas” como PEPS ou identificação específica, mas precisa ser confrontado, caso a caso, com o critério normativo local adotado para o ressarcimento e com a forma como o C176 foi escriturado.

---

## D. Regras de negócio implícitas e explícitas

### D.1. Regras explícitas da query

1. Usar a última EFD do período.
2. Partir apenas de saídas com `C176`.
3. Ler a chave da última entrada do próprio `C176`.
4. Priorizar Fronteira/SITAFE na apuração do ST.
5. Extrair `vICMSSubstituto` diretamente do XML bruto.
6. Recalcular MVA quando o produto estiver marcado como MVA ajustada.
7. Aplicar FIFO/PEPS para limitar a quantidade da entrada aproveitável na saída.
8. Comparar SPED vs XML/SITAFE em base unitária e total.

### D.2. Regras implícitas

1. A query trata o item da entrada como **determinável por `cod_item` + `MAX(num_item)`** na nota de entrada, sem score de desambiguação.
2. O Fronteira/SITAFE é tratado como fonte superior de verdade do ST.
3. O `vICMSSubstituto` é tratado como prova subsidiária do ICMS próprio quando o XML não traz `vICMS`.
4. O cálculo por MVA é uma tentativa de fechar lacunas documentais.
5. A quantidade ressarcível é limitada pela memória acumulada das entradas, e não apenas pela quantidade declarada em `C176`.

### D.3. Regras ausentes, mas juridicamente relevantes

1. elegibilidade jurídica do ICMS próprio por hipótese de `cod_mot_res`;
2. reconciliação explícita com `E111`, `E210` e `E220`;
3. tratamento de conversão de unidade (`0220`);
4. validação robusta do item da entrada quando houver reutilização de `cod_item`;
5. validação de conflito NCM/CEST entre SPED e XML.

---

## E. Atomização da consulta em etapas menores

### E.1. Etapa 1 — EFD válida e parâmetros
**Arquivo:** `40_parametros_e_arquivos_validos_fronteira.sql`

Função:
- receber os parâmetros;
- escolher a última EFD por período;
- expor a janela válida da auditoria.

### E.2. Etapa 2 — chaves de entrada e extração direta do XML
**Arquivo:** `41_chaves_entrada_e_xml_extraido.sql`

Função:
- obter as chaves de entrada realmente usadas no `C176`;
- extrair do XML bruto campos que não estão de forma confiável em `fato_nfe_detalhe`, especialmente `vICMSSubstituto`.

### E.3. Etapa 3 — base documental SPED + XML de saída e entrada
**Arquivo:** `42_base_sped_xml_saida_entrada.sql`

Função:
- unir `C100`, `C170`, `C176`, `0200`, XML da saída e XML da entrada;
- expor a fotografia documental mínima item a item.

### E.4. Etapa 4 — camada fiscal Fronteira + SEFIN + MVA
**Arquivo:** `43_base_fronteira_sefin_mva.sql`

Função:
- integrar `sitafe_nfe_calculo_item`;
- inferir `co_sefin`, ST, alíquota interna e MVA;
- calcular a MVA efetiva quando houver ajuste.

### E.5. Etapa 5 — apuração ouro unitária
**Arquivo:** `44_apuracao_ouro_unitaria.sql`

Função:
- definir o nível de apuração do ST;
- definir o nível de apuração do ICMS próprio;
- calcular o valor unitário apurado de cada um.

### E.6. Etapa 6 — memória PEPS/FIFO
**Arquivo:** `45_memoria_fifo_peps_fronteira.sql`

Função:
- calcular a quantidade acumulada anterior por item de saída;
- preservar a ordem cronológica de consumo das entradas.

### E.7. Etapa 7 — rateio final de quantidade
**Arquivo:** `46_rateio_fronteira.sql`

Função:
- limitar a quantidade de entrada utilizável na saída;
- evitar uso de quantidade acima da saída.

### E.8. Etapa 8 — painel final de auditoria
**Arquivo:** `47_resultado_final_fronteira.sql`

Função:
- publicar a visão consolidada com status, divergências, totalizações e diferença financeira.

### E.9. Etapa 9 — reconciliação com o Bloco E
**Arquivo:** `48_reconciliacao_bloco_e_fronteira.sql`

Função:
- confrontar os valores finais da trilha Fronteira/Apuração Ouro com `E111`, `E210` e `E220`.

---

## F. Comparação com a legislação/documentação tributária

### F.1. Pontos de aderência

1. **Uso do `C176` como centro da prova**
   A disciplina do ressarcimento exige detalhamento item a item da saída, vinculado à entrada que suporta o crédito. A consulta parte corretamente do `C176`.

2. **Busca do valor do Fronteira**
   O material operacional do projeto destaca que, em antecipação 1231, o valor do ST muitas vezes deve ser buscado no extrato do SITAFE, porque a NF do fornecedor não o evidencia adequadamente.

3. **PEPS/FIFO ou identificação específica**
   A query explicita PEPS/FIFO como método de rateio. Isso conversa com a orientação operacional do projeto para desdobramento de quantidades em múltiplas entradas quando a saída consome mais de um lote.

4. **Consolidação posterior no Bloco E**
   Embora a query original não faça isso, a trilha está claramente na mesma família de ressarcimento que exige reflexo na apuração mensal do ICMS.

### F.2. Divergências, insuficiências e extrapolações

1. **Ausência de elegibilidade jurídica do ICMS próprio**
   O valor apurado do ICMS próprio não pode ser automaticamente apropriado só porque foi encontrado no XML ou reconstruído pelo padrão ouro.

2. **Item da entrada pode ser escolhido de forma simplificada demais**
   A subquery de item da entrada usa `MAX(num_item)` por `chv_nfe + cod_item`. Isso é muito menos robusto que a trilha V4 baseada em score.

3. **Cascata de prova não é hierarquia legal absoluta**
   Priorizar Fronteira, depois XML, depois inferência por MVA é uma heurística forte de auditoria, mas não substitui o enquadramento jurídico do caso concreto.

4. **MVA calculada resolve lacuna documental, não comprovação jurídica plena**
   O recálculo do ST por MVA serve como valor de plausibilidade. Ele não equivale, por si só, ao valor juridicamente “devido” ou “ressarcível”.

5. **Ausência de `0220`**
   Se a unidade comercial do XML divergir da unidade escriturada ou da unidade de estoque, o rateio pode distorcer o total.

---

## G. Críticas e riscos

### G.1. Fragilidades técnicas

1. mistura extração documental, inferência fiscal e decisão de auditoria numa mesma CTE extensa;
2. dependência do `num_item` do SPED para localizar o item do XML;
3. escolha simplificada do item da entrada com `MAX(num_item)`;
4. ausência de camada própria de elegibilidade jurídica;
5. ausência de reconciliação nativa com o Bloco E.

### G.2. Fragilidades tributárias

1. risco de tratar valor documental do ICMS próprio como crédito elegível;
2. risco de tratar recálculo por MVA como verdade jurídica superior;
3. risco de aplicar FIFO mesmo quando o caso concreto exigir outra reconstrução;
4. risco de glosa se o valor item a item não conversar com a apuração mensal.

### G.3. Riscos de auditoria

1. falso positivo em item da entrada;
2. falso negativo quando `fato_nfe_detalhe` e `nfe_xml` divergem;
3. distorção por unidade de medida;
4. diferença financeira relevante gerada por hierarquia de apuração não validada juridicamente.

---

## H. Melhorias recomendadas

1. separar a busca do item da entrada da busca do valor unitário do tributo;
2. reaproveitar, quando necessário, a lógica de score da trilha V4 para identificar o item correto da entrada;
3. adicionar camada explícita de elegibilidade do ICMS próprio, por `cod_mot_res` e hipótese legal;
4. adicionar reconciliação obrigatória com `E111`, `E210` e `E220`;
5. incluir fator de conversão de unidade;
6. marcar no resultado final qual parcela do valor é:
   - documental;
   - SITAFE;
   - inferida;
   - juridicamente elegível.

---

## I. Versão reestruturada da lógica SQL

A terceira trilha passa a ser organizada assim:

- `40` → versão válida da EFD;
- `41` → chaves de entrada e extração direta do XML;
- `42` → base documental SPED + XML;
- `43` → enriquecimento fiscal com Fronteira e SEFIN;
- `44` → padrão ouro de apuração unitária;
- `45` → memória FIFO/PEPS;
- `46` → rateio final da quantidade;
- `47` → resultado final de auditoria;
- `48` → reconciliação com o Bloco E;
- `49` → preservação da query original;
- `50` → orquestração integrada das três abordagens.

---

## 2. Diferença desta trilha para as anteriores

### Em relação à trilha V4 de ressarcimento
A V4 anterior é melhor para reconstruir **qual item da entrada** corresponde ao item da saída.  
A trilha pós-2022 com Fronteira é melhor para reconstruir **qual valor unitário do tributo** parece mais confiável entre SPED, XML, SITAFE e inferência por MVA.

### Em relação à trilha de mudança de tributação
A trilha de mudança de tributação é centrada em estoque e inventário.  
A trilha pós-2022 com Fronteira é centrada em saída com `C176`, entrada vinculada e apuração unitária do tributo.

O ganho do pacote unificado é justamente permitir que o projeto trate as três perguntas separadamente:
1. qual saída gera o direito;
2. qual entrada e qual item sustentam esse direito;
3. qual valor unitário e qual quantidade podem ser juridicamente aproveitados.
