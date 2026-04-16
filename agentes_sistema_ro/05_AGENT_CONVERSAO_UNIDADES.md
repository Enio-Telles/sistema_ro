# 05_AGENT_CONVERSAO_UNIDADES.md

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
