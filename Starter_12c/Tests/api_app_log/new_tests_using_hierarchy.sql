DROP PACKAGE bottom;
DROP PACKAGE middle;
DROP PACKAGE top;

CREATE OR REPLACE PACKAGE top AS
PROCEDURE call_middle(i_str IN VARCHAR2);
END top;
/
CREATE OR REPLACE PACKAGE middle AS
PROCEDURE call_bottom(i_str IN VARCHAR2);
END middle;
/
CREATE OR REPLACE PACKAGE bottom AS
PROCEDURE at_bottom(i_str IN VARCHAR2);
END bottom;
/
CREATE OR REPLACE PACKAGE BODY top AS
PROCEDURE call_middle(i_str IN VARCHAR2) IS
BEGIN
   middle.call_bottom(i_str);
EXCEPTION
   WHEN VALUE_ERROR THEN
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
         
      app_log_api.ins(i_log_txt => 'VALUE_ERROR detected durring run of call_middle',
                     i_sev_cd => cnst.ERROR,
                     i_msg_cd => msgs.ERROR_MSG_CD);
   END call_middle;
END top;
/

CREATE OR REPLACE PACKAGE BODY middle AS
PROCEDURE call_bottom(i_str IN VARCHAR2) IS
BEGIN
   bottom.at_bottom(i_str);
END call_bottom;
END middle;
/

CREATE OR REPLACE PACKAGE BODY bottom AS
PROCEDURE at_bottom(i_str IN VARCHAR2) IS
BEGIN
   dbms_output.put_line('Reached the bottom proc with this string: '||i_str);
   IF (i_str = 'value_error') THEN
      RAISE VALUE_ERROR;
   END IF;
END at_bottom;
END bottom;
/

SET SERVEROUTPUT ON SIZE 1000000 
BEGIN
   top.call_middle('value_error');
END;
/
