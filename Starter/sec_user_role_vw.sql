CREATE OR REPLACE VIEW sec_user_role_vw
AS
SELECT a.app_cd,
       sur.user_id,
       su.user_nm,
       sr.role_id,
       sr.role_nm
  FROM sec_user_role sur,
       sec_user      su,
       sec_role      sr,
       app_vw        a
 WHERE sur.user_id = su.user_id
   AND sur.role_id = sr.role_id
   AND sr.app_id = a.app_id
--------------------------------------------------------------------------------
-- View to make the SEC_USER_ROLE table more user-friendly, replacing IDs with 
-- names.
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2008Mar07 Initial creation.
--bcoulam      2008Aug26 Pointed to APP_VW to filter in only the current app's
--                       security settings.
--------------------------------------------------------------------------------;
/

