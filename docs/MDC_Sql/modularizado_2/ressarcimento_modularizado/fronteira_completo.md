# Análise modular da rotina `fronteira_completo.sql`

## 1. Escopo do material

Este documento aplica à consulta `fronteira_completo.sql` o mesmo padrão adotado nas demais trilhas do pacote:

1. identificar o objetivo fiscal e operacional da SQL;
2. separar fontes documentais, fontes SITAFE e regras de negócio;
3. decompor a consulta em módulos menores;
4. apontar aderência, limites e riscos sob a ótica tributária e de auditoria;
5. conectar a lógica com a disciplina de Rondônia para antecipação/Fronteira, ressarcimento e controle de créditos.

A consulta original não é, em essência, uma rotina de cálculo de ressarcimento por `C176`. Ela é uma rotina de **conciliação entre a NF-e do BI e os lançamentos do SITAFE/Fronteira**, com foco em:

- identificar a nota de entrada interestadual destinada a contribuinte de Rondônia;
- localizar a nota correspondente no SITAFE;
- abrir o lançamento financeiro/fiscal vinculado;
- abrir o item fiscal e o item de lançamento;
- mostrar receita, guia, situação de pagamento e produto Sefin;
- confrontar a mercadoria/documento com a classificação tributária estadual aplicada no lançamento.

Por isso, esta trilha é mais próxima de uma **auditoria de lastro fiscal do Fronteira** do que de uma simples auditoria de EFD.

---

## A. Objetivo da consulta

### A.1. Objetivo técnico

A SQL original tenta responder, por NF-e de entrada:

1. a nota existe no BI com status autorizado e perfil interestadual para destinatário em Rondônia?
2. essa mesma chave foi reconhecida no SITAFE como nota sujeita a lançamento?
3. existe lançamento financeiro e item de lançamento ligado à nota?
4. qual produto estadual (`co_sefin`) foi efetivamente usado?
5. qual receita, guia e situação de pagamento foram atribuídas?
6. os valores de produto, base, alíquota, débito, crédito e ICMS recolher do SITAFE fazem sentido frente ao item da NF-e?

### A.2. Objetivo tributário aparente

Do ponto de vista fiscal, a consulta serve para verificar a coerência entre:

- a **prova documental da operação** (NF-e no BI/XML),
- a **materialização do lançamento estadual no SITAFE**,
- e a **classificação tributária estadual da mercadoria** (`sitafe_mercadoria` / `sitafe_produto_sefin`).

Isso é muito útil para auditorias de:

- antecipação/Fronteira;
- reconstrução de recolhimento associado à nota de entrada;
- validação de lastro de ressarcimento ou crédito ligado a entradas antecipadas;
- identificação de nota com pagamento, suspensão, parcelamento ou outra situação de lançamento.

---

## B. Tabelas e fontes utilizadas

### B.1. Tabelas do BI / XML

- `bi.fato_nfe_detalhe`: origem documental primária da NF-e.
  - Função: localizar a chave, identificar emitente, destinatário, UF de origem, data de emissão e número da nota.

### B.2. Tabelas do SITAFE

- `sitafe.sitafe_nota_fiscal`
  - Função: localizar a nota dentro do ambiente SITAFE.

- `sitafe.sitafe_nf_lancamento`
  - Função: ligar a nota ao lançamento fiscal/financeiro.

- `sitafe.sitafe_nfe_item`
  - Função: abrir os itens da NF-e dentro do SITAFE, inclusive `co_sefin`.

- `sitafe.sitafe_lancamento`
  - Função: trazer guia, receita, valor devido, valor pago e situação.

- `sitafe.sitafe_lancamento_item`
  - Função: abrir o item do lançamento, permitindo confrontar produto e valores.

- `sitafe.sitafe_mercadoria`
  - Função: trazer a parametrização fiscal estadual do produto.

- `sitafe.sitafe_produto_sefin`
  - Função: descrição do código estadual do produto.

### B.3. CTEs da consulta original

- `PARAMETROS`
- `ORIGEM_NFE`

A modularização proposta adiciona novas camadas intermediárias para que o percurso BI -> nota SITAFE -> lançamento -> item -> produto estadual fique auditável.

---

## C. Filtros identificados

### C.1. Filtros documentais

A consulta original trabalha com NF-e:

- em que o contribuinte informado é **destinatário**;
- de **entrada** (`CO_TP_NF = 1`);
- emitidas por UF diferente de Rondônia (`CO_UF_EMIT <> 'RO'`);
- autorizadas (`INFPROT_CSTAT IN ('100','150')`).

Isso indica foco em entradas interestaduais passíveis de antecipação/Fronteira.

### C.2. Filtros SITAFE

No lado SITAFE, a consulta exige que:

- a nota no SITAFE tenha a mesma chave da NF-e;
- o CNPJ destino da nota e do lançamento seja o contribuinte filtrado.

Na prática, isso restringe o resultado a lançamentos reconhecidos como pertencentes ao mesmo destinatário.

### C.3. Filtros implícitos

Há filtros implícitos importantes:

1. a nota precisa existir no BI e no SITAFE ao mesmo tempo;
2. o item do lançamento é ligado ao item da NF-e por `co_sefin`, não por `num_item` da nota;
3. a classificação fiscal estadual usada é a existente em `sitafe_mercadoria`, sem corte explícito de vigência na versão original;
4. a consulta presume que a melhor chave de conciliação BI x SITAFE é a própria chave de acesso.

---

## D. Regras de negócio explícitas e implícitas

### D.1. Regras explícitas

1. **A prova de origem nasce no BI**
   - A CTE `ORIGEM_NFE` é a tabela motora.

2. **Só entram notas interestaduais destinadas ao contribuinte**
   - A consulta foi desenhada para o universo típico do Fronteira.

3. **A nota do SITAFE é vinculada pela chave**
   - `sitafe_nota_fiscal.it_nu_identificao_nf_e = origem.chave`.

4. **O item fiscal do lançamento é vinculado ao item da NF-e por `co_sefin`**
   - `lanc_item.it_co_produto = item.it_co_sefin`.

5. **A consulta traduz a situação do lançamento**
   - pago, suspenso, parcelado, inscrito em dívida ativa, compensação etc.

### D.2. Regras implícitas

1. **A existência do lançamento é tratada como evidência de incidência operacional**
   - mas isso não substitui análise jurídica da hipótese tributária.

2. **A classificação estadual aplicada no lançamento é tratada como a classificação fiscal de fato**
   - o que pode ser operacionalmente correto, mas não elimina a necessidade de conferir NCM/CEST e vigência.

3. **Não há reconciliação direta com EFD**
   - a consulta comprova nota, lançamento, item e pagamento, mas não fecha apropriação em `C176`, `H020` ou `E111/E210/E220`.

---

## E. Atomização da consulta em etapas menores

### Módulo 100 — Parâmetros e origem da NF-e
Define o universo documental mínimo.

### Módulo 101 — Nota e lançamento SITAFE
Localiza a nota dentro do SITAFE e o lançamento financeiro/fiscal associado.

### Módulo 102 — Item fiscal, item do lançamento e mercadoria
Abre o detalhe do item e a classificação estadual.

### Módulo 103 — Cruzamento NFe x SITAFE
Une BI, nota fiscal, lançamento, item, mercadoria e produto estadual.

### Módulo 104 — Resultado final
Expõe os campos principais da auditoria.

### Módulo 105 — Resumo gerencial
Agrupa por receita e situação de pagamento.

### Módulo 106 — Orquestração integrada
Mostra como esta trilha conversa com as demais abordagens do pacote.

---

## F. Comparação com a legislação/documentação tributária

### F.1. Onde a lógica está aderente

1. **Entradas interestaduais e antecipação**
   - O material institucional de Rondônia destaca que, para mercadorias sujeitas à cobrança antecipada/Fronteira, a prova do valor e do lançamento pode precisar ser buscada no ambiente SITAFE, e não apenas na nota do fornecedor.

2. **Ressarcimento e créditos acumulados**
   - Os materiais do projeto e o Anexo IX do RICMS/RO mostram que créditos ligados a ressarcimento e a entradas com cobrança antecipada são objetos de controle específico. Por isso, uma trilha que reconstrói nota, lançamento e pagamento no SITAFE é pertinente como camada de prova.

3. **Disciplina estadual do ressarcimento**
   - A apresentação institucional e o guia do projeto deixam claro que o direito ao ressarcimento depende da existência de imposto pago/retido na entrada e da escrituração adequada. Esta consulta ajuda justamente a provar a camada entrada + cobrança/lançamento.

### F.2. Onde a lógica extrapola ou exige cuidado

1. **Não basta existir lançamento no SITAFE para existir direito de crédito**
   - A consulta mostra ocorrência operacional e financeira, não elegibilidade jurídica final.

2. **Não há corte de vigência explícito em `sitafe_mercadoria`**
   - Isso pode gerar leitura de parametrização atual para nota antiga, caso a tabela não seja historizada da forma esperada.

3. **Não há confronto automático com EFD**
   - A trilha é ótima para lastro documental/financeiro, mas incompleta para fechamento fiscal mensal.

---

## G. Críticas e riscos

### G.1. Fragilidades técnicas

- A query original usa `GROUP BY` com `MAX` na origem para obter unicidade por chave.
  - Isso resolve performance, mas esconde eventuais inconsistências documentais no BI.

- O vínculo item-lançamento ocorre por `co_sefin`.
  - Se houver mais de um item com o mesmo código estadual, pode haver sobreposição ou repetição.

- O módulo não historiza explicitamente a classificação fiscal estadual.

### G.2. Fragilidades tributárias

- Não demonstra, sozinho, se a operação gerou crédito apropriável, ressarcimento, débito ou mera antecipação.
- Não reconcilia com `C176`, `H020`, `E111`, `E210` ou `E220`.
- Não valida CFOP, CST, motivo do ressarcimento ou hipótese legal do art. 20 do Anexo VI.

### G.3. Melhor uso prático

A consulta é excelente como:

- camada de prova do lançamento Fronteira;
- auditoria de nota x SITAFE;
- preparação de dossiê para ressarcimento ou mudança de tributação;
- investigação de situações de pagamento, suspensão e parcelamento.

Ela não deve ser usada isoladamente como cálculo final do direito creditório.

---

## H. Melhorias recomendadas

1. adicionar corte explícito de vigência para a classificação da mercadoria;
2. criar reconciliação opcional com `C176` e `E111/E210/E220`;
3. separar produto documental (`NCM/CEST/XML`) de produto estadual (`co_sefin`);
4. criar flags de divergência entre:
   - NCM da NF-e,
   - `co_sefin` do item SITAFE,
   - receita do lançamento,
   - situação de pagamento;
5. produzir resumo por nota e por guia para auditoria gerencial.

---

## I. Referências normativas e documentais utilizadas

Esta trilha foi descrita com apoio nas seguintes referências já adotadas no pacote:

- RICMS/RO – Anexo VI (ressarcimento e restituição no regime de ST/antecipação);
- IN 022/2018/GAB/CRE;
- Guia de Ressarcimento ST e Mudança de Tributação;
- apresentação institucional de ressarcimento;
- Anexo IX do RICMS/RO (uso e monitoramento de créditos acumulados);
- documentos operacionais do projeto sobre Fronteira/SITAFE.

Observação importante:
esta trilha tem forte componente **operacional de conciliação**. Parte dela decorre diretamente da documentação do projeto e da organização dos dados no SITAFE, e não da transcrição literal de um dispositivo normativo específico.
