/* ============================================================================
   106_orquestracao_seis_abordagens.sql
   ----------------------------------------------------------------------------
   Objetivo:
   - mostrar como a trilha de conciliação NFe x SITAFE/Fronteira conversa
     com as demais abordagens do pacote.

   Observação:
   - este arquivo não executa toda a lógica sozinho;
   - ele apenas registra o encadeamento recomendado.
============================================================================ */

-- 1) Materializar a origem documental da NFe de entrada interestadual.
-- create or replace view origem_nfe_fronteira_completo as
-- <conteúdo de 100_parametros_origem_nfe_fronteira_completo.sql>;

-- 2) Materializar nota + lançamento do SITAFE.
-- create or replace view base_sitafe_nota_lancamento_fronteira_completo as
-- <conteúdo de 101_base_sitafe_nota_lancamento_fronteira_completo.sql>;

-- 3) Materializar item + produto estadual + mercadoria.
-- create or replace view base_sitafe_item_mercadoria_fronteira_completo as
-- <conteúdo de 102_base_sitafe_item_mercadoria_fronteira_completo.sql>;

-- 4) Materializar o cruzamento documental e financeiro.
-- create or replace view cruzamento_nfe_sitafe_fronteira_completo as
-- <conteúdo de 103_cruzamento_nfe_sitafe_fronteira_completo.sql>;

-- 5) Produzir a visão final item a item.
-- create or replace view resultado_final_fronteira_completo as
-- <conteúdo de 104_resultado_final_fronteira_completo.sql>;

-- 6) Produzir o resumo gerencial.
-- create or replace view resumo_status_pagamento_fronteira_completo as
-- <conteúdo de 105_resumo_status_pagamento_fronteira_completo.sql>;

-- 7) Integração sugerida com as demais trilhas:
--    - abordagem 1: conferir se a nota/entrada usada no C176 tem lastro de Fronteira;
--    - abordagem 3: comparar apuração ouro unitária com valores efetivos do lançamento;
--    - abordagem 4: usar esta trilha como evolução da reconstrução histórica pré-2022;
--    - abordagem 5: usar as chaves desta trilha para aprofundar omissões documentais
--      ou diferenças entre BI/XML e EFD.
