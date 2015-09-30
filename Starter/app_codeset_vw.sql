--------------------------------------------------------------------------------
PROMPT Creating codeset view...
CREATE OR REPLACE FORCE VIEW app_codeset_vw AS
SELECT acs.codeset_id,
       acs.codeset_nm,
       acs.codeset_defn,
       acs.parent_codeset_id,
       (SELECT acsp.codeset_nm
          FROM app_codeset acsp
         WHERE acsp.codeset_id = acs.parent_codeset_id) parent_codeset_nm
  FROM app_codeset acs,
       app_vw a
 WHERE acs.active_flg = 'Y'
   AND acs.app_id = a.app_id
 ORDER BY acs.codeset_nm
--------------------------------------------------------------------------------
--Denormalizes the lookup codesets for the application mapped to the current
-- schema.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2008Mar01 Initial creation.
--------------------------------------------------------------------------------
/
