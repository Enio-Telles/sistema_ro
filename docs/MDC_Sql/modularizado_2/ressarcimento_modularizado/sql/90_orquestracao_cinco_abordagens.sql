/*
===============================================================================
MÓDULO 90 - ORQUESTRAÇÃO DAS CINCO ABORDAGENS
-------------------------------------------------------------------------------
Objetivo
- Mostrar como a trilha documental se conecta às quatro trilhas já existentes.

Sequência sugerida
1) Trilhas 80-88 para validar completude e coerência documental.
2) Trilhas 00-15 / 40-49 / 60-69 para ressarcimento por C176 ou Fronteira.
3) Trilhas 20-29 para inventário e mudança de tributação.

Observação
- Esta orquestração é lógica. Cada módulo pode virar view, tabela temporária ou etapa ETL.
===============================================================================
*/

-- 1) Parâmetros e ajuste do tomador do CT-e.
-- CREATE OR REPLACE VIEW cte_ajuste_docs AS
-- @80_parametros_cte_tomador_docs.sql

-- 2) Universo documental do BI/XML por período.
-- CREATE OR REPLACE VIEW docs_bi_xml AS
-- @81_documentos_bi_xml_por_periodo.sql

-- 3) Base escriturada na EFD válida.
-- CREATE OR REPLACE VIEW efd_documentos_validos AS
-- @82_efd_documentos_validos.sql

-- 4) Cruzamento principal documento x EFD.
-- CREATE OR REPLACE VIEW cruzamento_docs_efd AS
-- @83_cruzamento_documentos_x_efd.sql

-- 5) Enriquecimento das omissões de entrada com manifestação.
-- CREATE OR REPLACE VIEW omissoes_eventos_manifestacao AS
-- @84_omissoes_entrada_eventos.sql

-- 6) Lookup amplo do BI/XML.
-- CREATE OR REPLACE VIEW bi_lookup_simetrico AS
-- @85_lookup_bi_xml_simetrico.sql

-- 7) Cruzamento reverso da EFD.
-- CREATE OR REPLACE VIEW efd_nao_cruzada_bi_xml AS
-- @86_efd_nao_cruzada_bi_xml.sql

-- 8) Resultado analítico final.
-- CREATE OR REPLACE VIEW resultado_final_auditoria_docs AS
-- @87_resultado_final_auditoria_docs.sql

-- 9) Resultado resumido por período.
-- CREATE OR REPLACE VIEW resumo_periodo_auditoria_docs AS
-- @88_resumo_periodo_auditoria_docs.sql
