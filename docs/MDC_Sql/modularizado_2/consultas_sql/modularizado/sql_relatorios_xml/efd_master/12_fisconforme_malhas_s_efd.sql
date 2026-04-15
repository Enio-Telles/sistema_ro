-- Origem: EFD_master.xml
-- Título no relatório: Fisconforme (malhas s / EFD)
-- Caminho no XML: EFD Master 2.0 > Fisconforme (malhas s / EFD)
-- Utilidade fiscal: Alta
-- Foco: Situação de pendências/malhas por período e status, vinculadas a conjuntos específicos de malhas.
-- Uso sugerido: Excelente trilha de risco e priorização: mostra onde já há questionamento institucional sobre EFD ou comportamento fiscal correlato.
-- Riscos/Limites: Malha não é prova definitiva de infração; é sinalizador de risco e workflow administrativo.
-- Tabelas/fontes identificadas: app_pendencia.pendencias, app_pendencia.malhas
-- Binds declarados: CNPJ_CPF, DATA_INICIAL, DATA_FINAL

SELECT
    t.id notificacao,
    t.malhas_id,
    m.titulo,
    t.periodo,
    CASE WHEN t.status = 0 THEN
            '<html><strong><font color="red">0 - Pendente'
        WHEN t.status = 1    THEN
            '<html><strong><font color="orange">1 - Contestado'
        WHEN t.status = 2    THEN
            '<html><strong><font color="blue">2 - Resolvido'
        WHEN t.status = 4    THEN
            '<html><strong><font color="red">4 - Indeferido'
        WHEN t.status = 5    THEN
            '<html><strong><font color="blue">5 - Deferido'
        WHEN t.status = 7    THEN
            '<html><strong><font color="blue">7 - Deferido Automaticamente'
        ELSE
            to_char(t.status)
    END status
FROM
    app_pendencia.pendencias    t
    LEFT JOIN app_pendencia.malhas        m ON t.malhas_id = m.id
WHERE
    t.cpf_cnpj = :CNPJ_CPF
    AND to_date(t.periodo, 'YYYYMM') BETWEEN :DATA_INICIAL AND :DATA_FINAL 
    AND t.malhas_id IN ( '10380', '10420', '10440', '10400', '10500',
                     '10140', '10061', '10020', '10180', '10200',
                     '10120', '10040', '10060', '10100',
                     '10240',
                     '10260',
                     '10320',
                     '10360' )
ORDER BY decode(t.status, 0, 1, 4, 2,
                                               1, 3, 2, 4, 5,
                                               4, 7, 4, NULL, 4),
t.periodo DESC
