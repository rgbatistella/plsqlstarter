SET SERVEROUTPUT ON SIZE 1000000
CREATE OR REPLACE PROCEDURE throw_err
IS
-- This version of throw_err demonstrates raising an Oracle-define exception
/*
   l_result INTEGER;
BEGIN
   dbms_output.put_line('Calculating result...');
   l_result := 1/0;
*/
-- This version of throw_err demonstrates raising a user-defined application exception

BEGIN
--   raise_application_error(-20999,'Hi there! I''m broken',TRUE);
   raise_application_error(-20999,RPAD('|',2046,'X')||'|');

-- This version of throw_err demonstrates raising a named exception associated to an Oracle defined exception
/*
   lx_int_err EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_int_err, -21302);
BEGIN
   RAISE lx_int_err;
*/
END throw_err;
/

CREATE OR REPLACE PROCEDURE client
IS
   lx_div_by_zero EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_div_by_zero, -1476);
BEGIN
   dbms_output.put_line('Calling throw_err()...');
   throw_err;
EXCEPTION
   WHEN lx_div_by_zero THEN
      dbms_output.put_line('SQLCODE: '||SQLCODE);
      dbms_output.put_line('SQLERRM length: '||LENGTH(SQLERRM)||' SQLERRM: '||SQLERRM);
      dbms_output.put_line('---------- ERROR STACK ----------'||CHR(10)||dbms_utility.format_error_stack);
      dbms_output.put_line('---------- CALL STACK ----------'||CHR(10)||dbms_utility.format_call_stack);
      dbms_output.put_line('---------- BACKTRACE ----------'||CHR(10)||dbms_utility.format_error_backtrace);
      excp.throw;
   WHEN OTHERS THEN
      dbms_output.put_line('SQLCODE: '||SQLCODE);
      dbms_output.put_line('SQLERRM length: '||LENGTH(SQLERRM)||' SQLERRM: '||SQLERRM);
      dbms_output.put_line('---------- ERROR STACK ----------'||CHR(10)||dbms_utility.format_error_stack);
      dbms_output.put_line('---------- CALL STACK ----------'||CHR(10)||dbms_utility.format_call_stack);
      dbms_output.put_line('---------- BACKTRACE ----------'||CHR(10)||dbms_utility.format_error_backtrace);
      excp.throw;
END client;
/

SET SERVEROUTPUT ON SIZE 1000000
BEGIN
   client;
END;
/      
