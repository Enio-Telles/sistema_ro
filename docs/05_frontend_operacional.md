# Frontend operacional do sistema_ro

## Diretrizes

O frontend deve ser construído como interface operacional, não como dashboard decorativo.
O foco principal é navegação por tabela, rastreabilidade de mercadorias e revisão assistida.

## Módulos principais

### 1. Mercadorias
Subabas:
- Agregação
- Conversão de Unidades
- Produtos Consolidados
- Cadastros Agrupados

### 2. Estoque
Subabas:
- Movimentação de Estoque
- Apuração Mensal
- Apuração Anual
- Apuração por Períodos
- Resumo Fiscal
- Alertas
- Bloco H

### 3. Fisconforme não atendido
Etapas:
- Consulta
- Resultados
- Para Notificações

## Contrato de UX transversal

Toda tabela relevante deve suportar:
- filtro textual
- filtro por período
- paginação
- seleção e ordem de colunas
- persistência de contexto por aba
- exportação
- abertura em nova aba
- destaque visual de anomalias

## Agregação

A aba deve exibir separadamente:
- `lista_descricoes`
- `lista_desc_compl`
- `lista_itens_agrupados`
- `ids_origem_agrupamento`

Ações mínimas:
- filtrar por descrição principal
- filtrar por complemento
- revisar score/confiança do grupo
- executar merge manual
- executar reversão por snapshot

## Conversão de unidades

A aba deve exibir:
- `id_agrupado`
- `mercadoria_id`
- `apresentacao_id`
- `unid`
- `unid_ref`
- `fator`
- `tipo_fator`
- `confianca_fator`
- `fator_manual`
- `unid_ref_manual`

Ações mínimas:
- editar fator manual
- editar unidade de referência
- aplicar unidade de referência em lote por grupo
- filtrar grupos com unidade única
- destacar fatores ambíguos

## Estoque

### Movimentação
Mostrar a trilha cronológica com:
- `fonte`
- `Tipo_operacao`
- `Dt_doc` / `Dt_e_s`
- `q_conv`
- `saldo_estoque_anual`
- `entr_desac_anual`
- `custo_medio_anual`
- `tipo_fator_aplicado`
- `match_confidence`

### Mensal / Anual / Períodos
Mostrar datasets próprios, não apenas filtros sobre a mesma tabela.
Cada subaba precisa de resumo no topo e detalhamento abaixo.

### Resumo Fiscal
KPIs mínimos:
- produtos com saldo negativo potencial
- produtos com entradas desacobertadas
- produtos com fator manual
- produtos com fator de baixa confiança
- divergência entre estoque calculado e inventário declarado

### Bloco H
Sub-subabas:
- H005 resumo
- H010/H020 detalhamento

## Fisconforme não atendido

### Consulta
- DSF
- referência
- período
- modo individual ou lote
- upload/reuso de PDF
- dados do auditor
- pasta de saída

### Resultados
- resumo executivo
- filtro por com pendência / sem pendência / com erro
- card por CNPJ
- detalhes cadastrais
- tabela de malhas
- atalho para Dossiê

### Para Notificações
- checklist de prontidão
- placeholders resolvidos
- geração individual TXT/Word
- geração lote ZIP
- indicação de salvamento local quando houver

## Regras visuais
- tabelas compactas e legíveis
- cores de exceção reservadas a alertas reais
- cabeçalhos fixos
- ordenação previsível
- performance aceitável com datasets grandes

## Estado persistido

Persistir por módulo:
- filtros ativos
- colunas visíveis
- ordem das colunas
- larguras das colunas
- CNPJ selecionado
- subaba atual
- período ativo
