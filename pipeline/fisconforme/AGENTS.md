# AGENT – Fisconforme (pipeline/fisconforme)

Este agente aborda o enriquecimento e validação de conformidade fiscal em `pipeline/fisconforme/`.

## Responsabilidades

- **Enriquecer dados** com informações externas (SEFIN, Sintegra, etc.), como códigos fiscais, tabelas de alíquotas e notas fiscais eletrônicas complementares.  
- **Calcular indicadores de conformidade** (divergência de CFOP, NCM incoerente, CST incompatível) e sinalizar riscos.  
- **Gerar flags** ou relatórios para auditoria, classificando operações suspeitas ou inconsistentes.  
- **Manter sincronização** entre dados internos e externos, realizando atualizações periódicas.

## Convenções

- Guarde tabelas de referência em `references/` com versionamento.  
- Documente regras de conformidade em `docs/`, incluindo link para leis ou normativos fiscais.  
- Mantenha as chaves de vinculação (`id_agrupado`, `id_agregado`, CNPJ, chave de NF) para cruzar dados internos e externos.  
- Não corrija dados originais na etapa de fisconforme; adicione colunas de status ou alerta separadas.

## Anti‑padrões

- Enriquecer dados sem documentar a fonte e a data da atualização.  
- Alterar valores originais em vez de gerar colunas de conformidade.  
- Criar regras de conformidade ad hoc que conflitam com normativos fiscais vigentes.