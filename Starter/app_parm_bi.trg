CREATE OR REPLACE TRIGGER app_parm_bi
  BEFORE INSERT ON app_parm
  FOR EACH ROW
DECLARE
BEGIN
      IF (:new.parm_id IS NULL) THEN
         SELECT app_parm_seq.NEXTVAL INTO :new.parm_id FROM dual;
      END IF;
END app_parm_bi;
/*******************************************************************************
Trigger to ensure insertions to APP_PARM have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
