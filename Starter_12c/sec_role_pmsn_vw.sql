CREATE OR REPLACE VIEW sec_role_pmsn_vw
BEQUEATH CURRENT_USER
AS
SELECT a.app_cd,
       sr.role_nm,
       sp.pmsn_nm
  FROM sec_role_pmsn srp, 
       sec_role      sr, 
       sec_pmsn      sp, 
       app_vw        a 
 WHERE srp.role_id = sr.role_id 
   AND srp.pmsn_id = sp.pmsn_id 
   AND sr.app_id = a.app_id
--------------------------------------------------------------------------------
-- View to make the SEC_ROLE_PMSN table more user-friendly, replacing IDs with 
-- names.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2008Mar07 Initial creation.
--bcoulam      2008Aug26 Pointed to APP_VW to filter in only the current app's
--                       security settings.
--bcoulam      2014Feb04 Added BEQUEATH CURRENT_USER. View now uses invoker rights
--                       of call to ENV packaged function, and is FINALLY
--                       self-adjusting as advertized. No more need for after-logon
--                       triggers in accounts specified by app_db.owner_account or
--                       app_db.access_account.
--------------------------------------------------------------------------------
/
