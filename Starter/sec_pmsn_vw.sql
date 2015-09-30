CREATE OR REPLACE FORCE VIEW sec_pmsn_vw
AS
SELECT app_cd, 
       pmsn_id, 
       pmsn_nm, 
       pmsn_descr 
  FROM sec_pmsn sp, 
       app_vw   a 
 WHERE sp.app_id = a.app_id
--------------------------------------------------------------------------------
-- View to make the SEC_PMSN table more user-friendly, replacing IDs with 
-- names.
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2008Mar07 Initial creation.
--bcoulam      2008Aug26 Pointed to APP_VW to filter in only the current app's
--                       security settings.
--------------------------------------------------------------------------------
/
