# Análise modular da rotina `Aud_EFD_X_(55,65,57))_Por_Período_v2.sql`

## 1. Escopo do material

Este documento aplica à consulta `Aud_EFD_X_(55,65,57))_Por_Período_v2.sql` o mesmo método usado nas outras quatro trilhas do pacote:

1. decompor a SQL em etapas mínimas auditáveis;
2. separar regra de leiaute EFD, regra documental do BI/XML, regra operacional de cruzamento e regra de enriquecimento;
3. identificar fontes, filtros, chaves de junção, omissões, diferenças de ICMS e divergências de período;
4. relacionar a lógica com a base normativa aplicável à escrituração fiscal digital e aos documentos eletrônicos modelos 55, 65 e 57.

Esta consulta não é uma rotina de ressarcimento nem de mudança de tributação. Ela é uma trilha de **auditoria de completude e coerência documental** entre:

- documentos eletrônicos autorizados no BI/XML;
- escrituração da EFD no `C100` (modelos 55 e 65) e `D100` (modelo 57);
- eventos de manifestação do destinatário para omissões de entrada;
- período de emissão do documento versus período em que o documento foi escriturado.

A utilidade tributária dela é grande: antes de validar crédito, ressarcimento, inventário ou cálculo de ICMS-ST, é preciso saber se o documento foi **efetivamente escriturado**, se foi escriturado no **período correto** e se o **valor de ICMS** declarado na EFD dialoga com o valor encontrado no documento eletrônico.

---

## A. Objetivo da consulta

### A.1. Objetivo técnico

A consulta procura responder, por período:

1. quais NF-e, NFC-e e CT-e autorizados existem no BI/XML para o contribuinte;
2. quais desses documentos foram localizados na EFD válida;
3. quais documentos parecem omitidos da EFD;
4. quais documentos foram escriturados em mês diferente da emissão;
5. em quais casos o ICMS do documento difere do ICMS da escrituração;
6. quais entradas omitidas têm manifestação do destinatário registrada;
7. quais documentos aparecem na EFD, mas não foram localizados no conjunto documental do BI/XML usado como base do cruzamento.

### A.2. Objetivo tributário aparente

A finalidade tributária da rotina é apoiar auditoria de obrigação acessória e consistência da apuração. A consulta parte da ideia de que a EFD deve refletir os documentos fiscais e demais informações com repercussão na apuração do imposto, e que a auditoria por chave de acesso permite identificar:

- omissão de escrituração;
- escrituração fora do período;
- divergência de valor de ICMS;
- documento escriturado sem correspondente documental localizado.

Em termos normativos, a trilha dialoga principalmente com:

- a disciplina geral da EFD ICMS/IPI, que exige escrituração completa e coerente dos documentos fiscais e demais informações que repercutem na apuração;
- o leiaute do `C100` para documentos modelos 55 e 65;
- o leiaute do `D100` para CT-e modelo 57;
- a disciplina operacional da manifestação do destinatário, usada aqui como evidência auxiliar para omissões de entrada;
- a validação do arquivo EFD por versão/entrega, refletida no uso da dimensão `bi.dm_efd_arquivo_valido`.

---

## B. Tabelas e fontes utilizadas

### B.1. Tabelas físicas

**BI / XML**
- `bi.fato_nfe_detalhe`: NF-e estruturada item a item.
- `bi.fato_nfce_detalhe`: NFC-e estruturada item a item.
- `bi.fato_cte_detalhe`: CT-e estruturado.
- `bi.dm_eventos`: eventos dos documentos eletrônicos, inclusive manifestação do destinatário.
- `bi.dm_efd_arquivo_valido`: dimensão que informa quais arquivos EFD são considerados válidos.

**SPED**
- `sped.reg_0000`: cabeçalho da EFD.
- `sped.reg_c100`: documentos fiscais modelos 55 e 65 escriturados na EFD.
- `sped.reg_d100`: CT-e modelo 57 escriturado na EFD.

### B.2. CTEs da consulta original

1. `parametros`
2. `cte_ajuste`
3. `docs`
4. `efd`
5. `base`
6. `omissao_entrada`
7. `ev_manifestacao_dest`
8. `max_ev_nota`
9. `max_ev_nota_descricao`
10. `bi_lookup`
11. `docs_n_cruzados`
12. `SELECT FINAL`

---

## C. Filtros identificados

### C.1. Filtros de escopo temporal

O universo documental do BI/XML é restrito a `dhemi BETWEEN data_inicial AND data_final`.

**Impacto:** a auditoria é por emissão do documento, não por data de escrituração.

### C.2. Filtros por papel do contribuinte

A consulta separa papéis distintos do contribuinte:

- destinatário em entradas de NF-e;
- emitente em saídas de NF-e e NFC-e;
- emitente ou tomador no CT-e;
- uma categoria específica de `Entrada Propria`;
- uma categoria operacional `Indicado como remetente`.

**Impacto:** a classificação do documento não depende só do modelo, mas também do papel material do CNPJ na operação.

### C.3. Filtros por autorização do documento

Nos documentos do BI/XML são aceitos apenas `infprot_cstat IN ('100', '150')`.

**Impacto:** a consulta trabalha com documentos autorizados/cancelamento fora do escopo. Isso é coerente com auditoria de escrituração de documentos válidos.

### C.4. Filtros de item-resumo

Nas bases de NF-e e NFC-e usa-se `seq_nitem = '1'`.

**Impacto:** a consulta pega uma linha-resumo por documento na base item a item. Isso é um filtro técnico para evitar duplicação, não um critério tributário.

### C.5. Filtros de validação da EFD

Na CTE `efd`, só entram arquivos marcados em `bi.dm_efd_arquivo_valido`.

**Impacto:** a trilha não trabalha com qualquer entrega do SPED; trabalha com a entrega considerada válida pela camada de governança do BI.

---

## D. Regras de negócio implícitas e explícitas

### D.1. Regras explícitas

1. O cruzamento principal entre documento e EFD é pela **chave de acesso**.
2. O universo documental inclui modelos 55, 65 e 57.
3. O CT-e exige ajuste do tomador efetivo, porque o papel do tomador varia com `CO_TOMADOR3`.
4. A comparação de período é mensal: `TRUNC(efd_ref, 'MM') = TRUNC(dhemi, 'MM')`.
5. A comparação de valores foca `doc_icms` versus `efd_icms`.
6. Omissões de entrada podem ser enriquecidas com manifestação do destinatário.
7. Também há cruzamento reverso: documentos que estão na EFD mas não foram localizados no conjunto `docs`.

### D.2. Regras implícitas

1. A dimensão `dm_efd_arquivo_valido` é tratada como verdade institucional sobre a versão correta da EFD.
2. O BI/XML é tratado como base documental primária para o confronto.
3. A operação `Indicado como remetente` é mantida como categoria operacional herdada da lógica anterior, mas merece revisão jurídica específica no ambiente do contribuinte.
4. A consulta não tenta validar toda a escrita item a item; ela audita o **nível documento**.
5. A manifestação do destinatário é usada como evidência auxiliar, não como prova de escrituração.

---

## E. Atomização da consulta em etapas menores

### `sql/80_parametros_cte_tomador_docs.sql`
Camada de parâmetros e ajuste do CT-e para identificar o tomador efetivo.

### `sql/81_documentos_bi_xml_por_periodo.sql`
Materializa os documentos do BI/XML por período, papel do contribuinte e modelo.

### `sql/82_efd_documentos_validos.sql`
Materializa os documentos escriturados na EFD válida, em `C100` e `D100`.

### `sql/83_cruzamento_documentos_x_efd.sql`
Faz o confronto principal por chave de acesso e classifica coincidência de período.

### `sql/84_omissoes_entrada_eventos.sql`
Isola omissões de entrada e traz eventos de manifestação do destinatário.

### `sql/85_lookup_bi_xml_simetrico.sql`
Monta o lookup amplo do BI/XML para o cruzamento reverso.

### `sql/86_efd_nao_cruzada_bi_xml.sql`
Encontra documentos da EFD sem correspondente no conjunto documental principal.

### `sql/87_resultado_final_auditoria_docs.sql`
Consolida a saída final da trilha documental.

### `sql/88_resumo_periodo_auditoria_docs.sql`
Agrega a trilha por período, operação e tipo de inconsistência.

### `sql/90_orquestracao_cinco_abordagens.sql`
Mostra como esta trilha documental pode conviver com as quatro anteriores.

---

## F. Comparação com a legislação/documentação tributária

### F.1. Pontos de aderência

**Escrituração documental na EFD**
A consulta é aderente à ideia central de que a EFD deve conter os documentos fiscais e demais informações com repercussão na apuração. Por isso o cruzamento de `C100` e `D100` com documentos do BI/XML faz sentido como trilha de auditoria de obrigação acessória.

**Modelos corretos de registros**
A separação entre modelos 55/65 no `C100` e modelo 57 no `D100` é coerente com o leiaute da EFD.

**Manifestação do destinatário como enriquecimento**
A manifestação não substitui a escrituração, mas é útil para dar contexto às omissões de entrada, especialmente quando há ciência da operação, confirmação ou desconhecimento.

### F.2. Pontos de cautela

**`Entrada Propria` e `Indicado como remetente`**
Essas categorias são operacionais. Elas podem ser úteis para análise, mas não devem ser confundidas automaticamente com categorias jurídicas fechadas da EFD.

**`doc_icms` versus `efd_icms`**
Comparar o total de ICMS do BI/XML com o campo total da EFD é útil como trilha de divergência, mas não resolve sozinho diferenças de arredondamento, complementos, estornos, ajustes ou tratamentos específicos do documento.

**Base documental por `seq_nitem = 1`**
Essa técnica é válida para reduzir duplicidade na fato item a item, mas não deve ser confundida com auditoria item a item.

---

## G. Críticas e riscos

1. **A consulta audita no nível documento, não no nível item.**
2. **A categoria `Indicado como remetente` precisa validação de negócio local.**
3. **Diferenças de ICMS podem decorrer de regra fiscal legítima e não só de erro.**
4. **A ausência no BI/XML não prova, sozinha, inexistência do documento.**
5. **Eventos de manifestação ajudam, mas não substituem obrigação de escrituração.**
6. **O cruzamento por período mensal é adequado para auditoria inicial, mas não resolve casos com escrituração extemporânea juridicamente justificada.**

---

## H. Melhorias recomendadas

1. Criar um módulo opcional de abertura item a item para documentos com divergência relevante.
2. Parametrizar regras específicas por `cod_sit` e por modelo documental.
3. Criar reconciliação com ajustes do Bloco E quando a divergência de ICMS repercutir na apuração.
4. Tratar separadamente eventos de manifestação favoráveis e desfavoráveis.
5. Permitir filtros por UF de origem/destino e por operação.

---

## I. Versão reestruturada da lógica SQL, quando aplicável

A trilha documental fica mais auditável se organizada em cinco camadas:

1. **Parâmetros e ajuste do CT-e**;
2. **Universo documental BI/XML**;
3. **Universo escriturado na EFD válida**;
4. **Cruzamento principal e cruzamento reverso**;
5. **Saída analítica e resumo por período**.

Essa organização evita confundir:
- prova documental;
- regra de leiaute da EFD;
- enriquecimento por evento;
- conclusão fiscal.

O papel desta quinta abordagem no pacote é servir como **camada de sanidade documental** para as outras quatro: antes de discutir ressarcimento, inventário, Fronteira ou cálculo histórico, é saudável provar que os documentos existem, foram escriturados e estão no período esperado.
