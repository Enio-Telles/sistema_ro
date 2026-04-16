# Núcleo de mínimo denominador comum (MDC)

Este diretório contém as consultas-base a partir das quais é possível remontar,
com combinações e agregações, as famílias de consultas analisadas na conversa.

Princípios do MDC:
1. cada consulta representa uma camada canônica do problema;
2. o MDC evita lógica de apresentação e HTML de relatório;
3. o MDC separa prova documental, apuração, Fronteira, inventário e dossiê;
4. consultas derivadas devem preferir `JOIN` sobre o MDC, em vez de voltar ao
   dado cru em cada relatório.

Blocos:
- 00 a 04: parâmetros, contribuinte, EFD válida, participantes e produtos;
- 05 a 11: escrituração EFD documental, ressarcimento, inventário e apuração;
- 12 a 19: BI/XML, SITAFE/Fronteira, dimensões fiscais e rateio de frete;
- 20 a 22: núcleo fiscal-cadastral dos dossiês;
- 23: orquestração de referência.
- 24: diagnóstico de necessidade de conversão de unidade.
