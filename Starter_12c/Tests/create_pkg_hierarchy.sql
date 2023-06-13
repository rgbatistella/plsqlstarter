DROP SYNONYM top
/
DROP SYNONYM middle
/
DROP SYNONYM bottom
/

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
   logs.create_event('Testing logs Event');
   logs.dbg('before middle.proc call');
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
   FUNCTION get_line RETURN NUMBER IS BEGIN    logs.dbg('inside get line'); RETURN $$PLSQL_LINE; END get_line;
   -- this is only meant to test inner routines
   FUNCTION get_str RETURN VARCHAR2
   IS
   BEGIN
      logs.dbg('inside get str');
      RETURN i_str;
   END get_str;
BEGIN
   logs.dbg('before bottom.proc call');
   bottom.proc(get_str, get_line);
END proc;
END middle;
/

CREATE OR REPLACE PACKAGE BODY bottom
AS
PROCEDURE bogus_priv_proc (i_str IN VARCHAR2) IS
BEGIN
   logs.dbg('inside bottom.bogus_priv_proc');
   dbms_output.put_line(i_str);
END bogus_priv_proc;

PROCEDURE proc    (i_str IN VARCHAR2, i_line IN NUMBER) IS
   lx EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx, -0922);

   PROCEDURE force_error IS
   BEGIN
      logs.dbg('raising too many rows');
      RAISE TOO_MANY_ROWS;
   EXCEPTION
      WHEN TOO_MANY_ROWS THEN
         dbms_output.new_line;
         dbms_output.put_line('Old Call Stack');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.put_line(dbms_utility.format_call_stack);
         dbms_output.new_line;
         dbms_output.new_line;
         dbms_output.put_line('Old Error Stack');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.put_line(dbms_utility.format_error_stack);
         dbms_output.new_line;
         dbms_output.new_line;
         dbms_output.put_line('10g Backtrace');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.put_line(dbms_utility.format_error_backtrace);
         dbms_output.new_line;
         dbms_output.put_line('********** UTL_CALL_STACK Section **********');
         dbms_output.put_line('Call Stack Depth ['||utl_call_stack.dynamic_depth||'] Backtrace Depth ['||utl_call_stack.backtrace_depth||'] Error Stack Depth ['||utl_call_stack.error_depth||']');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.new_line;
         dbms_output.put_line('UCS Call Stack');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.put_line( str.ewc('LexDepth',9)||str.ewc('Depth',6)||str.ewc('Line#',6)||str.ewc('Unit Name',60) );
         FOR i IN 1..utl_call_stack.dynamic_depth() LOOP
            dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.lexical_depth(i)),9)||
                                  str.ewc(TO_CHAR(i),6)||
                                  str.ewc(TO_CHAR(utl_call_stack.unit_line(i)),6)||
                                  str.ewc(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i)),60) );
         END LOOP;
         dbms_output.new_line;
         dbms_output.put_line('UCS Error Stack');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.put_line( str.ewc('Error#',10)||str.ewc('ErrorMsg',50) );
         FOR i IN 1..utl_call_stack.error_depth() LOOP
            dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.error_number(i)),10)||
                                  str.ewc(SUBSTR(utl_call_stack.error_msg(i),1,50),50) );
         END LOOP;
         dbms_output.new_line;
         dbms_output.put_line('UCS Backtrace');
         dbms_output.put_line('--------------------------------------------------------------------------------');
         dbms_output.put_line( str.ewc('Line#',10)||str.ewc('Unit Name',60) );
         FOR i IN REVERSE 1..utl_call_stack.backtrace_depth() LOOP
            dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.backtrace_line(i)),10)||
                                  str.ewc(SUBSTR(utl_call_stack.backtrace_unit(i),1,60),60) );
         END LOOP;
         logs.err('Failure forced in test of ucs - error stack',TRUE);
   END force_error;

BEGIN

   logs.dbg('before bogus_priv_proc');
   bogus_priv_proc(i_str);

   IF (i_str = 'excp.throw') THEN
      logs.dbg('before excp 5000');
      excp.throw(5000,'Super important error from bottom.proc');
   ELSIF(i_str = 'excp.throw(ORA)') THEN
      logs.dbg('before excp -12574');
      excp.throw(-12574);
   ELSIF (i_str = 'SQLCODE') THEN
      logs.dbg('before excp too_many_rows');
      RAISE TOO_MANY_ROWS;
   ELSIF (i_str = 'raise') THEN
      logs.dbg('before raise -2000');
      raise_application_error(-20000,'Error raised by RAISE_APPLICATION_ERROR');
   ELSIF (i_str = 'ucs - call stack') THEN
      dbms_output.new_line;
      dbms_output.put_line('Old Call Stack');
      dbms_output.put_line('--------------------------------------------------------------------------------');
      dbms_output.put_line(dbms_utility.format_call_stack);
      dbms_output.new_line;
      dbms_output.put_line('UCS Call Stack');
      dbms_output.put_line('--------------------------------------------------------------------------------');
      dbms_output.put_line('Call Stack Depth ['||utl_call_stack.dynamic_depth||'] Backtrace Depth ['||utl_call_stack.backtrace_depth||'] Error Stack Depth ['||utl_call_stack.error_depth||']');
      dbms_output.put_line('--------------------------------------------------------------------------------');
      dbms_output.put_line( str.ewc('LexDepth',9)||str.ewc('Depth',6)||str.ewc('Line#',6)||str.ewc('Name',60) );
      logs.dbg('before call stack loop');
      FOR i IN 1..utl_call_stack.dynamic_depth() LOOP
         dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.lexical_depth(i)),9)||
                               str.ewc(TO_CHAR(i),6)||
                               str.ewc(TO_CHAR(utl_call_stack.unit_line(i)),6)||
                               str.ewc(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i)),60) );
      END LOOP;
   ELSIF (i_str = 'ucs - error stack') THEN
      logs.dbg('before force error');
      force_error;
   ELSIF (i_str = 'backtrace') THEN
      BEGIN
         logs.dbg('before excp too_many_rows');
         RAISE TOO_MANY_ROWS;
      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            dbms_output.new_line;
            dbms_output.put_line('10g Backtrace Stack');
            dbms_output.put_line('--------------------------------------------------------------------------------');
            dbms_output.put_line(DBMS_UTILITY.format_error_backtrace);
            dbms_output.new_line;
            logs.err('Failed during proc(backtrace)',TRUE);
      END;
   ELSIF (i_str = 'env') THEN
      logs.dbg('inside env');
      dbms_output.new_line;
      dbms_output.put_line('Call Stack');
      dbms_output.put_line('--------------------------------------------------------------------------------');
      dbms_output.put_line(DBMS_UTILITY.format_call_stack);
      dbms_output.new_line;
      dbms_output.put_line('ENV.GET_MY_NM');
      dbms_output.put_line('--------------------------------------------------------------------------------');
      dbms_output.put_line(env.get_my_nm);
      dbms_output.new_line;
      dbms_output.put_line('ENV.GET_CALLER_NM');
      dbms_output.put_line('--------------------------------------------------------------------------------');
      dbms_output.put_line(env.get_caller_nm||' from line '||i_line);
      dbms_output.new_line;
      dbms_output.put_line('ENV.GET_CALLER_LINE');
      dbms_output.put_line('--------------------------------------------------------------------------------');
      dbms_output.put_line(env.get_caller_line);
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
            logs.dbg('before raise error message');
            logs.err('My error message',TRUE);
      END;
   ELSIF (i_str = 'dbg') THEN
      FOR i IN 1..40 LOOP
         env.init_client_ctx(i_client_id => 'bcoulam');
         logs.dbg('Test msg');
         --dbms_lock.sleep(5);
      END LOOP;
   ELSIF (i_str = 'err_in_excp') THEN
      logs.dbg('before err_in_excp');
      err_in_excp;
   END IF;
EXCEPTION
   WHEN TOO_MANY_ROWS THEN
      logs.dbg('before final too many rows');
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
   logs.dbg('before no data found in err_in_excp');
   RAISE NO_DATA_FOUND;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RAISE NO_DATA_FOUND;
END err_in_excp;

END bottom;
/

CREATE OR REPLACE PACKAGE BODY bottom AS

PROCEDURE proc(i_str IN VARCHAR2) IS
BEGIN
   IF (i_str = 'unhandled') THEN
 	  RAISE VALUE_ERROR;
   ELSIF (i_str = 'handled') THEN
 	  RAISE NO_DATA_FOUND;
   END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  logs.msg(RPAD('Error#',7)||RPAD('Line#',6)||RPAD('Unit',12)||'Msg');
  FOR i IN REVERSE 1..utl_call_stack.backtrace_depth() LOOP
   logs.msg(RPAD(TO_CHAR(utl_call_stack.error_number(i)),7)||
       RPAD(TO_CHAR(utl_call_stack.backtrace_line(i)),6)||
       RPAD(SUBSTR(utl_call_stack.backtrace_unit(i),1,12),12)||
       utl_call_stack.error_msg(i));
  END LOOP;
  RAISE;
END proc;

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

BEGIN
  app_log_api.g_event_id := 11;
  logs.update_event('updated event name');
END;
/

BEGIN
  app_log_api.g_event_id := null;
  logs.update_event('updated/created non existant event name');
END;
/

BEGIN
  app_log_api.g_event_id := null;
  logs.update_event('updated/created non existant event name',null,null,false);
END;
/
SELECT v('APP_ID') FROM dual
APP_PAGE_ID
APP_SESSION
APP_USER
REQUEST
SELECT * FROM useR_scheduler_jobs WHERE Lower(job_action) LIKE '%_da%';
                      begin DA_ADM_PRC_CUSTO_MENSAL( TO_CHAR(SYSDATE,'YYYY-MM') ); end;
                      DA_DCP_PKG_DOCUMENT_CAPTURE.processar_arquivos
/

SELECT * FROM apex_appl_automations WHERE application_id=2500;
SELECT * FROM apex_appl_automation_actions WHERE application_id=2500 ORDER BY 1 desc;
SELECT * FROM apex_debug_messages WHERE session_id=16047692502195;

Select *
From APEX_Automation_Log WHERE application_id=2500
AND automation_name <>'Iniciar jobs de análise de documento'
ORDER BY end_timestamp desc;
SELECT * FROM app_log WHERE log_id=1555 ORDER BY 1 DESC;

SELECT * FROM app_log WHERE log_id>473 ORDER BY 1 DESC;
SELECT * FROM app_event ORDER BY 1 DESC;
exec env.init_client_ctx(   i_client_id  => 1)
exec env.set_current_schema ('ECOMEX');
SELECT env.get_current_schema FROM dual;
SELECT msgs.get_msg_cd(103), msgs.get_msg(msgs.get_msg_cd(103)) FROM dual;
SELECT env.get_caller_nm, env.get_caller_line FROM dual;
SELECT logs.format_log_txt ('teste')  FROM dual ;


ORA-01403: no data found
ORA-06512: at line 5
ORA-20000: teste
ORA-06512: at line 2

ORA-01403: no data found
ORA-06512: at line 5
ORA-20000: teste
ORA-06512: at line 2
/

DECLARE
  x NUMBER;
BEGIN
  logs.dbg('antes de da divisão');
  x := 1 / 0;
EXCEPTION
  WHEN others THEN
  logs.err;
END;
/

SELECT * FROM app_log ORDER BY 1 DESC;
begin