CREATE OR REPLACE TRIGGER app_env_bi
  BEFORE INSERT ON app_env
  FOR EACH ROW
DECLARE
BEGIN
      IF (:new.env_id IS NULL) THEN
         SELECT app_env_seq.NEXTVAL INTO :new.env_id FROM dual;
      END IF;
END app_env_bi;
/*******************************************************************************
Trigger to ensure insertions to APP_ENV have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
