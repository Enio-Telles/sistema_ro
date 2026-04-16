# Análise modular da rotina de ressarcimento de ICMS-ST

## 1. Escopo do material

Este pacote converte a consulta monolítica enviada em uma malha de módulos menores, auditáveis e reutilizáveis.

A modularização não foi feita apenas para “fatiar” a SQL. O objetivo foi separar, de forma rastreável, blocos com naturezas diferentes:

- prova documental da EFD;
- prova documental do XML;
- apoio cadastral do 0200;
- validação com Fronteira/SITAFE;
- vínculo entre item de saída e item de entrada;
- inferência fiscal por NCM/CEST/vigência;
- rateio da quantidade que pode sustentar o ressarcimento;
- cálculo monetário;
- fechamento jurídico da elegibilidade do ICMS próprio;
- reconciliação com a apuração do Bloco E.

---

## 2. Objetivo tributário da rotina original

Em linguagem de negócio, a rotina procura responder a seguinte pergunta:

> Para cada item de saída com ressarcimento escriturado no C176, o vínculo com a entrada, a quantidade considerada e o valor do ressarcimento são coerentes com a EFD, com o XML, com o Fronteira e com um cálculo fiscal inferido?

A consulta original faz isso em quatro frentes:

1. **EFD**: usa `reg_0000`, `reg_c100`, `reg_c170`, `reg_c176` e `reg_0200`.
2. **XML**: usa `bi.fato_nfe_detalhe` para reforçar a prova do item de entrada e do item de saída.
3. **Fronteira/SITAFE**: usa `sitafe_nfe_calculo_item` para buscar o valor do ICMS-ST itemizado quando a sistemática relevante estiver no Fronteira.
4. **Inferência fiscal**: usa NCM, CEST, MVA e alíquotas para reconstruir um valor calculado e compará-lo com o que foi escriturado.

---

## 3. Base normativa e documental considerada na modularização

A análise modular foi estruturada com base em quatro grupos de referência:

### 3.1. IN 22/2018 e materiais de apoio de Rondônia
A lógica do pacote foi alinhada à ideia central de que:

- o ressarcimento precisa ser demonstrado item a item;
- o C176 é filho do C170 e detalha a entrada vinculada à saída;
- a valoração deve usar a entrada correspondente;
- quando isso não for possível, a rotina precisa tratar entradas suficientes para suportar a quantidade da saída;
- a escrituração final precisa conversar com a apuração do Bloco E.

### 3.2. Material operacional sobre Fronteira
Foi considerada a orientação de que, em cenários de antecipação com encerramento de fase, o valor do ICMS-ST nem sempre pode ser reconstruído apenas pela nota do fornecedor, devendo ser buscado no Fronteira/SITAFE.

### 3.3. Casos administrativos e de malha
Também foi considerada a necessidade prática de reconstituir o item correto quando o C176 aponta a nota certa, mas o item errado, exigindo cruzamento por NCM, descrição, GTIN e quantidade.

### 3.4. Diretriz arquitetural
Foi adotada a premissa de que score, ranking, conciliações e regras jurídicas não devem ficar enterrados dentro de uma única SQL opaca. Por isso, o pacote separa o que é:

- extração mínima Oracle;
- reconstrução analítica do vínculo;
- enquadramento jurídico;
- reconciliação final.

---

## 4. Fontes técnicas usadas

### SPED
- `sped.reg_0000`
- `sped.reg_c100`
- `sped.reg_c170`
- `sped.reg_c176`
- `sped.reg_0200`
- `sped.reg_e111` *(esperado para a reconciliação do Bloco E)*
- `sped.reg_e210` *(esperado para a reconciliação do Bloco E-ST)*
- `sped.reg_e220` *(esperado para a reconciliação dos ajustes por apuração)*

### XML / BI
- `bi.fato_nfe_detalhe`

### SITAFE / SEFIN
- `sitafe.sitafe_nfe_calculo_item`
- `sitafe.sitafe_cest_ncm`
- `sitafe.sitafe_produto_sefin_aux`

### Sistema
- `dual`

> Observação: caso os nomes físicos de `E111`, `E210` ou `E220` sejam diferentes no banco do projeto, adapte apenas o módulo de reconciliação. Os demais módulos não dependem dessas tabelas.

---

## 5. Resumo executivo da query original

### O que a query original faz
- seleciona a última EFD válida por período;
- restringe o universo ao CNPJ e ao intervalo pedidos;
- captura as saídas com C176;
- usa a chave da última entrada informada no C176;
- abre os itens possíveis da nota de entrada;
- cruza os itens da entrada com XML e cadastro 0200;
- pontua candidatos e escolhe o item mais aderente;
- incorpora XML da saída, Fronteira e parâmetros fiscais inferidos;
- rateia a quantidade considerada;
- compara SPED, XML, Fronteira e cálculo inferido;
- produz uma visão final de auditoria por item.

### O que a query original não faz bem
- mistura regra tributária, regra cadastral, regra operacional e regra de qualidade de dados;
- incorpora score heurístico dentro da SQL final;
- não fecha a apuração com E111/E210/E220;
- não separa valor documental do ICMS próprio de valor juridicamente elegível;
- não trata fator de conversão de unidade.

---

## 6. Módulos do pacote e função de cada arquivo

### `00_parametros_e_arquivos_validos.sql`
Resolve a moldura temporal. Identifica a última EFD válida por período, respeitando CNPJ e data-limite de processamento.

### `01_saidas_ressarcimento_c176.sql`
Abre o universo do ressarcimento já escriturado. É o ponto de partida natural da auditoria, porque o C176 é a prova item a item do que foi declarado.

### `02_produtos_cadastro_0200.sql`
Extrai NCM, CEST, descrição e GTIN do cadastro de produtos da EFD. Esse módulo não cria direito creditório; ele sustenta a identificação fiscal e cadastral do item.

### `03_xml_entrada_fronteira.sql`
Busca XML da entrada e valor do Fronteira por item. É o módulo documental mais importante para validar ST em cenários de antecipação.

### `04_xml_saida.sql`
Busca XML da saída para reforçar o item documental e a quantidade da operação de saída.

### `05_itens_entrada_sped_base.sql`
Lista todos os itens candidatos dentro da chave de entrada informada no C176.

### `06_score_candidatos_vinculo.sql`
Aplica a heurística de vínculo entre o item da saída e os itens possíveis da entrada. Pontua `cod_item`, item documental, GTIN, NCM, CEST, descrição e quantidade, além de punir conflitos fiscais.

### `07_vinculo_entrada_escolhido.sql`
Seleciona o candidato vencedor e mede confiança, ambiguidade e conflitos.

### `08_base_vinculos_e_inferencia_sefin.sql`
Transforma o vínculo escolhido em uma base fiscalmente enriquecida, trazendo NCM/CEST prioritários, vigência, alíquota interna, MVA e indicador de ST.

### `09_rateio_quantidades.sql`
Calcula a `qtd_considerada`. Aqui está um ponto crítico: a query original consome da mais antiga para a mais nova, enquanto a literalidade normativa pode exigir recência em certos cenários.

### `10_calculos_ressarcimento.sql`
Calcula:
- ICMS próprio do SPED;
- ICMS próprio reconstituído pelo XML;
- ST escriturada;
- ST do Fronteira;
- ST inferida por cálculo.

### `11_resultado_final_auditoria.sql`
Expõe a visão final auditável por item, com colunas de rastreabilidade, score, parâmetros fiscais, valores, diferenças e status.

### `12_orquestracao_referencia.sql`
Mostra como materializar os módulos em views, tabelas temporárias ou datasets.

### `13_reconciliacao_bloco_e.sql` **(novo)**
Fecha a lógica do item com a apuração mensal. Agrega o resultado auditado por período e compara com E111/E210/E220. Esse módulo não substitui a conferência documental do item; ele verifica se o resultado chega à apuração com o código de ajuste correto.

### `14_elegibilidade_icms_proprio.sql` **(novo)**
Separa o que é valor documental do ICMS próprio daquilo que é juridicamente elegível para apropriação. Ele foi feito como módulo parametrizável, porque a permissão legal depende da hipótese do ressarcimento e das regras materiais aplicáveis.

### `99_query_original_referencia.sql`
Mantém a query original intacta para rastreabilidade.

### `README_CONTRATOS_SQL.txt`
Documenta os nomes lógicos assumidos entre um módulo e outro.

---

## 7. Leitura jurídica da nova modularização

A modularização nova melhora a aderência analítica por três motivos.

### 7.1. Ela separa prova documental de inferência fiscal
Antes, a mesma query localizava o item, inferia NCM/CEST, escolhia MVA, calculava valor e classificava confiança. Agora esses passos estão separados.

### 7.2. Ela separa valor documental de valor juridicamente utilizável
O módulo `10` continua útil para reconstruir o valor documental do ICMS próprio. Mas o módulo `14` deixa explícito que esse valor não pode ser apropriado automaticamente sem validação jurídica da hipótese.

### 7.3. Ela separa item auditado de apuração fechada
O módulo `11` entrega o item auditado. O módulo `13` verifica se isso chega corretamente ao Bloco E.

---

## 8. Pontos críticos identificados

### 8.1. Ordem de consumo das entradas
A query original usa cronologia crescente no rateio. Isso precisa ser validado contra a interpretação que o projeto pretende adotar para a IN 22/2018.

### 8.2. Elegibilidade do ICMS próprio
Nem todo valor documental de ICMS próprio pode ser apropriado em conta gráfica. O módulo `14` foi criado justamente para que esse tema não fique implícito.

### 8.3. Ausência de fator de conversão
Nesta atualização, o pacote ganhou uma camada específica para **detectar quando a conversão é obrigatória**, em vez de apenas apontar a ausência do fator. Ver `conversao_unidades.md` e `sql_mdc/24_diagnostico_necessidade_conversao_unidade.sql`.

A modularização ainda não resolve conversão de unidade. Esse ponto continua em aberto e deve ser tratado em módulo próprio, se o dataset tiver esse risco.

### 8.4. Dependência de parametrização jurídica
A reconciliação do Bloco E e a elegibilidade do ICMS próprio exigem parametrização local de códigos e hipóteses. Isso é intencional: o pacote evita fingir certeza jurídica onde a norma e a configuração do cliente precisam ser validadas.

---

## 9. Como usar o pacote na prática

### Uso mínimo para auditoria de item
1. Executar `00` a `11`.
2. Validar o vínculo do item da entrada.
3. Comparar SPED, XML, Fronteira e cálculo.

### Uso recomendado para auditoria jurídica completa
1. Executar `00` a `11`.
2. Parametrizar e executar `14_elegibilidade_icms_proprio.sql`.
3. Parametrizar e executar `13_reconciliacao_bloco_e.sql`.
4. Comparar o resultado com o Bloco E e com a política jurídica adotada pelo projeto.

---

## 10. Estrutura sugerida de evolução

Próximos módulos recomendados, se o projeto evoluir:

- módulo de fator de conversão de unidade (`0200/0220`);
- módulo de reconciliação com inventário/estoque;
- módulo de trilha de decisão jurídica por hipótese de ressarcimento;
- módulo de parametrização externa dos pesos do score;
- módulo de fechamento por chave de nota e por período para UI/BI.

---

## 11. Conclusão

O pacote atualizado deixa a rotina mais próxima de uma trilha de auditoria do que de uma SQL monolítica.

Ele agora responde a quatro perguntas em ordem lógica:

1. **O que foi declarado no C176?**
2. **Qual item de entrada realmente sustenta essa declaração?**
3. **Quanto desse item pode ser usado para sustentar a saída?**
4. **Qual parte do valor é apenas documental e qual parte é juridicamente apropriável e reconciliável com o Bloco E?**

Essa separação melhora a rastreabilidade técnica e reduz o risco de transformar uma heurística analítica em uma conclusão jurídica automática.
