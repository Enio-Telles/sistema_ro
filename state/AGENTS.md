# AGENT – Estado (state/)

O diretório `state/` contém arquivos ou registros de estado de execução (checkpoints, flags, marcadores de progresso). Este agente descreve como esse estado deve ser usado e mantido.

## Responsabilidades

- **Persistir checkpoints** das pipelines para que execuções possam ser retomadas ou reprocessadas de forma incremental.  
- **Armazenar flags e parâmetros** que indicam se determinado período/CNPJ já foi processado ou se há pendências.  
- **Controlar reprocessamentos**: registrar quando um dataset foi reprocessado devido a alteração de schema, fator de conversão ou correção fiscal.  
- **Evitar duplicidade** de processamento, assegurando que uma mesma combinação de CNPJ/período não seja processada múltiplas vezes sem necessidade.

## Convenções

- Use formatos simples (CSV, JSON, Parquet) com nomes descritivos (`checkpoint_extracao.csv`, `status_proc_parquet.json`).  
- Mantenha histórico de estados ao invés de sobrescrever (por exemplo, registre data e razão do reprocessamento).  
- Sincronize o estado com logs das pipelines e do backend para permitir auditoria.  
- Documente a estrutura de cada arquivo de estado em `docs/`.

## Anti‑padrões

- Utilizar variáveis globais ou arquivos temporários dispersos para controlar estado.  
- Não limpar ou atualizar estados obsoletos, levando a execuções incorretas ou reprocessamentos desnecessários.  
- Omitir registro de reprocessamentos, tornando difícil reproduzir resultados antigos.