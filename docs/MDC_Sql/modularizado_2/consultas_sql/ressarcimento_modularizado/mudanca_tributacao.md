# Análise modular da rotina de mudança de tributação em ICMS-ST

## 1. Escopo do material

Este documento aplica à consulta `analise_mudanca_trib_st_v2.sql` o mesmo método usado no pacote de ressarcimento: decompor a SQL em etapas mínimas auditáveis, separar regras técnicas de regras tributárias e destacar o que é prova documental, o que é heurística de auditoria e o que ainda depende de enquadramento jurídico externo.

A consulta original não calcula integralmente o crédito ou débito de mudança de tributação. Ela faz algo mais específico: parte do inventário do Bloco H, identifica a última entrada do item antes da data de inventário e compara o valor unitário do inventário com o valor unitário da última compra. Isso é útil como trilha de auditoria, mas não basta, por si só, para suportar todo o tratamento jurídico de saída da ST para o regime normal ou de entrada no regime de ST.

---

## A. Objetivo da consulta

### A.1. Objetivo técnico

A consulta procura responder, para cada item em inventário:

1. qual foi a fotografia do estoque no Bloco H (`H005`, `H010` e eventualmente `H020`);
2. qual foi a última entrada escriturada do item antes da data do inventário;
3. qual o valor unitário dessa última entrada;
4. qual a diferença entre o valor unitário de inventário e o valor unitário da última compra.

### A.2. Objetivo tributário aparente

O objetivo tributário implícito é auditar cenários de **mudança de tributação** de mercadorias sujeitas à ST, especialmente situações em que:

- a mercadoria sai da ST para o regime normal e o contribuinte pretende se creditar do imposto vinculado ao estoque remanescente;
- a mercadoria entra na ST e o contribuinte precisa medir o estoque afetado para futura apuração do débito.

A documentação operacional usada neste projeto indica exatamente essa lógica: em mudança de tributação, o contribuinte deve levantar o estoque no Bloco H; quando a mercadoria sai da ST para o regime normal, o `H005` deve usar motivo `02`, o `H020` deve demonstrar o imposto a ser creditado por item e o efeito financeiro deve ser levado ao `E111`; quando a mercadoria entra na ST, a apuração tende a repercutir em `E210/E220`. Logo, a consulta está na trilha correta do problema, mas ainda não resolve toda a obrigação acessória e nem toda a apuração.

---

## B. Tabelas e fontes utilizadas

### B.1. Tabelas físicas

**SPED**
- `sped.reg_0000`: define qual arquivo EFD será considerado.
- `sped.reg_h005`: identifica a data e o motivo do inventário.
- `sped.reg_h010`: detalha o item em estoque.
- `sped.reg_h020`: traz o complemento tributário do inventário em casos específicos, inclusive mudança de tributação.
- `sped.reg_0200`: apoia a identificação cadastral do item.
- `sped.reg_c100`: cabeçalho da nota fiscal de entrada.
- `sped.reg_c170`: item da nota fiscal de entrada.

**BI / XML**
- `bi.fato_nfe_detalhe`: usada apenas para enriquecer a nota com `NSU`, `UF do emitente` e `UF do destinatário`.

### B.2. CTEs da consulta original

1. `PARAMETROS`
   - recebe CNPJ, intervalo, item opcional, data-limite de processamento e data específica de inventário.

2. `ARQUIVOS_RANKING`
   - ranqueia os arquivos `reg_0000` para escolher a última versão entregue por período.

3. `estoque`
   - monta a base do inventário a partir de `H005 + H010 + H020 + 0200`.

4. `NSU`
   - obtém `NSU`, chave e UFs no BI.

5. `ENTRADAS`
   - monta a base de compras a partir de `C100 + C170`.

6. `RANKING_ENTRADAS`
   - para cada item e data de inventário, identifica a última entrada anterior à data do inventário.

7. `SELECT FINAL`
   - expõe estoque, última compra, dados de `H020` e diferença entre valor unitário do inventário e valor unitário da última compra.

---

## C. Filtros identificados

### C.1. Filtros no módulo de parâmetros

- `:CNPJ` restringe a análise ao estabelecimento.
- `:data_inicial` e `:data_final` delimitam a janela, mas a consulta adiciona **dois meses** ao `data_final`.
- `:cod_item` é opcional e passa por normalização.
- `:data_limite_processamento` impede usar arquivos entregues após a data de corte.
- `:data_inventario` permite focar uma fotografia específica do estoque.

### C.2. Filtros de arquivos EFD

- `r.data_entrega <= p.dt_corte`
- `r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro`
- `ROW_NUMBER() OVER (PARTITION BY r.cnpj, r.dt_ini ORDER BY r.data_entrega DESC)`

**Efeito**: a consulta sempre escolhe a última EFD entregue para cada `dt_ini` dentro da janela.

**Crítica**: a partição usa `cnpj, dt_ini`, mas não considera `dt_fin` nem desempate por `id`. Isso pode ser suficiente na prática, mas é menos robusto do que a abordagem usada na rotina de ressarcimento.

### C.3. Filtros da base de estoque

- `arq.rn = 1`
- filtro opcional por item normalizado
- filtro opcional por data exata do inventário

**Ponto crítico**: a consulta **não exige** `h005.mot_inv = '02'`. Para auditoria de mudança de tributação, isso é uma lacuna importante, porque o próprio material operacional do projeto associa a mudança de forma de tributação ao motivo `02` no `H005`.

### C.4. Filtros da base documental do BI

- `(co_emitente = p.cnpj_filtro OR co_destinatario = p.cnpj_filtro)`
- `dhemi BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro`
- `INFPROT_CSTAT IN ('100','150')`
- `SEQ_NITEM = 1`

**Efeito**: busca apenas documentos autorizados/regularizados, mas usa somente o primeiro item do XML para obter `NSU` e UFs.

**Crítica**: para `NSU` e UFs essa heurística tende a funcionar, mas continua sendo um atalho técnico. Não é prova item a item.

### C.5. Filtros da base de entradas

- `substr(c170.cfop, 1, 1) IN ('1','2','3')`
- `c100.ind_oper = '0'`
- `c100.cod_sit = '00'`
- filtro opcional por item normalizado

**Efeito**: captura entradas regulares de mercadorias.

**Críticas**:
- não distingue compra com ST de compra sem ST;
- não trata extemporaneidade (`cod_sit` 01/03/07 etc.);
- não valida CST/CSOSN/C190 para saber se havia imposto próprio, ST retida ou antecipação.

### C.6. Filtro de temporalidade da última entrada

- `ent.dt_doc <= est.dt_inv`

**Efeito**: a “última compra” é sempre anterior ou igual à data do inventário.

**Regra implícita**: a última compra é tratada como melhor proxy para valorar o estoque.

**Crítica jurídica**: essa proxy pode ser útil para auditoria, mas não decorre automaticamente da norma aplicável a `H020`. Em vários casos, o cálculo do valor a creditar ou debitar depende do imposto efetivamente suportado no estoque, e não apenas do preço unitário da última compra.

---

## D. Regras de negócio implícitas e explícitas

### D.1. Regras explícitas

1. Usar a última EFD entregue para cada período.
2. Buscar inventário no Bloco H.
3. Comparar inventário com a última entrada do item.
4. Usar item normalizado para relacionar estoque e compras.
5. Expor `H020` quando existir.

### D.2. Regras implícitas

1. **Valor unitário da última compra** funciona como referência para o inventário.
2. **Mudança de tributação** é tratada mais como problema de estoque e valoração do que como problema completo de apuração tributária.
3. **UF emitente/destinatário** são elementos auxiliares para rastrear a origem da compra.
4. A consulta assume que o código do item, depois de “limpo”, é estável o suficiente para vincular estoque e entradas.

### D.3. Regras ausentes, mas juridicamente relevantes

1. filtro por `mot_inv = 02`;
2. identificação do evento jurídico de entrada na ST ou saída da ST;
3. cálculo do crédito/débito do imposto;
4. reconciliação com `E111`, `E210` ou `E220`;
5. validação de NCM/CEST/0220 em mudança de tributação.

---

## E. Atomização da consulta em etapas menores

A seguir está a decomposição recomendada para a nova trilha modular.

### E.1. Etapa 1 — selecionar a EFD válida
**Arquivo**: `20_parametros_e_arquivos_validos_mudanca.sql`

Função: isolar parâmetros, data de corte e o último arquivo por período.

### E.2. Etapa 2 — abrir o inventário do Bloco H
**Arquivo**: `21_estoque_bloco_h.sql`

Função: materializar `H005 + H010 + H020 + 0200`, com filtros claros por item, data e motivo do inventário.

### E.3. Etapa 3 — abrir a trilha documental das entradas
**Arquivos**:
- `22_nsu_documental.sql`
- `23_entradas_sped.sql`

Função: separar a base fiscal (`C100/C170`) do enriquecimento documental (`NSU/UFs`).

### E.4. Etapa 4 — identificar a última entrada antes do inventário
**Arquivo**: `24_ranking_ultima_entrada_inventario.sql`

Função: escolher o documento de entrada usado como referência de rastreabilidade.

### E.5. Etapa 5 — formar a base comparativa
**Arquivo**: `25_base_mudanca_tributacao.sql`

Função: unir estoque, `H020`, última entrada e diferença de valor unitário.

### E.6. Etapa 6 — qualificar juridicamente a mudança
**Arquivo**: `26_regras_juridicas_mudanca_tributacao.sql`

Função: separar o que é mera evidência de estoque do que efetivamente é crédito/debito em mudança de tributação.

### E.7. Etapa 7 — reconciliar com a apuração
**Arquivo**: `27_reconciliacao_mudanca_bloco_e.sql`

Função: verificar se o efeito item a item do inventário conversa com `E111`, `E210` e `E220`.

### E.8. Etapa 8 — expor o resultado auditável
**Arquivo**: `28_resultado_final_mudanca_tributacao.sql`

Função: publicar flags, diferenças, lacunas e aderência tributária.

---

## F. Comparação com a legislação/documentação tributária

### F.1. Pontos de aderência

1. **Uso do Bloco H**
   A documentação do projeto vincula explicitamente a mudança de tributação ao levantamento de estoque no Bloco H, com `H010` para os itens e `H020` para o valor do imposto a creditar por item.

2. **`H005` motivo 02**
   A mudança de forma de tributação é tratada, nos materiais de apoio, como motivo `02` no `H005`.

3. **Reflexo no Bloco E**
   O material também liga a mudança de tributação à escrituração em `E111` quando houver crédito e em `E210/E220` quando houver débito de ICMS-ST.

4. **Prova documental da entrada**
   A consulta tenta ancorar o estoque em documentos de entrada reais, o que é coerente com a necessidade de demonstrar a origem do imposto embutido no estoque.

### F.2. Divergências, insuficiências e extrapolações

1. **A consulta não exige `mot_inv = 02`**
   Então ela pode capturar inventários anuais ou outras fotografias do estoque que não representam, juridicamente, mudança de tributação.

2. **A consulta não identifica se a mercadoria estava entrando ou saindo da ST**
   Sem isso, não há como decidir corretamente entre crédito (`E111`) e débito (`E210/E220`).

3. **A consulta não calcula imposto**
   Ela compara valor unitário de inventário com valor unitário da última compra. Isso é útil como indício, mas não equivale ao imposto próprio ou ao ICMS-ST embutido no estoque.

4. **Ausência de NCM/CEST e vigência**
   Mudança de tributação em ST depende da situação normativa da mercadoria. Sem cruzar NCM/CEST com a vigência do Anexo VI, a consulta não consegue provar juridicamente o enquadramento.

5. **Ausência de fator de conversão (`0220`)**
   Se a unidade do inventário não coincidir com a unidade da entrada, o vínculo econômico pode ser falso mesmo quando o `cod_item` coincide.

6. **Uso da última compra como proxy legal**
   A legislação operacional do projeto fala em imposto pago na entrada para o estoque remanescente. A última compra pode ser evidência útil, mas não substitui automaticamente a reconstrução do imposto efetivamente suportado nas quantidades em estoque.

---

## G. Críticas e riscos

### G.1. Fragilidades técnicas

1. partição simplificada em `reg_0000`;
2. uso de item normalizado sem tabela de equivalência;
3. dependência de `SEQ_NITEM = 1` para captar `NSU`/UFs;
4. ausência de `0220`;
5. ausência de CST/C190/C197/C176/Bloco E no cálculo.

### G.2. Fragilidades tributárias

1. não filtra mudança de tributação por `mot_inv = 02`;
2. não separa cenário de crédito e cenário de débito;
3. não calcula ICMS próprio e ICMS-ST do estoque;
4. não valida se a mercadoria realmente deixou ou passou a integrar o regime de ST;
5. não reconcilia com `E111/E210/E220`.

### G.3. Riscos de interpretação

1. tratar diferença de valor unitário como diferença de imposto;
2. supor que última compra basta para valorar o estoque tributário;
3. aceitar qualquer inventário como se fosse inventário de mudança de tributação;
4. concluir direito a crédito sem demonstrar enquadramento normativo do item.

---

## H. Melhorias recomendadas

1. **Obrigar `mot_inv = 02`** quando o objetivo for mudança de forma de tributação.
2. **Parametrizar o evento normativo**: data de início/fim da ST por NCM/CEST.
3. **Cruzar o item com NCM/CEST e vigência estadual**.
4. **Reconstituir o imposto embutido no estoque**, e não apenas o preço unitário.
5. **Criar dois fluxos jurídicos explícitos**:
   - saída da ST para o regime normal → crédito;
   - entrada na ST → débito.
6. **Reconciliar com `E111`, `E210` e `E220`**.
7. **Adicionar fator de conversão e validação de unidade**.
8. **Trazer `C190/C197` ou outra base fiscal complementar** quando houver necessidade de recuperar o imposto suportado nas entradas.

---

## I. Versão reestruturada da lógica SQL, quando aplicável

### I.1. Fluxo mínimo recomendado

1. `arquivos_validos_mudanca`
2. `estoque_bloco_h`
3. `entradas_sped`
4. `ultima_entrada_por_item_e_data`
5. `base_mudanca_tributacao`
6. `classificacao_juridica_mudanca`
7. `reconciliacao_bloco_e`
8. `resultado_final_mudanca`

### I.2. Sentido jurídico da nova modelagem

A mudança de tributação não deve ser tratada como simples comparação de custo. Ela precisa ser lida como uma cadeia de prova:

- **prova da existência do estoque**;
- **prova de qual inventário está sendo usado**;
- **prova da entrada que compôs esse estoque**;
- **prova de que o item estava ou deixou de estar no regime de ST**;
- **prova do imposto embutido a creditar ou do débito a exigir**;
- **prova de que isso foi refletido corretamente na apuração**.

A modularização nova foi desenhada exatamente para separar essas camadas.

---

## 2. Explicação detalhada de cada arquivo SQL criado para esta abordagem

### `20_parametros_e_arquivos_validos_mudanca.sql`
Seleciona a última EFD válida por período e preserva a lógica de corte por `data_entrega`. A observação crítica nele é que o “+2 meses” no `data_final` é regra operacional do projeto e não regra legal do SPED.

### `21_estoque_bloco_h.sql`
Materializa `H005/H010/H020/0200`. O arquivo já deixa comentado que, para mudança de tributação, o uso recomendado é filtrar `mot_inv = '02'`, salvo quando o usuário quiser deliberadamente uma varredura mais ampla.

### `22_nsu_documental.sql`
Isola o enriquecimento do BI. A ideia é impedir que `NSU` e UFs fiquem misturados com a lógica tributária principal.

### `23_entradas_sped.sql`
Abre as entradas do `C100/C170` com filtros explícitos. O arquivo já deixa claro que se trata de prova documental de compra, não de cálculo do imposto do estoque.

### `24_ranking_ultima_entrada_inventario.sql`
Escolhe a última entrada do item antes do inventário. É um módulo de rastreabilidade documental, não um módulo de valoração legal definitiva.

### `25_base_mudanca_tributacao.sql`
Une estoque, última compra e `H020`. Serve para comparar o valor do inventário com o valor da última entrada e expor lacunas.

### `26_regras_juridicas_mudanca_tributacao.sql`
Cria uma camada explícita de enquadramento: inventário apto para mudança, crédito potencial, débito potencial e itens pendentes de validação normativa.

### `27_reconciliacao_mudanca_bloco_e.sql`
Cruza a base do inventário com `E111/E210/E220`. Este é o arquivo que fecha a obrigação acessória com a apuração.

### `28_resultado_final_mudanca_tributacao.sql`
Publica o resultado auditável da abordagem de mudança de tributação.

### `29_query_original_mudanca_tributacao_referencia.sql`
Preserva a consulta original recebida, para rastreabilidade histórica.

---

## 3. Síntese final

A consulta original é útil como **trilha preliminar de auditoria** para mudança de tributação, porque ela enxerga estoque, `H020` e última entrada. O problema é que ela ainda não faz o salto de “evidência de estoque” para “efeito tributário juridicamente suportado”.

A nova modularização corrige isso ao separar:

1. prova do inventário;
2. prova da última entrada;
3. classificação jurídica do evento de mudança;
4. reconciliação com a apuração no Bloco E.

Esse desenho é mais seguro para auditoria, manutenção e validação tributária.
