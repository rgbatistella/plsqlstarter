CREATE OR REPLACE FORCE VIEW app_parm_vw
BEQUEATH CURRENT_USER
AS
SELECT ap.parm_nm parm_nm,
       aep.parm_val parm_value,
       aep.hide_yn,
       ap.parm_display_nm,
       ap.parm_comments
  FROM app_env_parm aep,
       app_parm ap,
       app_env_vw aev
 WHERE aep.parm_id = ap.parm_id
   AND aep.env_id = aev.env_id
--------------------------------------------------------------------------------
--A view that self-adjusts, showing only the parameters for the current database
--and invoking schema. The Core schema should grant this view to any consuming
--schemas. The consuming schema would create a synonym to this view and then
--query it simply with SELECT * FROM app_parm_vw. The view will show only the
--parameters for that schema and database as defined by entries in app_env_parm.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2007Nov09 Initial creation.
--bcoulam      2008Aug22 Made to be self-adjusting by relying on app_env_vw.
--bcoulam      2010Apr08 Added the display name and comments columns.
--bcoulam      2014Feb04 Added BEQUEATH CURRENT_USER. View now uses invoker rights
--                       of call to ENV packaged function, and is FINALLY self-
--                       self-adjusting as advertized. No more need for after-logon
--                       triggers in accounts specified by app_db.owner_account or
--                       app_db.access_account.
--------------------------------------------------------------------------------
/
