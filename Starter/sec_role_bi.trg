CREATE OR REPLACE TRIGGER sec_role_bi
  BEFORE INSERT ON sec_role
  FOR EACH ROW
DECLARE
BEGIN
      IF (:new.role_id IS NULL) THEN
         SELECT sec_role_seq.NEXTVAL INTO :new.role_id FROM dual;
      END IF;
END sec_role_bi;
/*******************************************************************************
Trigger to ensure insertions to SEC_ROLE have a new PK from the sequence generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Oct27 Initial creation.
*******************************************************************************/
/
