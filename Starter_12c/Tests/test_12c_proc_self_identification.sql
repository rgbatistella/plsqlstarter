CREATE OR REPLACE FUNCTION who_am_i RETURN VARCHAR2 AS
BEGIN
   RETURN utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(2));
END who_am_i;
/

CREATE OR REPLACE FUNCTION get_my_line RETURN INTEGER AS
BEGIN
   RETURN utl_call_stack.unit_line(2);
END get_my_line;
/

CREATE OR REPLACE PACKAGE test_utc AS
   PROCEDURE where_am_i(i_test IN VARCHAR2 DEFAULT NULL);
END test_utc;
/

CREATE OR REPLACE PACKAGE BODY test_utc AS
   PROCEDURE where_am_i(i_test IN VARCHAR2 DEFAULT NULL) IS
      PROCEDURE i_am_here_p IS
      BEGIN
         dbms_output.put_line(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(1)));
      END i_am_here_p;
      FUNCTION i_am_here_f RETURN VARCHAR2 IS
      BEGIN
         RETURN utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(1));
      END i_am_here_f;
      PROCEDURE inner_calling_wrapper IS
      BEGIN
         dbms_output.put_line(who_am_i);
      END inner_calling_wrapper;
   BEGIN
      IF (i_test IS NULL) THEN
         dbms_output.put_line(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(1)));
      ELSIF (i_test = 'inner_proc') THEN
         i_am_here_p;
      ELSIF (i_test = 'inner_func') THEN
         dbms_output.put_line(i_am_here_f);
      ELSIF (i_test = 'wrapper') THEN
         dbms_output.put_line(who_am_i);
      ELSIF (i_test = 'inner_calling_wrapper') THEN
         inner_calling_wrapper;
      ELSIF (i_test = 'excp') THEN
         RAISE VALUE_ERROR;
      ELSIF (i_test = 'my_line') THEN
         dbms_output.put_line(TO_CHAR(utl_call_stack.unit_line(1)));
      ELSIF (i_test = 'wrapped_my_line') THEN
         dbms_output.put_line(get_my_line);
      END IF;
   EXCEPTION
      WHEN VALUE_ERROR THEN
         dbms_output.put_line(who_am_i);
   END where_am_i;
END test_utc;
/

SET SERVEROUTPUT ON SIZE 1000000 
BEGIN
   dbms_output.put_line(CHR(10)||'Test [Regular proc identifying itself] Expect "TEST_UTC.WHERE_AM_I"');
   test_utc.where_am_i;
   dbms_output.put_line(CHR(10)||'Test [Inner proc identifying itself] Expect "TEST_UTC.WHERE_AM_I.I_AM_HERE_P"');
   test_utc.where_am_i('inner_proc');
   dbms_output.put_line(CHR(10)||'Test [Inner function identifying itself] Expect "TEST_UTC.WHERE_AM_I.I_AM_HERE_F"');
   test_utc.where_am_i('inner_func');
   dbms_output.put_line(CHR(10)||'Test [Wrapper function correctly ignoring itself and reporting caller] Expect "TEST_UTC.WHERE_AM_I"');
   test_utc.where_am_i('wrapper');
   dbms_output.put_line(CHR(10)||'Test [Inner routine calling upon wrapper. Wrapper must ignore itself and identify inner proc] Expect "TEST_UTC.WHERE_AM_I.INNER_CALLING_WRAPPER"');
   test_utc.where_am_i('inner_calling_wrapper');
   dbms_output.put_line(CHR(10)||'Test [Identify self from within exception block] Expect "TEST_UTC.WHERE_AM_I"');
   test_utc.where_am_i('excp');
   dbms_output.put_line(CHR(10)||'Test [Identify current line number] Expect 29');
   test_utc.where_am_i('my_line');
   dbms_output.put_line(CHR(10)||'Test [Identify current line number through wrapper] Expect 31');
   test_utc.where_am_i('wrapped_my_line');
END;
/
