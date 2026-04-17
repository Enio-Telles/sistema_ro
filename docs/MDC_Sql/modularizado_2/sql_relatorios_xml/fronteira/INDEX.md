# Índice de consultas extraídas de relatorio_fronteira.xml

| # | Consulta | Arquivo | Utilidade fiscal | Foco |
|---|---|---|---|---|
| 1 | Dossiê Fronteira 2.0 | `01_dossie_fronteira_2_0.sql` | Altíssima | Porta de entrada do dossiê, localizando comando de Fronteira por comando, motorista, placa, emitente, destinatário ou chave. |
| 2 | Destinatário(s) | `02_destinatario_s.sql` | Alta | Concentra destinatários por comando, com valor total de mercadorias. |
| 3 | Nota(s) Fiscal(is) | `03_nota_s_fiscal_is.sql` | Altíssima | Lista as notas fiscais do comando, com chave, datas, emitente, destinatário, UF, bases e valores de ICMS/ST. |
| 4 | Lançamento | `04_lancamento.sql` | Altíssima | Traz o lançamento da nota no SITAFE/Fronteira: guia, situação, valores, frete crédito, processo de suspensão e pendência. |
| 5 | Mercadoria | `05_mercadoria.sql` | Alta | Agrupa mercadorias do comando por descrição, NCM e unidade, com quantidade e valor. |
| 6 | Destino(s) | `06_destino_s.sql` | Média/Alta | Agrupa o comando por município/UF de destino, somando valor de mercadorias. |
