# AGENT – Conversão de Unidades (pipeline/conversao)

Este agente cobre as pipelines de **conversão de unidades** em `pipeline/conversao/`.

## Responsabilidades

- **Aplicar fatores de conversão** de volume, peso e quantidade de forma padronizada, garantindo consistência entre diferentes documentos e origens.  
- **Gerenciar fatores manuais** (`fator_manual`), assegurando que existam registros de origem, data de vigência e justificativa.  
- **Ajustar quantidades e valores** em mercadorias e estoque em conformidade com as unidades padronizadas.  
- **Reprocessar dados dependentes** quando um fator for alterado.

## Convenções

- Mantenha uma tabela de fatores em `references/` ou banco local, versionando cada alteração.  
- Valide a presença de `fator_manual` antes de aplicar conversões automáticas; se não existir, registre a necessidade de cadastro.  
- Documente a unidade de entrada (`unidade_origem`) e de saída (`unidade_destino`) em cada transformação.  
- Após atualizar um fator manual, execute pipelines dependentes (mercadorias, estoque) e registre reprocessamento.

## Anti‑padrões

- Aplicar múltiplas conversões sem indicar a ordem ou a origem de cada fator.  
- Não recalcular métricas dependentes quando um fator mudar.  
- Manter fatores em locais temporários (como planilhas locais) sem controle de versão.