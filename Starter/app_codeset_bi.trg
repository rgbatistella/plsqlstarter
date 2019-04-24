CREATE OR REPLACE TRIGGER app_codeset_bi
  BEFORE INSERT ON app_codeset
  FOR EACH ROW
DECLARE
BEGIN
   IF (:new.codeset_id IS NULL) THEN
      SELECT app_codeset_seq.NEXTVAL INTO :new.codeset_id FROM dual;
   END IF;
END app_codeset_bi;
/*******************************************************************************
Trigger to ensure insertions to APP_CODESET have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
