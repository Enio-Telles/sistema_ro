--EXISTEM 143 IT_CO_SEFIN
--IT_DA_INICIO = INICIO YYYYMMDD
-- IT_DA_FINAL = FIM YYYYMMDD
WITH classif AS
(SELECT  s2.it_no_produto, 
    s1.* FROM sitafe.sitafe_produto_sefin_aux s1
LEFT JOIN sitafe.sitafe_produto_sefin s2 ON s1.it_co_sefin = s2.it_co_sefin 

)
SELECT 
n.IT_NU_NCM,
n.IT_NU_CEST,
n.it_co_sefin,
c.*

FROM sitafe.sitafe_cest_ncm n
LEFT JOIN classif c on c.it_co_sefin = n.it_co_sefin

ORDER BY n.IT_NU_NCM

--sitafe.sitafe_ncm_mercadoria
