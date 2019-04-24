SET SERVEROUTPUT ON SIZE 1000000
DECLARE
--   l_blob BLOB;
   l_blob BLOB := EMPTY_BLOB();
BEGIN
   IF (l_blob IS NULL) THEN
      dbms_output.put_line('l_blob locator is null');
   ELSE
      dbms_output.put_line('l_blob might have something in it');
      
      dbms_output.put_line('Temporary ['||dbms_lob.istemporary(l_blob)||']');
      
      IF (dbms_lob.getlength(l_blob) > 0) THEN
         dbms_output.put_line('l_blob has something in it!');
      ELSE
         dbms_output.put_line('l_blob was just intialized is all.');
      END IF;
   END IF;
END;
/
