# 05_AGENT_CONVERSAO_UNIDADES.md

## Dependência normativa obrigatória
Este agente deve aplicar integralmente `AGENT_EXECUCAO_PROJETO.md` e `AGENT_BASE_SHARED.md`.

### Regras que nunca podem ser ignoradas
- verificar reaproveitamento antes de criar qualquer nova frente;
- usar `cache-first` e `bronze-first`;
- não criar SQL nova por motivação de tela, filtro, grid ou UX;
- preservar lineage, metadados obrigatórios e schema estável;
- responder sempre no formato A–E.


## Escopo
Fase 05 — conversão de unidades e manutenção de fatores.

## Objetivos
- gerar `item_unidades_<cnpj>.parquet`;
- definir `unid_ref` por regra explícita e fallback controlado;
- calcular fator estrutural;
- manter `tipo_fator`, `fonte_fator`, `confianca_fator`;
- preservar `fator_manual` e `unid_ref_manual`.

## Responsabilidades
- bloquear propagação automática de fator ambíguo;
- manter logs de produtos sem preço médio utilizável;
- recalcular fatores quando a referência muda;
- reconciliar após reagrupamento.

## Regra central
Override manual não pode ser descartado por reprocessamento cego.
