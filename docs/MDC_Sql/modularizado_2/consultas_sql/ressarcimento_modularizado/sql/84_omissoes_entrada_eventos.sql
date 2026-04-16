/*
===============================================================================
MÓDULO 84 - OMISSÕES DE ENTRADA E EVENTOS DE MANIFESTAÇÃO
-------------------------------------------------------------------------------
Objetivo
- Isolar entradas sem correspondência na EFD.
- Enriquecer essas omissões com o último evento de manifestação do destinatário.

Granularidade
- 1 linha por chave de entrada omitida.

Regra de negócio
- A manifestação é evidência auxiliar e não substitui a escrituração.
===============================================================================
*/

WITH omissao_entrada AS (
    SELECT b.chave_acesso
    FROM cruzamento_docs_efd b
    WHERE b.operacao = 'Entrada'
      AND b.data_efd_x_doc = '(Confirmar Omissao na EFD)'
),
ev_manifestacao_dest AS (
    SELECT
        o.chave_acesso,
        e.nsu AS nsu_evento,
        e.evento_tpevento,
        e.evento_descevento,
        e.evento_dhevento
    FROM omissao_entrada o
    JOIN bi.dm_eventos e
      ON e.chave_acesso = o.chave_acesso
    WHERE e.evento_tpevento IN ('110111', '210220', '210240', '210200', '210210')
),
max_ev_nota AS (
    SELECT chave_acesso, MAX(nsu_evento) AS max_nsu_evento
    FROM ev_manifestacao_dest
    GROUP BY chave_acesso
)
SELECT
    m.chave_acesso,
    e.evento_tpevento,
    e.evento_descevento,
    e.evento_dhevento
FROM max_ev_nota m
JOIN ev_manifestacao_dest e
  ON e.chave_acesso = m.chave_acesso
 AND e.nsu_evento = m.max_nsu_evento;
