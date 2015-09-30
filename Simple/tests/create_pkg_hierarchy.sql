CREATE OR REPLACE PACKAGE top
AS
PROCEDURE proc(i_str IN VARCHAR2);
END top;
/

CREATE OR REPLACE PACKAGE middle
AS
PROCEDURE proc(i_str IN VARCHAR2);
END middle;
/

CREATE OR REPLACE PACKAGE bottom
AS
PROCEDURE proc(i_str IN VARCHAR2, i_line IN NUMBER);
PROCEDURE bogus_pub_proc;
-- testing user_arguments with an overload
PROCEDURE bogus_pub_proc(i_str IN VARCHAR2);
PROCEDURE err_in_excp;
END bottom;
/

CREATE OR REPLACE PACKAGE BODY top
AS
PROCEDURE proc(i_str IN VARCHAR2) IS
BEGIN
   middle.proc(i_str);
EXCEPTION 
   WHEN NO_DATA_FOUND THEN
      logs.info('Caught NO_DATA_FOUND in middle.');
END proc;
END top;
/
CREATE OR REPLACE PACKAGE BODY middle
AS
PROCEDURE proc(i_str IN VARCHAR2) IS
   -- this is only meant to test inner routines, not accuracy of $$PLSQL_LINE
   FUNCTION get_line RETURN NUMBER IS BEGIN RETURN $$PLSQL_LINE; END get_line;
   -- this is only meant to test inner routines   
   FUNCTION get_str RETURN VARCHAR2
   IS
   BEGIN 
      RETURN i_str;
   END get_str;
BEGIN
   bottom.proc(get_str, get_line);
END proc;
END middle;
/
CREATE OR REPLACE PACKAGE BODY bottom
AS
PROCEDURE bogus_priv_proc (i_str IN VARCHAR2) IS
BEGIN
   dbms_output.put_line(i_str);
END bogus_priv_proc;

PROCEDURE proc    (i_str IN VARCHAR2, i_line IN NUMBER) IS
   l_owner VARCHAR2(30);
   l_obj_type VARCHAR2(20);
   l_unit_name VARCHAR2(30);
   l_routine_nm VARCHAR2(30);
   l_line_num INTEGER;
   lx EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx, -0922);
BEGIN

   bogus_priv_proc(i_str);
   
   IF (i_str = 'excp.throw') THEN
      excp.throw(5000,'Super important error from bottom.proc');
   ELSIF(i_str = 'excp.throw(ORA)') THEN
      excp.throw(-12574);
   ELSIF (i_str = 'SQLCODE') THEN
      RAISE TOO_MANY_ROWS;
   ELSIF (i_str = 'raise') THEN
      raise_application_error(-20000,'Error raised by RAISE_APPLICATION_ERROR');
   ELSIF (i_str = 'backtrace') THEN
      BEGIN
         RAISE TOO_MANY_ROWS;
      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            IF (env.get_db_version >= 10) THEN
               dbms_output.new_line;
               dbms_output.put_line('Backtrace Stack');
               dbms_output.put_line('--------------------------------------------------------------------------------');
               --dbms_output.put_line(DBMS_UTILITY.format_error_backtrace);
               dbms_output.new_line;
               logs.err('Failed during proc(backtrace)',TRUE);
            ELSE
               dbms_output.new_line;
               dbms_output.put_line('Backtrace Stack');
               dbms_output.put_line('--------------------------------------------------------------------------------');
               ---io.p(DBMS_UTILITY.format_error_backtrace);
               dbms_output.new_line;
            END IF;
      END;
   ELSIF (i_str = 'env') THEN   
      IF (env.get_db_version >= 10) THEN
         dbms_output.new_line;
         dbms_output.put_line('Call Stack');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.put_line(DBMS_UTILITY.format_call_stack);
         dbms_output.new_line;
         dbms_output.put_line('ENV.WHO_AM_I');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         dbms_output.put_line(env.who_am_i);
         dbms_output.new_line;
         dbms_output.put_line('ENV.WHO_CALLED_ME');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         dbms_output.put_line(env.who_called_me||' from line '||i_line);
         dbms_output.new_line;
         dbms_output.put_line('ENV.CALLER_META');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         env.caller_meta(l_owner, l_obj_type, l_unit_name, l_routine_nm, l_line_num);
         dbms_output.put_line(l_owner||'.'||l_obj_type||'.'||l_routine_nm||' @ line '||l_line_num);
         dbms_output.new_line;
         dbms_output.put_line('ENV.GET_ROUTINE_NM + LINE_NUM_HERE');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         dbms_output.put_line(env.get_routine_nm($$PLSQL_UNIT,$$PLSQL_LINE)||' @ line '||env.line_num_here);
      ELSE

         bogus_priv_proc(i_str);
         dbms_output.new_line;
         dbms_output.put_line('Call Stack');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         io.p(DBMS_UTILITY.format_call_stack);
         dbms_output.new_line;
         dbms_output.put_line('ENV.WHO_AM_I');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         dbms_output.put_line(env.who_am_i);
         dbms_output.new_line;
         dbms_output.put_line('ENV.WHO_CALLED_ME');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         dbms_output.put_line(env.who_called_me||' from line '||i_line);
         dbms_output.new_line;
         dbms_output.put_line('ENV.CALLER_META');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         env.caller_meta(l_owner, l_obj_type, l_unit_name, l_routine_nm, l_line_num);
         dbms_output.put_line(l_owner||'.'||l_obj_type||'.'||l_routine_nm||' @ line '||l_line_num);
         dbms_output.new_line;
         dbms_output.put_line('ENV.GET_ROUTINE_NM + LINE_NUM_HERE');
         dbms_output.put_line('--------------------------------------------------------------------------------');   
         dbms_output.put_line(env.get_routine_nm($$PLSQL_UNIT,$$PLSQL_LINE)||' @ line '||env.line_num_here);
      END IF;
   ELSIF (i_str = 'logs') THEN
      env.init_client_ctx(i_client_id => 'bcoulam');
      logs.msg('Assertion Failure', cnst.WARN);
      logs.msg('Logical Lock Held', cnst.ERROR, msgs.fill_msg('Logical Lock Held','Object 1','Entity A', '5'));
      logs.msg(10, cnst.WARN);
      logs.msg('My stand-in message');
      logs.warn('My warning message');
      logs.info('My info message');
      logs.set_dbg(TRUE);
      logs.dbg('Debug message');
      DECLARE
      BEGIN
         RAISE lx;
      EXCEPTION
         WHEN lx THEN
            logs.err(FALSE);
            --dbms_output.put_line(dbms_utility.format_error_backtrace);
            logs.err('My error message',TRUE);
      END;
   ELSIF (i_str = 'dbg') THEN
      FOR i IN 1..40 LOOP
         env.init_client_ctx(i_client_id => 'bcoulam');
         logs.dbg('Test msg');
         --dbms_lock.sleep(5);
      END LOOP;   
   ELSIF (i_str = 'err_in_excp') THEN
      err_in_excp;   
   END IF;
EXCEPTION
   WHEN TOO_MANY_ROWS THEN
      excp.throw;
END proc;

PROCEDURE bogus_pub_proc
IS
BEGIN
   NULL;
END bogus_pub_proc;

PROCEDURE bogus_pub_proc /*comment*/ (i_str IN VARCHAR2)
IS
BEGIN
   NULL;
END bogus_pub_proc;
PROCEDURE err_in_excp IS
BEGIN
   RAISE NO_DATA_FOUND;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RAISE NO_DATA_FOUND;
END err_in_excp;

END bottom;
/

SET SERVEROUTPUT ON
EXEC top.proc('excp.throw');
SET SERVEROUTPUT ON
EXEC top.proc('excp.throw(ORA)');
SET SERVEROUTPUT ON
EXEC top.proc('SQLCODE');
SET SERVEROUTPUT ON
EXEC top.proc('raise');
SET SERVEROUTPUT ON
EXEC top.proc('backtrace');
SET SERVEROUTPUT ON
EXEC top.proc('env');
SET SERVEROUTPUT ON
EXEC top.proc('logs');
SET SERVEROUTPUT ON
EXEC top.proc('dbg');

