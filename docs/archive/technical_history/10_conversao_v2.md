# Conversão v2

## Objetivo

A conversão v2 introduz prioridade explícita entre:
1. fator estrutural
2. fator por preço
3. override manual

## Fator estrutural

A camada estrutural procura padrões simples em `descr_item` e `descr_compl`, por exemplo:
- `12x1`
- `CX 12`
- `C/12`
- `FD 6`

Quando encontra multiplicidade coerente, ela produz:
- `fator`
- `tipo_fator = estrutural`
- `confianca_fator` maior que a do fator por preço

## Fator por preço

Continua existindo como fallback quando a estrutura não puder ser inferida.

## Override manual

Continua sendo a última prioridade e substitui qualquer fator anterior.

## Log de anomalias

A conversão v2 também gera `log_conversao_anomalias` com alertas como:
- fator não positivo
- fator extremo
- mesma unidade com fator diferente de 1
- fator por preço com baixa confiança
