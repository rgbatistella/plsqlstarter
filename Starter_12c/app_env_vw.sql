CREATE OR REPLACE FORCE VIEW app_env_vw
BEQUEATH CURRENT_USER
AS
SELECT app.app_cd,
       ae.env_nm,
       adb.db_nm,
       adb.db_alias,
       ae.owner_account,
       ae.access_account,
       app.app_id,
       app.app_nm,
       ae.app_version,
       ae.env_id,
       adb.db_id
  FROM app_env ae,
       app_vw  app,
       app_db  adb
 WHERE ae.app_id = app.app_id
   AND ae.db_id = adb.db_id
   AND adb.db_nm = UPPER(SYS_CONTEXT('userenv', 'con_name'))
   AND ae.owner_account = SYS_CONTEXT('userenv', 'current_schema')
--------------------------------------------------------------------------------
-- View to make the APP_ENV table more user-friendly, replacing IDs with names.
-- A view that self-adjusts, showing only the environment for the current database
-- and invoking schema. The Core schema should grant this view to any consuming
-- schemas. The consuming schema would create a synonym to this view and then
-- query it simply with SELECT * FROM app_env_vw.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2008Mar07 Initial creation.
--bcoulam      2008Aug22 Made self-adjusting.
--bcoulam      2014Feb04 Added BEQUEATH CURRENT_USER. View now uses invoker rights
--                       of call to ENV packaged function, and is FINALLY self-
--                       self-adjusting as advertized. No more need for after-logon
--                       triggers in accounts specified by app_db.owner_account or
--                       app_db.access_account.
--------------------------------------------------------------------------------
/
