CREATE OR REPLACE TRIGGER app_bi
  BEFORE INSERT ON app
  FOR EACH ROW
DECLARE
BEGIN
   IF (:new.app_id IS NULL) THEN
      SELECT app_seq.NEXTVAL INTO :new.app_id FROM dual;
   END IF;
END app_bi;
/*******************************************************************************
Trigger to ensure insertions to APP have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
