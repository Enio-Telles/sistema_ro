Este diretório contém a modularização da query original.

Há três estilos de módulo aqui:
1. Módulos iniciais mais autônomos, com CTEs próprias;
2. Módulos posteriores que assumem entidades upstream materializadas
   (views, tabelas temporárias ou datasets) com nomes lógicos;
3. Módulos jurídicos/finais que pressupõem parametrização da área tributária.

Nomes lógicos esperados nos módulos posteriores:
- saidas_ressarcimento_c176
- produtos_saida_0200
- xml_saida
- vinculo_entrada_escolhido
- base_vinculos_e_inferencia_sefin
- base_qtd_ressarcimento
- base_final_ressarcimento
- base_juridica_icms_proprio (opcional, quando o módulo 14 for materializado)

Esses nomes podem ser implementados como:
- CREATE VIEW ...
- tabelas temporárias
- datasets Parquet lidos fora do Oracle
- CTEs encadeadas em uma versão orquestrada

Ordem prática sugerida de uso:
1. 00 a 11 para a trilha documental e analítica do item;
2. 14 para elegibilidade jurídica do ICMS próprio;
3. 13 para reconciliação com o Bloco E;
4. materialização final para relatório, UI ou malha.

A ideia do pacote é preservar a rastreabilidade da regra, e não impor um único modelo de execução.


BLOCO DE RELATÓRIOS XML EXTRAÍDOS
- sql_relatorios_xml/efd_master: consultas extraídas do relatório EFD Master.
- sql_relatorios_xml/fronteira: consultas extraídas do dossiê Fronteira.
- Esses arquivos preservam a lógica de relatório/orquestração original e devem ser lidos como consultas de navegação auditável, não como trilhas completas de cálculo.

BLOCO MDC (MÍNIMO DENOMINADOR COMUM)
- sql_mdc: consultas-base canônicas para regenerar as famílias analisadas.
- A intenção do MDC não é substituir os módulos específicos, mas fornecer a
  base comum da qual os módulos específicos podem derivar.
- Preferência arquitetural: novos relatórios devem começar do MDC e só depois
  aplicar regras específicas (score, PEPS/FIFO, elegibilidade, HTML de UI etc.).
