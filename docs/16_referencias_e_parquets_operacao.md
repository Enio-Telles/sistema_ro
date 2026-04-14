# Referências e Parquets — guia operacional

## Objetivo

Este documento explica, de forma operacional, como as referências e os arquivos Parquet entram no `sistema_ro`, onde eles devem existir em runtime, quais são obrigatórios e quais enriquecimentos dependem deles.

---

## 1. Conceito importante

No estado atual do projeto, existem **dois papéis diferentes** para `references/`:

### 1.1 `references/` no repositório Git
A pasta versionada no repositório tem função principalmente documental:
- manifesto das referências esperadas;
- descrição do papel de cada arquivo;
- orientação de atualização.

### 1.2 `workspace/references/` em runtime
O código do projeto usa `reference_dir()` para resolver as referências em tempo de execução.
Na prática, isso significa que os Parquets de referência precisam existir em:

```text
<WORKSPACE_ROOT>/references/
```

Por padrão:

```text
./workspace/references/
```

---

## 2. Arquivos de referência obrigatórios

Os arquivos esperados pelo projeto atualmente são:

- `sitafe_cest.parquet`
- `sitafe_cest_ncm.parquet`
- `sitafe_ncm.parquet`
- `sitafe_produto_sefin.parquet`
- `sitafe_produto_sefin_aux.parquet`

### 2.1 Papel de cada arquivo

#### `sitafe_cest_ncm.parquet`
Melhor correspondência fiscal auxiliar.
Usado para inferência mais forte por combinação `CEST + NCM`.

#### `sitafe_cest.parquet`
Fallback por `CEST` quando a combinação ideal não existe.

#### `sitafe_ncm.parquet`
Fallback por `NCM` quando a inferência por `CEST + NCM` e por `CEST` não resolve.

#### `sitafe_produto_sefin.parquet`
Tabela de descrição e identificação do `co_sefin`.
Ajuda a enriquecer semanticamente o item classificado.

#### `sitafe_produto_sefin_aux.parquet`
Tabela histórica de vigência.
É a base para anexar parâmetros por data de operação.

---

## 3. Integração atual no código

### 3.1 Loader das referências
O projeto já possui loader de referências em `pipeline/references/loaders.py`.
Ele:
- resolve os nomes esperados;
- valida a existência do arquivo;
- lê o Parquet com Polars.

### 3.2 Enriquecimento SEFIN
O projeto já possui integração prática de referências em `pipeline/references/enrichment.py`.
Esse enriquecimento:
- usa `infer_co_sefin(...)`;
- aplica `attach_sefin_vigencia(...)`;
- usa `dt_e_s` ou `dt_doc` como `data_ref`.

### 3.3 Preparação da silver enriquecida
A preparação enriquecida da silver já existe em `backend/app/services/silver_base_v2_service.py`.
Esse serviço:
- gera `itens_unificados`;
- gera `base_info_mercadorias`;
- tenta gerar `itens_unificados_sefin`;
- continua o fluxo mesmo se as referências não estiverem disponíveis.

---

## 4. Parquets do projeto por camada

## 4.1 Silver mínima
Esses datasets são base operacional para executar o gold:

- `silver/efd_c170_<cnpj>.parquet`
- `silver/nfe_itens_<cnpj>.parquet`
- `silver/nfce_itens_<cnpj>.parquet` (opcional)
- `silver/bloco_h_<cnpj>.parquet` (opcional)
- `silver/itens_unificados_<cnpj>.parquet`
- `silver/base_info_mercadorias_<cnpj>.parquet`
- `silver/itens_unificados_sefin_<cnpj>.parquet` (quando houver referências carregadas)

## 4.2 Gold principal
Esses datasets já são produzidos pelas execuções gold:

- `gold/produtos_agrupados_<cnpj>.parquet`
- `gold/id_agrupados_<cnpj>.parquet`
- `gold/produtos_final_<cnpj>.parquet`
- `gold/item_unidades_<cnpj>.parquet`
- `gold/fatores_conversao_<cnpj>.parquet`
- `gold/log_conversao_anomalias_<cnpj>.parquet`
- `gold/mov_estoque_<cnpj>.parquet`
- `gold/aba_mensal_<cnpj>.parquet`
- `gold/aba_anual_<cnpj>.parquet`
- `gold/aba_periodos_<cnpj>.parquet`
- `gold/estoque_resumo_<cnpj>.parquet`
- `gold/estoque_alertas_<cnpj>.parquet`

## 4.3 Fisconforme
- `fisconforme/fisconforme_cadastral_<cnpj>.parquet`
- `fisconforme/fisconforme_malhas_<cnpj>.parquet`

---

## 5. O que depende das referências

### 5.1 Depende diretamente das referências
- `itens_unificados_sefin`
- inferência de `co_sefin`
- enriquecimento por vigência histórica
- futura melhora de parâmetros fiscais por data

### 5.2 Não depende diretamente das referências
- geração de `itens_unificados`
- geração de `base_info_mercadorias`
- agregação de mercadorias
- cálculo de fatores por preço
- override manual
- primeira execução de estoque

Isso significa que o projeto continua rodando sem as referências, mas com menor riqueza fiscal.

---

## 6. Comportamento quando faltam referências

No fluxo atual:
- a preparação da silver enriquecida tenta usar as referências;
- se elas não estiverem presentes, o fluxo não para;
- o projeto persiste ao menos a silver-base (`itens_unificados` e `base_info_mercadorias`).

Consequência prática:
- o pipeline continua utilizável;
- mas sem `itens_unificados_sefin` e sem enriquecimento por vigência.

---

## 7. Integração real vs integração documental

## 7.1 Integração real já existente
- loader de referências;
- enriquecimento de itens com SEFIN;
- persistência de `itens_unificados_sefin`;
- uso intensivo de Parquet em silver/gold/fisconforme.

## 7.2 Integração ainda incompleta
- validação explícita de que as referências obrigatórias estão presentes antes do enriquecimento;
- uso sistemático de `itens_unificados_sefin` como entrada preferencial do gold;
- exposição por API do status das referências carregadas;
- documentação mais forte de origem/checksum/data de carga das referências.

---

## 8. Fluxo operacional recomendado

### Fluxo sem enriquecimento fiscal
1. carregar `efd_c170`, `nfe_itens`, `nfce_itens`, `bloco_h` em silver;
2. chamar `POST /api/v5/silver/{cnpj}/prepare`;
3. chamar `POST /api/v6b/pipeline/{cnpj}/run`.

### Fluxo com enriquecimento fiscal
1. garantir os cinco Parquets de referência em `workspace/references/`;
2. carregar `efd_c170`, `nfe_itens`, `nfce_itens`, `bloco_h` em silver;
3. chamar `POST /api/v5b/silver/{cnpj}/prepare-sefin`;
4. verificar `silver/itens_unificados_sefin_<cnpj>.parquet`;
5. chamar `POST /api/v6b/pipeline/{cnpj}/run`.

---

## 9. Checklist operacional

### Antes de rodar a silver enriquecida
- [ ] `WORKSPACE_ROOT` definido corretamente
- [ ] `workspace/references/` existente
- [ ] cinco Parquets de referência presentes
- [ ] datasets silver-base do CNPJ carregados

### Antes de rodar o gold
- [ ] `itens_unificados_<cnpj>.parquet` presente
- [ ] `base_info_mercadorias_<cnpj>.parquet` presente
- [ ] `fatores_conversao` e `overrides` avaliados conforme necessidade
- [ ] bloco H presente quando a análise exigir inventário

---

## 10. Melhorias recomendadas

- criar endpoint de diagnóstico das referências carregadas;
- validar schema mínimo de cada Parquet de referência;
- registrar checksum, data de carga e origem das referências;
- priorizar `itens_unificados_sefin` como insumo preferencial do gold quando existir;
- adicionar testes que simulem ausência e presença parcial das referências.
