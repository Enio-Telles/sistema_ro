-- efd_c170.sql
-- grupo: core
-- dominio: EFD C170
-- objetivo: itens do documento fiscal do bloco C
-- parametros esperados: cnpj, periodo_inicio, periodo_fim
-- observacao: principal trilha de entrada para estoque
-- status: template curado para implementação no novo projeto
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

/* :cnpj :periodo_inicio :periodo_fim */
SELECT
    1 AS placeholder
FROM dual
WHERE 1 = 0;
