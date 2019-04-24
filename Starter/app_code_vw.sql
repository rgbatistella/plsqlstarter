
--------------------------------------------------------------------------------
PROMPT Creating code view...
CREATE OR REPLACE FORCE VIEW app_code_vw AS
SELECT acs.codeset_id,
       acs.codeset_nm,
       acd.code_val,
       acd.code_id,
       acd.code_defn,
       acd.display_order,
       acd.editable_flg,
       acs.parent_codeset_id,
       (SELECT acsp.codeset_nm
          FROM app_codeset acsp
         WHERE acsp.codeset_id = acs.parent_codeset_id) parent_codeset_nm,
       acd.parent_code_id,
       (SELECT acdp.code_val
          FROM app_code acdp
         WHERE acdp.code_id = acd.parent_code_id) parent_code_val
  FROM app_code    acd,
       app_codeset acs,
       app_vw a
 WHERE acd.codeset_id = acs.codeset_id
   AND acs.active_flg = 'Y'
   AND acd.active_flg = 'Y'
   AND acs.app_id = a.app_id
 ORDER BY acs.app_id,
          acs.codeset_nm,
          acd.display_order,
          acd.code_val
--------------------------------------------------------------------------------
--Denormalizes the lookup code model into a more useable view.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2007Nov09 Initial creation.
--------------------------------------------------------------------------------
/
