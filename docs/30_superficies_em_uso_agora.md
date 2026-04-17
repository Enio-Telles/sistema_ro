# Superficies em Uso Agora

## Objetivo

Este documento substitui o uso disperso de versoes e aliases em documentos operacionais.

## Use agora

### Silver / preparo com SEFIN

- Runtime oficial: `runtime_silver_v2.py`
- Prefixo preferido:
  - `/api/v5b/silver`
- Endpoint principal:
  - `POST /api/v5b/silver/{cnpj}/prepare-sefin`

### Gold / estoque / conversao

- Runtime por versao: `runtime_gold_v20.py`
- Alias operacional preferido: `runtime_gold_current_v2.py`
- Prefixos preferidos:
  - `/api/gold20`
  - `/api/current-v2`

### Fisconforme modular

- Runtime por versao: `runtime_gold_v25.py`
- Alias operacional preferido: `runtime_gold_current_v5.py`
- Prefixos preferidos:
  - `/api/gold25/fisconforme-v2`
  - `/api/current-v5/fisconforme-v2`

## Use apenas para transicao

Estas superficies ainda podem ser usadas para comparacao tecnica controlada, mas nao devem ser tratadas como referencia principal.

- `runtime_gold_v18`
- `runtime_gold_v19`
- `runtime_gold_v21`
- `runtime_gold_v22`
- `runtime_gold_v23`
- `runtime_gold_v24`

## Nao divulgar como superficie principal

- `runtime_gold_v14`
- `runtime_gold_v15`
- `runtime_gold_v16`
- `runtime_gold_v17`
- `runtime_gold_current`
- rotas legadas de `fisconforme`

## Regra pratica

Quando houver duvida operacional:

1. usar `v5b/silver` para preparo silver com SEFIN;
2. usar `current-v2` para gold;
3. usar `current-v5/fisconforme-v2` para Fisconforme;
4. usar `main` como entrypoint de descoberta, overview e catalogo;
5. usar versoes de transicao apenas para comparacao ou migracao.

## Status resumido por CNPJ

Para orientacao operacional rapida por contribuinte, usar:

- `GET /api/current-v2/status/{cnpj}`
- `GET /api/current-v5/status/{cnpj}`
- `GET /api/current-v2/pipeline/{cnpj}/status`
- `GET /api/gold20/pipeline/{cnpj}/status`
- `GET /api/current-v5/pipeline/{cnpj}/status`
- `GET /api/gold25/pipeline/{cnpj}/status`

Esse resumo consolida:

- prontidao de referencias obrigatorias;
- prontidao minima para preparar silver;
- prontidao minima para executar gold;
- prontidao de SEFIN;
- contexto estruturado de SEFIN e referencias em runtime;
- alerta de cobertura temporal parcial quando o gold ja existe, mas ainda ha abas fiscais sem interseccao de vigencia;
- listas de pendencias por etapa;
- proxima acao recomendada;
- aliases e prefixos oficiais de gold e Fisconforme;
- superficie oficial complementar de silver com SEFIN.

Nos endpoints `pipeline/.../status`, o foco e a execucao gold oficial:

- validacao dos inputs do gold;
- origem operacional dos itens;
- contexto SEFIN usado pela execucao;
- resumo da qualidade operacional da conversao antes do `run`;
- `temporal_resolution_summary` quando `aba_mensal`, `aba_anual` e `aba_periodos` ja existem;
- `quality_attention_required` e `attention_flags` para destacar `temporal_resolution_partial`.

No `POST .../pipeline/{cnpj}/run`, o retorno tambem passa a trazer:

- `temporal_resolution_summary`;
- `quality_attention_required`;
- `attention_flags`.

Com isso, a propria execucao materializada devolve a leitura operacional da cobertura temporal do gold sem depender de consulta separada.

## Interpretacao rapida de `next_action`

- `validar_referencias`: faltam referencias obrigatorias antes de avancar.
- `carregar_silver_base`: referencias estao prontas, mas ainda faltam bases minimas.
- `preparar_silver`: ja existe carga minima e o proximo passo e consolidar silver.
- `preparar_silver_sefin`: silver para gold existe, mas ainda falta materializar `itens_unificados_sefin`.
- `executar_gold`: silver minima para gold ja existe.
- `revisar_quality`: os principais artefatos gold ja foram materializados.

Quando `next_action = revisar_quality`, vale olhar tambem `quality_attention_required` e `attention_flags`. Se houver `temporal_resolution_partial`, o proximo passo continua sendo revisar a qualidade, mas com foco nas abas fiscais com cobertura SEFIN parcial.
