CREATE OR REPLACE TRIGGER app_sql_bi
  BEFORE INSERT ON app_sql
  FOR EACH ROW
DECLARE
BEGIN
   IF (:new.sql_id IS NULL) THEN
      SELECT app_sql_seq.NEXTVAL INTO :new.sql_id FROM dual;
   END IF;
END app_sql_bi;
/*******************************************************************************
Trigger to ensure insertions to APP_SQL have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
