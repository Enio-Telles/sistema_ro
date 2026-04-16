/*
===============================================================================
MÓDULO 15 - SEED DA MATRIZ DE COD_MOT_RES
-------------------------------------------------------------------------------
Objetivo
- Externalizar a matriz inicial usada no módulo 14 para uma tabela física.
- Facilitar governança, versionamento e aprovação pela área tributária.

Observação
- Este script NÃO é obrigatório para rodar o pacote.
- Ele existe para quando o projeto quiser sair da CTE inline e passar a manter
  a matriz em tabela versionada.
===============================================================================
*/

/* Exemplo de estrutura física */
CREATE TABLE param_matriz_cod_mot_res (
    cod_mot_res                  VARCHAR2(10)  NOT NULL,
    descricao_layout_oficial     VARCHAR2(200) NOT NULL,
    hipotese_macro               VARCHAR2(100) NOT NULL,
    ind_ressarc_st_em_tese       VARCHAR2(1)   NOT NULL,
    ind_permite_icms_proprio     VARCHAR2(1)   NOT NULL,
    exige_validacao_adicional    VARCHAR2(1)   NOT NULL,
    grau_certeza_inicial         VARCHAR2(20)  NOT NULL,
    observacao_tributaria        VARCHAR2(1000),
    dt_inicio_vigencia           DATE DEFAULT DATE '1900-01-01',
    dt_fim_vigencia              DATE,
    versao_regra                 VARCHAR2(50) DEFAULT 'v1_inicial',
    CONSTRAINT pk_param_matriz_cod_mot_res PRIMARY KEY (cod_mot_res, dt_inicio_vigencia)
);

/* Seed inicial conservador */
INSERT INTO param_matriz_cod_mot_res (
    cod_mot_res,
    descricao_layout_oficial,
    hipotese_macro,
    ind_ressarc_st_em_tese,
    ind_permite_icms_proprio,
    exige_validacao_adicional,
    grau_certeza_inicial,
    observacao_tributaria
) VALUES (
    '1',
    'SAIDA PARA OUTRA UF',
    'ART20_II_RICMS_RO',
    'S',
    'A',
    'S',
    'MEDIO',
    'Hipotese em tese alinhada ao art. 20, II, do RICMS/RO. ICMS proprio ainda depende de validacao local.'
);

INSERT INTO param_matriz_cod_mot_res VALUES (
    '2',
    'SAIDA AMPARADA POR ISENCAO OU NAO INCIDENCIA',
    'ART20_III_RICMS_RO',
    'S',
    'N',
    'N',
    'MEDIO',
    'Matriz inicial trata como vedacao ao ICMS proprio. Revisar antes de producao se houver fundamento especifico.',
    DATE '1900-01-01',
    NULL,
    'v1_inicial'
);

INSERT INTO param_matriz_cod_mot_res VALUES (
    '3',
    'PERDA OU DETERIORACAO',
    'ART20_I_RICMS_RO_EM_TESE',
    'S',
    'A',
    'S',
    'MEDIO',
    'Hipotese ligada a nao ocorrencia do fato gerador presumido. Exigir validacao juridica adicional para ICMS proprio.',
    DATE '1900-01-01',
    NULL,
    'v1_inicial'
);

INSERT INTO param_matriz_cod_mot_res VALUES (
    '4',
    'FURTO OU ROUBO',
    'ART20_I_RICMS_RO_EM_TESE',
    'S',
    'A',
    'S',
    'MEDIO',
    'Hipotese ligada a nao ocorrencia do fato gerador presumido. Manter validacao juridica adicional para ICMS proprio.',
    DATE '1900-01-01',
    NULL,
    'v1_inicial'
);

INSERT INTO param_matriz_cod_mot_res VALUES (
    '5',
    'EXPORTACAO',
    'HIPOTESE_ESPECIFICA_A_VALIDAR',
    'S',
    'A',
    'S',
    'BAIXO',
    'Codigo previsto no leiaute oficial do C176. Nao liberar ICMS proprio automaticamente sem revisao juridica.',
    DATE '1900-01-01',
    NULL,
    'v1_inicial'
);

INSERT INTO param_matriz_cod_mot_res VALUES (
    '6',
    'VENDA INTERNA PARA SIMPLES NACIONAL',
    'HIPOTESE_ESPECIFICA_A_VALIDAR',
    'S',
    'A',
    'S',
    'BAIXO',
    'Codigo previsto no leiaute oficial do C176. A matriz inicial nao libera apropriacao automatica do ICMS proprio.',
    DATE '1900-01-01',
    NULL,
    'v1_inicial'
);

INSERT INTO param_matriz_cod_mot_res VALUES (
    '9',
    'OUTROS',
    'HIPOTESE_ABERTA',
    'S',
    'A',
    'S',
    'BAIXO',
    'Codigo residual do leiaute. Exigir classificacao juridica complementar.',
    DATE '1900-01-01',
    NULL,
    'v1_inicial'
);

COMMIT;

/*
Como plugar a tabela física no módulo 14:
- substituir a CTE `matriz_elegibilidade` por um SELECT em
  `param_matriz_cod_mot_res` filtrando a vigência pertinente;
- manter os códigos marcados como "A" até aprovação formal da área tributária.
*/
