/*
===============================================================================
MÓDULO 88 - RESUMO POR PERÍODO DA AUDITORIA DOCUMENTAL
-------------------------------------------------------------------------------
Objetivo
- Agregar a saída analítica por período, operação e status de cruzamento.

Granularidade
- 1 linha por período / operação / situação resumida.
===============================================================================
*/

SELECT
    NVL(efd_ref, TO_CHAR(TRUNC(dhemi, 'MM'), 'YYYY/MM')) AS periodo_referencia,
    operacao,
    data_efd_x_doc,
    tipo_dif,
    COUNT(*) AS qtd_documentos,
    SUM(NVL(tot_doc, 0)) AS soma_total_documentos,
    SUM(NVL(doc_icms, 0)) AS soma_icms_documento,
    SUM(NVL(efd_icms, 0)) AS soma_icms_efd,
    SUM(NVL(diferenca, 0)) AS soma_diferenca_icms
FROM resultado_final_auditoria_docs
GROUP BY NVL(efd_ref, TO_CHAR(TRUNC(dhemi, 'MM'), 'YYYY/MM')),
         operacao,
         data_efd_x_doc,
         tipo_dif
ORDER BY 1, 2, 3, 4;
