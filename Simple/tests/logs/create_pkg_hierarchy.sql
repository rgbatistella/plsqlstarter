DROP TABLE test_uid PURGE;
CREATE TABLE test_uid (
 ID NUMBER CONSTRAINT test_uid_id_nn NOt NULL
,CONSTRAINT test_uid_pk PRIMARY KEY (ID)
);
INSERT INTO test_uid VALUES (1);
COMMIT;

--------------------------------------------------------------------------------
-- This set of packages is meant to test a fairly typical set of nested, 
-- dependent calls that can happen in an environment where a client calls a
-- backend proc that then calls upon other procs for help and service only
-- to get an error deep in the call tree. We want the new 10g backtrace to tell
-- exactly where the error happened.
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE top AS
   PROCEDURE proc(i_str IN VARCHAR2);
END top;
/

--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE middle AS
   PROCEDURE proc(i_str IN VARCHAR2);
END middle;
/

--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE bottom AS
   PROCEDURE proc
   (
      i_str  IN VARCHAR2,
      i_line IN NUMBER
   );
END bottom;
/

--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY top AS
   PROCEDURE proc(i_str IN VARCHAR2) IS
   BEGIN
      env.init_client_ctx(i_client_id => 'bcoulam');

      dbms_output.put_line(RPAD('-',cnst.pagewidth,'-'));
      dbms_output.put_line('--------- Called for ['||i_str||']');
      IF (i_str = 'dbg') THEN
         logs.set_dbg(i_dbg_val => 'unit=BOTTOM,MIDDLE,TOP');
      END IF;

      logs.dbg('Calling middle.proc');      
      middle.proc(i_str);
      logs.dbg('Processing of middle.proc done.');

      IF (i_str = 'dbg') THEN
         logs.set_dbg('off');
      END IF;
   END proc;
END top;
/

--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY middle AS
   PROCEDURE proc(i_str IN VARCHAR2) IS
      -- this is only meant to test inner routines, and how they bugger up env.caller_meta
--      FUNCTION get_line RETURN NUMBER IS
--      BEGIN
--         logs.dbg('Inside middle.proc.get_line');
--         RETURN $$PLSQL_LINE;
--      END get_line;
--      -- this is only meant to test inner routines   
--      FUNCTION get_str RETURN VARCHAR2 IS
--      BEGIN
--         logs.dbg('Inside middle.proc.get_str');
--         RETURN i_str;
--      END get_str;
   BEGIN
      logs.dbg('Calling bottom.proc');
--      bottom.proc(get_str, get_line);
      bottom.proc(i_str, $$PLSQL_LINE);
      logs.dbg('Processing of bottom.proc done.');
   END proc;
END middle;
/

--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY bottom
AS

PROCEDURE proc    (i_str IN VARCHAR2, i_line IN NUMBER) IS
   lx EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx, -0922);
   
   lx_bogus_value EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_bogus_value, -20001);
   
   -- This inner routine is here to replicate the bug where env.caller_meta
   -- is unable to determine the package.proc due to the inner routine
--   PROCEDURE bogus_priv_proc (i_str IN VARCHAR2) IS
--   BEGIN
--      dbms_output.put_line('bogus_priv_proc: '||i_str);
--   END bogus_priv_proc;
BEGIN
   /* TEST PLAN:
      From bottom of package hierarchy, see effect on logged package/routine and stack trace:
      
      logs.info
      logs.warn
      logs.err (no args) -- SQLCODE, SQLERRM, re-raise
      logs.err (msg) -- Oracle error, re-raise
      logs.err (msg) -- User-defined error, re-raise
      logs.err (msg) -- Oracle error, suppress
      logs.err (msg) -- User-defined error, suppress

      logs.err -- raised, uncaught, but caught and logged by middle
      logs.err -- raised, caught by bottom.proc block
      logs.err -- raised, caught by inner block inside bottom.proc
  */

   -- dip into another sub-level       
   --bogus_priv_proc(i_str);

   logs.dbg('BEGIN - Decision tree in bottom.proc');
   
   IF (i_str = 'call stack') THEN
      dbms_output.put_line(dbms_utility.format_call_stack);
   ELSIF (i_str = 'call stack - error') THEN
      BEGIN
         RAISE NO_DATA_FOUND;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            dbms_output.put_line(dbms_utility.format_error_stack);
            dbms_output.put_line(dbms_utility.format_call_stack);
      END;
   ELSIF (i_str = 'backtrace(raw)') THEN
      BEGIN
         INSERT INTO test_uid VALUES (1);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN
            dbms_output.put_line('ERROR: Unique Constraint Violation Detected');
            dbms_output.put_line('----- PL/SQL Backtrace -----'||CHR(10)||dbms_utility.format_error_backtrace);
            RAISE;
      END;
   ELSIF (i_str = 'backtrace') THEN
      BEGIN
         INSERT INTO test_uid VALUES (1);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN
            logs.err;
      END;
   ELSIF (i_str = 'raise(oracle)') THEN
      BEGIN
         INSERT INTO test_uid VALUES (1);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN
            logs.err(NULL,FALSE);
            RAISE;
      END;
   ELSIF (i_str = 'raise_proc(oracle)') THEN
      BEGIN
         INSERT INTO test_uid VALUES (1);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN
            logs.err(SQLERRM,FALSE);
            raise_app_err('Row already exists in TEST_UID.',SQLCODE);
      END;
   ELSIF (i_str = 'raise_proc(ude)') THEN
      BEGIN
         RAISE lx_bogus_value;
      EXCEPTION
         WHEN lx_bogus_value THEN
            logs.err('Bogus value detected.',FALSE);
            raise_app_err('Bogus value detected. Halting program...');
      END;
   ELSIF (i_str = 'info') THEN
      logs.info('Testing logs.info from bottom.proc');
   ELSIF (i_str = 'warn') THEN
      logs.warn('Testing logs.warn from bottom.proc');
   ELSIF (i_str = 'dbg') THEN
      FOR i IN 1..5 LOOP
         logs.dbg('Debugging from '||$$PLSQL_UNIT);
      END LOOP;   
   ELSIF (i_str = 'err(oracle,reraise)') THEN
      BEGIN
         RAISE lx;
      EXCEPTION
         WHEN lx THEN
            logs.err(SQLERRM);
      END;
   ELSIF (i_str = 'err(ude,reraise)') THEN
      BEGIN
         RAISE lx_bogus_value;
      EXCEPTION
         WHEN lx_bogus_value THEN
            logs.err('Bogus value detected. Halt processing.');
      END;
   ELSIF (i_str = 'err(oracle,suppress)') THEN
      BEGIN
         RAISE lx;
      EXCEPTION
         WHEN lx THEN
            logs.err(SQLERRM,FALSE);
      END;
   ELSIF (i_str = 'err(ude,suppress)') THEN
      BEGIN
         RAISE lx_bogus_value;
      EXCEPTION
         WHEN lx_bogus_value THEN
            logs.err('Bogus value detected. Log and continue.',FALSE);
      END;
   ELSIF (i_str = 'raise(uncaught)') THEN
      RAISE NO_DATA_FOUND;
   ELSIF (i_str = 'raise(caught-main block)') THEN
      -- also exercises the condition of logging an error message with no args
      RAISE TOO_MANY_ROWS;
   ELSIF (i_str = 'raise(caught-inner block)') THEN
      BEGIN
         RAISE NO_DATA_FOUND;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            logs.err;
      END;
   ELSIF (i_str = 'err - twice in a row') THEN
      DECLARE
      BEGIN
         RAISE lx;
      EXCEPTION
         WHEN lx THEN
            logs.err(i_msg => 'Saying something about the context of this error', i_reraise => FALSE);
            --dbms_output.put_line(dbms_utility.format_error_backtrace);
            logs.err('My error message',TRUE);
      END;
   END IF;
   logs.dbg('END - End of decision tree for bottom.proc');
EXCEPTION
   WHEN TOO_MANY_ROWS THEN
      logs.err;
END proc;

END bottom;
/

DECLARE
BEGIN
   DELETE FROM app_log;
   env.reset_client_ctx;
   COMMIT;
END;
/
SET SERVEROUTPUT ON
EXEC top.proc('info');
SET SERVEROUTPUT ON
EXEC top.proc('warn');
SET SERVEROUTPUT ON
EXEC top.proc('dbg');
SET SERVEROUTPUT ON
EXEC top.proc('err(oracle,reraise)');
SET SERVEROUTPUT ON
EXEC top.proc('err(ude,reraise)');
SET SERVEROUTPUT ON
EXEC top.proc('err(oracle,suppress)');
SET SERVEROUTPUT ON
EXEC top.proc('err(ude,suppress)');
SET SERVEROUTPUT ON
EXEC top.proc('raise(uncaught)');
SET SERVEROUTPUT ON
EXEC top.proc('raise(caught-main block)');
SET SERVEROUTPUT ON
EXEC top.proc('raise(caught-inner block)');
SET SERVEROUTPUT ON
EXEC top.proc('err - twice in a row');
SET SERVEROUTPUT ON
EXEC top.proc('backtrace(raw)');
SET SERVEROUTPUT ON
EXEC top.proc('backtrace');
SET SERVEROUTPUT ON
EXEC top.proc('raise(oracle)');
SET SERVEROUTPUT ON
EXEC top.proc('raise_proc(oracle)');
SET SERVEROUTPUT ON
EXEC top.proc('raise_proc(ude)');

