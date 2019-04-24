PL/SQL Developer Test script 3.0
41
/* Use this DDL to set up the objects for the test.
DROP SEQUENCE tr_seq;
DROP FUNCTION get_next;
DROP TABLE tr;

CREATE TABLE tr(ID INTEGER PRIMARY KEY);

CREATE SEQUENCE tr_seq;

CREATE FUNCTION get_next RETURN INTEGER 
IS
   l_next INTEGER := 0;
BEGIN
   l_next := tr_seq.nextval;
   RETURN l_next;
END get_next;
/

BEGIN
   FOR i IN 1..10 LOOP
      INSERT INTO tr VALUES (i);
   END LOOP;
   COMMIT;
END;
/
*/

declare 
   l_max    INTEGER := 0;
   l_before INTEGER := 0;
   l_after INTEGER := 0;
begin
   SELECT MAX(ID) INTO l_max FROM tr;
   SELECT get_next INTO l_before FROM dual;
   ddl_utils.reset_seq('tr_seq');
   SELECT get_next INTO l_after FROM dual;
   
   dbms_output.put_line('Max ID in table [T]est[R]eset: '||l_max);
   dbms_output.put_line('Next sequence number before reset: '||l_before);  
   dbms_output.put_line('Next sequence number after reset: '||l_after);  
end;
0
0
