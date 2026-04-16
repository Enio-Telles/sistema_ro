/*
Base compartilhada de eventos de manifestação do destinatário.
Útil para enriquecer omissões de entrada e trilhas documentais.
*/
SELECT nsu AS nsu_evento,
       chave_acesso,
       evento_tpevento,
       evento_descevento,
       evento_dhevento
FROM bi.dm_eventos
WHERE evento_tpevento IN ('110111', '210220', '210240', '210200', '210210');
