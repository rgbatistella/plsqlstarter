CREATE OR REPLACE FORCE VIEW app_env_parm_vw
AS
SELECT aev.app_cd,
       aev.db_nm,
       aev.env_nm,
       aev.owner_account,
       ap.parm_nm,
       aep.parm_val,
       aep.hide_yn
  FROM app_env_parm  aep,
       app_env_vw    aev,
       app_parm      ap
 WHERE aep.env_id = aev.env_id
   AND aep.parm_id = ap.parm_id
--------------------------------------------------------------------------------
-- View to make the APP_ENV_PARM table more user-friendly, replacing IDs with names.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2008Mar07 Initial creation.
--------------------------------------------------------------------------------
/
