CREATE OR REPLACE FORCE VIEW sec_user_app_vw
AS
SELECT a.app_cd
      ,su.user_id
      ,su.user_nm
	  ,su.pmy_email_addr
	  ,su.work_phone
  FROM sec_user_app sua
      ,sec_user     su
      ,app          a
 WHERE sua.app_id = a.app_id
   AND sua.user_id = su.user_id
--------------------------------------------------------------------------------
-- View to make the SEC_USER_APP table more user-friendly, replacing IDs with names.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2008Mar07 Initial creation.
--bcoulam      2008Aug26 Pointed to APP_VW to filter in only the current app's
--                       security settings.
--------------------------------------------------------------------------------
/
