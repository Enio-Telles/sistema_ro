# Documento Canônico de Arquitetura de Camadas

Em conformidade com a fundação de governança (`01_AGENT_FUNDACAO_GOVERNANCA.md`) e os princípios de execução de projeto (`AGENT_EXECUCAO_PROJETO.md`), este documento formaliza o mapeamento entre a nomenclatura histórica do repositório (`sistema_ro`) e as camadas canônicas oficiais.

Qualquer novo desenvolvimento, extração ou materialização de dataset deve obedecer à taxonomia "Camada Atualizada" descrita abaixo.

## Tabela de Mapeamento

| Nome Legado (Histórico)                 | Camada Atualizada (Oficial) | Descrição do Papel da Camada                                                                                   | Regras de Persistência |
| :-------------------------------------- | :-------------------------- | :------------------------------------------------------------------------------------------------------------- | :--------------------- |
| `bronze`                                | **`raw`**                   | Captura quase literal da origem (Oracle). Nenhuma regra analítica aplicada. Retém 1:1 o schema base.         | Imutável, particionado por versão/mês de extração. |
| `silver`                                | **`base`**                  | Limpeza primária: tipagem forte (Polars), deduplicação técnica, padronização de chaves, parsing leve de dados JSON/XML. | Consolidação por CNPJ e período. Sem regra de negócio. |
| `mdc_base`                              | **`curated` (canônica)**    | Mínimo Denominador Comum (MDC). Combinação estrutural pura, limpa e padronizada. Serve como fundação (fio de ouro).| Enriquecimento sem agregação destrutiva. Preserva ID de linha.|
| `agregacao` / `fontes_agr`              | **`curated` (derivada)**    | Modelos derivados focados no nível do domínio, cruzamentos horizontais, enriquecimento aprofundado e categorização. | Pode conter lógicas de domínio. Deriva exclusivamente de `raw` ou `base`.|
| `gold` / `gold_produtos` / `fisconforme`| **`marts` / `views`**       | Camada de consumo da regra de negócio fechada: agregações finais, sumarização, indicadores prontos para API/UI.| Resumo, otimized-for-read, sem acesso direto a origens. |

## Regra Fundamental
O fluxo canônico exige um pipeline direcional e determinístico:

`Oracle -> Raw (Bronze) -> Base (Silver) -> Curated (MDC/Agg) -> Marts (Gold/Fisconforme)`

> [!IMPORTANT]
> O princípio do "fio de ouro" (Lineage) exige que todos os parquets gerados carreguem metadados explícitos garantindo a validação desde sua extração do Raw até o consumo no Marts.
> Metadados como `upstream_datasets` e propriedades identificadoras (`dataset_id`) devem acompanhar as serializações em `pipeline/io/parquet_store.py`.
