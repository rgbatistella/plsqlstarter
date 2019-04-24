CREATE OR REPLACE FORCE VIEW sec_role_pmsn_vw
AS
SELECT app_cd, 
       role_nm, 
       pmsn_nm 
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
--------------------------------------------------------------------------------
/
