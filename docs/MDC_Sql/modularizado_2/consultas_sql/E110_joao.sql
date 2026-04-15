with 
www as (select 1 ddd,
:CNPJ cnpj,
:data_inicial data1,
:data_final data2                            from dual)
 
SELECT
        r0000.cod_fin,
        extract (year from r0000.dt_ini)||'/'|| substr (r0000.dt_ini, 4,2) ref,        
        r0000.data_entrega,      
                 LPAD(TRIM(to_char(e110.vl_tot_debitos, '999G999G999G990D00')),18) "VL DEBITOS",
                 LPAD(TRIM(to_char(e110.vl_aj_debitos, '999G999G999G990D00')),18) "VL AJ DEBITOS_DOC",
                  LPAD(TRIM(to_char(e110.vl_tot_aj_debitos, '999G999G999G990D00')),18) "VL AJ DEBITOS_APUR",
                 LPAD(TRIM(to_char(e110.vl_estornos_cred, '999G999G999G990D00')),18) "VL ESTORNOS CRED_APUR",
                 LPAD(TRIM(to_char(e110.vl_tot_creditos, '999G999G999G990D00')),18) "VL CREDITOS",
                 LPAD(TRIM(to_char(e110.vl_aj_creditos, '999G999G999G990D00')),18) "VL AJ CREDITOS_DOC",
                 LPAD(TRIM(to_char(e110.vl_tot_aj_creditos, '999G999G999G990D00')),18) "VL AJ CREDITOS_APUR",
                 LPAD(TRIM(to_char(e110.vl_estornos_deb, '999G999G999G990D00')),18) "VL ESTORNOS DEB_APUR",
                 LPAD(TRIM(to_char(e110.vl_sld_credor_ant, '999G999G999G990D00')),18) "VL SLD CREDOR ANT",
                 LPAD(TRIM(to_char(e110.vl_sld_apurado, '999G999G999G990D00')),18) "VL SLD APURADO",
                 LPAD(TRIM(to_char(e110.vl_tot_ded, '999G999G999G990D00')),18) "VL TOT DED",
                 LPAD(TRIM(to_char(e110.vl_icms_recolher, '999G999G999G990D00')),18) "VL ICMS RECOLHER",
                 LPAD(TRIM(to_char(e110.vl_sld_credor_transportar, '999G999G999G990D00')),18) "VL SLD CREDOR TRANSPORTAR",
                 LPAD(TRIM(to_char(e110.deb_esp, '999G999G999G990D00')),18) deb_esp
 
            FROM sped.reg_0000 r0000
            JOIN BI.DM_EFD_ARQUIVO_VALIDO ARQV   on  ARQV.REG_0000_ID  =  r0000.id 
            JOIN sped.reg_e110 e110    ON E110.REG_0000_ID = r0000.id 
            join www on www.ddd=1
                where
                                r0000.cnpj = www.cnpj
                                and r0000.dt_ini BETWEEN www.data1 and www.data2
 
 
order by 2 desc, 1, 3