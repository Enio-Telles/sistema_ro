# sistema_ro

Pipeline canônico de auditoria fiscal de estoque para o Estado de Rondônia
(SEFIN-RO). Reimplementação da metodologia descrita em
``metodologia_mds/`` depois da revisão crítica registrada em
[`ANALISE_METODOLOGIA.md`](ANALISE_METODOLOGIA.md).

O pacote consolida movimentações (C170, NF-e, NFC-e, Bloco H),
reconcilia estoque cronológico com custo médio ponderado e projeta as
divergências de ICMS por período, mês e ano. A integração com a base
SITAFE da SEFIN-RO cobre alíquota interna, ST vigente e MVA por
``co_sefin`` resolvido a partir de ``CEST`` e ``NCM``.

## Entregáveis

- [`ANALISE_METODOLOGIA.md`](ANALISE_METODOLOGIA.md) — auditoria da
  metodologia original: inconsistências encontradas (rótulos de
  ``tipo_operacao`` como string, fórmulas de desacobertos **invertidas**,
  fallback silencioso de ``fator_conversao``, definição circular de
  ``quantidade_convertida``, entre outras) e como foram sanadas.
- [`metodologia_revisada/`](metodologia_revisada/) — oito documentos
  (`00`–`07`) com a metodologia corrigida. `00_convencoes_gerais.md`
  define enums, sinais, fórmulas canônicas e a integração SITAFE.
- [`src/sistema_ro/`](src/sistema_ro/) — implementação Python/Polars.
- [`tests/`](tests/) — suite de 60 testes cobrindo o núcleo canônico.

## Arquitetura

```
sistema_ro/
├── enums.py           IntEnum TipoOperacao + tabela de sinais
├── schemas.py         schemas Polars de contrato
├── quantidades.py     quantidade_fisica & quantidade_fisica_sinalizada
├── agregacao.py       normalizar_descricao (idempotente),
│                      id_produto_agrupado_base (SHA1), overrides
├── conversao.py       fator_conversao com precedência e quarentena
├── movimentacao.py    montar_movimentacao_estoque (orquestra a ingestão)
├── calculo_saldo.py   saldo cronológico + custo médio + entr. desacob.
├── divergencias.py    fórmulas de desacobertos (corrigidas)
├── tabelas/
│   ├── _comum.py      expressões base_e_icms & divergencias
│   ├── periodos.py    agregação por (produto, codigo_periodo)
│   ├── mensal.py      agregação por (produto, ano, mes)
│   └── anual.py       agregação por (produto, ano)
├── validadores.py     invariantes de integridade
├── sitafe.py          integração com parquets SEFIN-RO
├── sitafe_sync.py     sincronização incremental dos parquets SITAFE
├── ingestao.py        leitores Parquet/SQL concretos para os Protocols
└── contracts/fontes.py Protocols para C170 / NF-e / NFC-e / Bloco H
```

## Fluxo canônico

1. **Fontes** → o usuário implementa `contracts.fontes` conforme seu
   ambiente (SQL, parquet, CSV).
2. **Agregação de produtos** → `agregacao.resolver_id_produto_agrupado`
   aplica overrides por precedência (`por_produto_origem` >
   `por_linha_origem` > `por_descricao`) sobre a base SHA1.
3. **Conversão de unidades** → `conversao.resolver_fator_conversao`
   aplica precedência `manual > fisico > catalogo > preco > quarentena`.
   Linhas em quarentena ficam fora do pipeline.
4. **Movimentação** →
   `movimentacao.montar_movimentacao_estoque` combina movimentos,
   inventários, mapeamento e conversão, deriva quantidades e resolve
   saldo/custo via `calculo_saldo.aplicar_saldo_e_custo`.
5. **Tabelas** → `tabelas.gerar_tabela_{periodos,mensal,anual}`
   agregam o DataFrame canônico por produto e janela temporal.
6. **Validadores** → `validadores.checar_movimentacao` +
   `checar_desacobertos_mutuamente_exclusivos` garantem as
   invariantes antes da entrega.

## Integração SITAFE

As alíquotas internas, ST e MVA por produto vêm dos cinco parquets
em `referencias/CO_SEFIN/`:

| Arquivo                          | Uso                                                                        |
| -------------------------------- | -------------------------------------------------------------------------- |
| `sitafe_cest_ncm.parquet`        | mapeamento (CEST, NCM) → `co_sefin` (mais específico)                      |
| `sitafe_cest.parquet`            | fallback CEST → `co_sefin`                                                 |
| `sitafe_ncm.parquet`             | fallback NCM → `co_sefin` (+ regulamento ST / isento)                      |
| `sitafe_produto_sefin.parquet`   | catálogo de produtos SEFIN                                                 |
| `sitafe_produto_sefin_aux.parquet` | vigência temporal: alíquota, ST, MVA, flags por UF                       |

API em `sistema_ro.sitafe`:

```python
from sistema_ro.sitafe import (
    carregar_sitafe,
    resolver_co_sefin,
    aliquotas_st_mva_para,
    parametros_fiscais_por_periodo,
)

# 1. Carga única (datas convertidas, flags S/N → bool)
sitafe = carregar_sitafe("C:/sistema_ro/referencias/CO_SEFIN")

# 2. Resolver co_sefin (precedência CEST+NCM > CEST > NCM)
produtos_co = resolver_co_sefin(produtos_df, sitafe)

# 3. Alíquota/ST/MVA em uma data de referência
tax = aliquotas_st_mva_para(
    produtos_co.select(["id_produto_agrupado", "co_sefin"]),
    sitafe,
    data_referencia="2022-12-31",
)

# 4. Materialização por período (formato consumido pelas tabelas)
aliq, st_df, mva_df = parametros_fiscais_por_periodo(
    produtos_co.select(["id_produto_agrupado", "co_sefin"]),
    sitafe,
    periodos=[("2021", "2021-12-31"), ("2022", "2022-12-31")],
    granularidade="ano",
)
g = gerar_tabela_anual(
    mov,
    aliquotas_por_produto=aliq,
    st_vigente_por_ano=st_df,
)
```

## Execução

```bash
pip install -e ".[dev]"
pytest
```

Saída esperada: `82 passed`.

## Leitores concretos (`ingestao.py`)

Dois backends cobrem os casos típicos; ambos retornam DataFrames
Polars aderentes a `SCHEMA_FONTE_MOVIMENTO` / `SCHEMA_FONTE_INVENTARIO`
(validação fail-fast no `carregar`).

```python
from sistema_ro.ingestao import (
    ParquetFonteMovimento, ParquetFonteBlocoH,
    SQLFonteMovimento, SQLFonteBlocoH, sqlite_loader,
)
from sistema_ro.contracts.fontes import FonteUnificada

# Backend Parquet canônico (dados/CNPJ/<cnpj>/fontes/*.parquet)
fontes = FonteUnificada(
    c170=ParquetFonteMovimento("dados/CNPJ", nome="c170"),
    nfe=ParquetFonteMovimento("dados/CNPJ", nome="nfe"),
    nfce=ParquetFonteMovimento("dados/CNPJ", nome="nfce"),
    bloco_h=ParquetFonteBlocoH("dados/CNPJ"),
)

# Backend SQL (SQLite, DuckDB ou qualquer callable)
loader_c170 = sqlite_loader(
    "dados/warehouse.db",
    "SELECT ... FROM c170 WHERE cnpj_titular = :cnpj",
)
fonte_c170 = SQLFonteMovimento(loader=loader_c170, rotulo="c170-warehouse")
```

## Sincronização SITAFE (`sitafe_sync.py`)

Propagação incremental do diretório fonte (mount SEFIN) para
`referencias/CO_SEFIN/`, comparando SHA-256.

```bash
python -m sistema_ro.sitafe_sync \
    /mnt/sefin-compartilhado referencias/CO_SEFIN --dry-run
```

```python
from sistema_ro.sitafe_sync import sincronizar_sitafe, StatusSincronizacao

relatorio = sincronizar_sitafe(
    fonte="/mnt/sefin-compartilhado",
    destino="referencias/CO_SEFIN",
    permitir_remocao=False,  # arquivos sumidos na fonte só aparecem no relatório
)
for item in relatorio:
    if item.status in {StatusSincronizacao.NOVO, StatusSincronizacao.ATUALIZADO}:
        print(f"{item.status.value}: {item.nome} ({item.bytes_copiados} bytes)")
```

## Validadores cruzados

Após gerar mensal e anual, confira coerência entre as tabelas antes
de entregar:

```python
from sistema_ro.validadores import (
    checar_movimentacao,
    checar_desacobertos_mutuamente_exclusivos,
    checar_consistencia_mensal_anual,
    checar_consistencia_periodos_anual,
)

for p in checar_movimentacao(mov):
    print("mov:", p)
for p in checar_consistencia_mensal_anual(mensal, anual):
    print("mensal≠anual:", p)
for p in checar_consistencia_periodos_anual(
    periodos, anual,
    mapa_periodo_ano={1: 2021, 2: 2021, 3: 2022},
):
    print("períodos≠anual:", p)
```

## Convenções não negociáveis

- `tipo_operacao` é **sempre** `IntEnum` — nunca string. Rótulos em
  `ROTULO_POR_TIPO_OPERACAO` são apenas projeção.
- `saidas_desacobertas = max(saldo_calc − declarado, 0)` e
  `estoque_final_desacoberto = max(declarado − saldo_calc, 0)` são
  **mutuamente exclusivos**. A metodologia original tinha essas
  fórmulas invertidas; a correção está verificada em
  `tests/test_divergencias.py` e `tests/test_validadores.py`.
- `custo_medio_corrente` é média ponderada em entradas e **inalterado**
  em saídas; inventário (`tipo=3`) registra estoque declarado sem
  alterar saldo nem custo.
- `fator_conversao` jamais fica com fallback silencioso `1.0`: na
  ausência de origem válida a linha vai para quarentena.
- Todos os IDs (`id_produto_agrupado_base`) são derivados
  deterministicamente via SHA1 truncado para permitir reprocessamento
  idempotente.

## Próximos passos sugeridos

1. Automatizar a execução periódica de `sitafe_sync` via agendador do SO
   (cron/Task Scheduler) apontando para o compartilhamento SEFIN
   definitivo.
2. Escrever um CLI de ponta-a-ponta (`python -m sistema_ro.pipeline
   --cnpj ...`) que encadeie: ingestão → `montar_movimentacao_estoque`
   → tabelas → validadores → persistência em
   `analises/produtos/*.parquet`.
3. Expandir a suíte de testes com um caso baseado em dados sintéticos
   multianuais (múltiplos produtos, devoluções, inventários intermediários)
   para validar numericamente `checar_consistencia_mensal_anual` ponta a
   ponta contra o pipeline completo.
