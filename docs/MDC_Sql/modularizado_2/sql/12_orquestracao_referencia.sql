/*
===============================================================================
MÓDULO 12 - ORQUESTRAÇÃO DE REFERÊNCIA
-------------------------------------------------------------------------------
Objetivo
- Mostrar uma forma de encadear os módulos materializados.
- Este arquivo não pretende ser o pipeline definitivo.
- Ele é apenas um guia de execução.

Estratégias possíveis
1. CREATE VIEW para cada módulo.
2. Tabelas temporárias por etapa.
3. Materialização em datasets fora do Oracle.
===============================================================================

Exemplo conceitual de encadeamento:

CREATE OR REPLACE VIEW arquivos_validos AS
SELECT * FROM (
    -- conteúdo de 00_parametros_e_arquivos_validos.sql
);

CREATE OR REPLACE VIEW saidas_ressarcimento_c176 AS
SELECT * FROM (
    -- conteúdo de 01_saidas_ressarcimento_c176.sql
);

CREATE OR REPLACE VIEW produtos_saida_0200 AS
SELECT *
FROM (
    -- conteúdo do bloco PRODUTOS_SAIDA do módulo 02
)
WHERE origem_modulo = 'PRODUTOS_SAIDA';

CREATE OR REPLACE VIEW xml_saida AS
SELECT * FROM (
    -- conteúdo de 04_xml_saida.sql
);

CREATE OR REPLACE VIEW score_candidatos_vinculo AS
SELECT * FROM (
    -- conteúdo de 06_score_candidatos_vinculo.sql
);

CREATE OR REPLACE VIEW vinculo_entrada_escolhido AS
SELECT * FROM (
    -- conteúdo de 07_vinculo_entrada_escolhido.sql
);

CREATE OR REPLACE VIEW base_vinculos_e_inferencia_sefin AS
SELECT * FROM (
    -- conteúdo de 08_base_vinculos_e_inferencia_sefin.sql
);

CREATE OR REPLACE VIEW base_qtd_ressarcimento AS
SELECT * FROM (
    -- conteúdo de 09_rateio_quantidades.sql
);

CREATE OR REPLACE VIEW base_final_ressarcimento AS
SELECT * FROM (
    -- conteúdo de 10_calculos_ressarcimento.sql
);

-- Visão final item a item.
SELECT * FROM (
    -- conteúdo de 11_resultado_final_auditoria.sql
);

-- Camada jurídica adicional do ICMS próprio.
CREATE OR REPLACE VIEW base_juridica_icms_proprio AS
SELECT * FROM (
    -- conteúdo de 14_elegibilidade_icms_proprio.sql
);

-- Fechamento com o Bloco E.
SELECT * FROM (
    -- conteúdo de 13_reconciliacao_bloco_e.sql
);

Notas:
- Para produção, prefira nomes físicos com versionamento ou schema dedicado.
- Para auditoria ad hoc, views temporárias costumam ser suficientes.
- Se houver governança jurídica madura, externalize a matriz do módulo 14.
- Se houver governança de apuração madura, externalize a tabela de códigos do módulo 13.
*/
