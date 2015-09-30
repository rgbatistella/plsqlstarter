SET SERVEROUTPUT ON SIZE 1000000
-- This version of throw_err demonstrates raising an Oracle-defined exception
CREATE OR REPLACE PROCEDURE throw_oracle_err
IS
   l_result INTEGER;
BEGIN
   dbms_output.put_line('Calculating result...');
   l_result := 1/0;
END throw_oracle_err;
/

-- This version of throw_err demonstrates raising a user-defined application exception
-- as well as length limitations on user-defined error message
CREATE OR REPLACE PROCEDURE throw_user_err
IS
BEGIN
--   raise_application_error(-20999,'Hi there! I''m broken',TRUE);
   raise_application_error(-20999,RPAD('|',2046,'X')||'|');
END throw_user_err;
/

-- This version of throw_err demonstrates raising a named exception associated to an Oracle defined exception
CREATE OR REPLACE PROCEDURE throw_named_excp
IS
   lx_int_err EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_int_err, -21300);
BEGIN
   RAISE lx_int_err;
END throw_named_excp;
/

CREATE OR REPLACE PROCEDURE client(i_proc IN INTEGER)
IS
   lx_div_by_zero EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_div_by_zero, -1476);
BEGIN
   CASE i_proc
      WHEN 1 THEN
         dbms_output.put_line('Calling throw_oracle_err()...');
         throw_oracle_err;
      WHEN 2 THEN
         dbms_output.put_line('Calling throw_user_err()...');
         throw_user_err;
      WHEN 3 THEN
         dbms_output.put_line('Calling throw_named_excp()...');
         throw_named_excp;
   END CASE;

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
   client(1);
END;
/      

PAUSE Press any key to throw the next error...
SET SERVEROUTPUT ON SIZE 1000000
BEGIN
   client(2);
END;
/      

PAUSE Press any key to throw the next error...
SET SERVEROUTPUT ON SIZE 1000000
BEGIN
   client(3);
END;
/      
