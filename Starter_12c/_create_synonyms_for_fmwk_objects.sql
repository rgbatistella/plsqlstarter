DECLARE
   CURSOR cur_core_objects IS
      SELECT object_name
        FROM user_objects
       WHERE object_type IN ('PACKAGE', 'TABLE', 'VIEW', 'TYPE', 'SEQUENCE');
BEGIN
   FOR lr IN cur_core_objects LOOP
      EXECUTE IMMEDIATE 'CREATE SYNONYM &&fmwk_consumer.' || lr.object_name ||
                        ' FOR &&fmwk_home.' || lr.object_name;
   END LOOP;
END;
/
