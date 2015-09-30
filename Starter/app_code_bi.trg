CREATE OR REPLACE TRIGGER app_code_bi
  BEFORE INSERT ON app_code
  FOR EACH ROW
DECLARE
BEGIN
   IF (:new.code_id IS NULL) THEN
      SELECT app_code_seq.NEXTVAL INTO :new.code_id FROM dual;
   END IF;
END app_code_bi;
/*******************************************************************************
Trigger to ensure insertions to APP_CODE have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
