CREATE OR REPLACE FORCE VIEW app_vw
BEQUEATH CURRENT_USER
AS
SELECT app_id,
       app_cd,
       app_nm,
       app_descr
  FROM app
 WHERE app_id = env.get_app_id
--------------------------------------------------------------------------------
--View that determines which application is calling upon Core components. This 
--view does not work if app_env and app_db are not set up properly, with data
--for each application, database and environment. It also does not work if 
--multiple applications share the same schema. If you have multiple apps sharing
--the same schema, you will need to hardcode your application ID or code in
--PL/SQL and views that make use of the Core components that need to know which
--app you are.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2007Nov09 Initial creation.
--bcoulam      2008Aug22 Rewrote to make use of more flexible logic in 
--                       env.get_app_id.
--bcoulam      2014Feb04 Added BEQUEATH CURRENT_USER. View now uses invoker rights
--                       of call to ENV packaged function, and is FINALLY self-
--                       self-adjusting as advertized. No more need for after-logon
--                       triggers in accounts specified by app_db.owner_account or
--                       app_db.access_account.
-------------------------------------------------------------------------------- 
/
