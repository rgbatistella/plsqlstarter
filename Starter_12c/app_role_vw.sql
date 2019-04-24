CREATE OR REPLACE VIEW app_role_vw
BEQUEATH CURRENT_USER
AS
SELECT role_id,
       role_nm,
       role_descr
  FROM sec_role ar,
       app_vw av
 WHERE av.app_id = ar.app_id
--------------------------------------------------------------------------------
--A view that self-adjusts, showing only the roles for the current database
--and invoking schema. The Core schema should grant this view to any consuming
--schemas. The consuming schema would create a synonym to this view and then
--query it simply with SELECT * FROM app_role_vw.
--
--Artisan      Date      Comments
--============ ========= ======================================================
--bcoulam      2007Nov09 Initial creation.
--bcoulam      2014Feb04 Added BEQUEATH CURRENT_USER. View now uses invoker rights
--                       of call to ENV packaged function, and is FINALLY self-
--                       self-adjusting as advertized. No more need for after-logon
--                       triggers in accounts specified by app_db.owner_account or
--                       app_db.access_account.
--------------------------------------------------------------------------------
/
