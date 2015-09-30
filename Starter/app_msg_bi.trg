CREATE OR REPLACE TRIGGER app_msg_bi
  BEFORE INSERT ON app_msg
  FOR EACH ROW
DECLARE
BEGIN
      IF (:new.msg_id IS NULL) THEN
         SELECT app_msg_seq.NEXTVAL INTO :new.msg_id FROM dual;
      END IF;
END app_msg_bi;
/*******************************************************************************
Trigger to ensure insertions to APP_MSG have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
