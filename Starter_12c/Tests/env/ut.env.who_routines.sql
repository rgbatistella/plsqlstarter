SET SERVEROUTPUT ON
DECLARE
BEGIN
   dbms_output.put_line('Expected [Unknown] Actual['||env.who_called_me||']');
   dbms_output.put_line('Expected [ANONYMOUSBLOCK] Actual['||env.who_am_i||']');
END;
/

CREATE OR REPLACE PROCEDURE check_who_routines(i_caller IN VARCHAR2) IS
BEGIN
   dbms_output.put_line('Expected ['||i_caller||'] Actual ['||env.who_called_me||']');
   dbms_output.put_line('Expected [CHECK_WHO_ROUTINES] Actual ['||env.who_am_i||']');
END check_who_routines;
/

BEGIN
   check_who_routines(env.who_am_i);
END;
/

CREATE OR REPLACE PROCEDURE call_check_who_routines IS
BEGIN
   check_who_routines(env.who_am_i);
END call_check_who_routines;
/

BEGIN
   call_check_who_routines;
END;
/

DROP PROCEDURE call_check_who_routines;
DROP PROCEDURE check_who_routines;
