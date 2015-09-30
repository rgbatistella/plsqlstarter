-- See if v$session is available for the ENV routines
-- get_client_program and get_os_pid, neither is possible
-- without access to v$session. Set conditional compilation
-- flag baased on its existence.

--DECLARE
--   lx_obj_unavail EXCEPTION;
--   PRAGMA EXCEPTION_INIT(lx_obj_unavail, -942);
--   l_count INTEGER := 0;
--BEGIN
--   EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM v$session' INTO l_count;
--   EXECUTE IMMEDIATE 'ALTER SESSION SET PLSQL_CCFLAGS = ''vsession_avail:true''';
--EXCEPTION
--   WHEN lx_obj_unavail THEN
--      EXECUTE IMMEDIATE 'ALTER SESSION SET PLSQL_CCFLAGS = ''vsession_avail:false''';
--END;
--/

SET DEFINE OFF

-----------------------------------------------------------
PROMPT Creating TYPES...   
@@dt_tt.tps
@@num_tt.tps
@@str_maxcol_tt.tps
@@str_maxvc2_tt.tps
@@str_obj_nm_tt.tps
@@str_sm_tt.tps
CREATE SYNONYM STR_TT for STR_MAXCOL_TT;

-----------------------------------------------------------
PROMPT Creating PACKAGES...

PROMPT cnst.pks
@@cnst.pks

PROMPT typ.pks
@@typ.pks

SET DEFINE ON
-- The name of the framework-owning schema needs to be passed into the package
-- spec to associate a constant to the previously-created application context.
PROMPT env.pks
@@env.pks
SET DEFINE OFF

PROMPT dt.pks
@@dt.pks

PROMPT parm.pks
@@parm.pks

PROMPT timer.pks
@@timer.pks

PROMPT str.pks
@@str.pks

PROMPT num.pks
@@num.pks

PROMPT api_app_log.pks
@@app_log_api.pks

PROMPT io.pks
@@io.pks

PROMPT excp.pks
@@excp.pks

PROMPT logs.pks
@@logs.pks

PROMPT timer.pkb
@@timer.pkb

PROMPT str.pkb
@@str.pkb

PROMPT num.pkb
@@num.pkb

PROMPT parm.pkb
@@parm.pkb

PROMPT api_app_log.pkb
@@app_log_api.pkb

PROMPT io.pkb
@@io.pkb

PROMPT excp.pkb
@@excp.pkb

PROMPT env.pkb
@@env.pkb

PROMPT dt.pkb
@@dt.pkb

PROMPT logs.pkb
@@logs.pkb

-----------------------------------------------------------
PROMPT Creating JOBS...
PROMPT trim_app_log.job
@@trim_app_log.job

SET DEFINE ON


