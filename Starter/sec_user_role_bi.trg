CREATE OR REPLACE TRIGGER sec_user_role_bi
  BEFORE INSERT ON sec_user_role
  FOR EACH ROW
DECLARE
BEGIN
      IF (:new.user_role_id IS NULL) THEN
         SELECT sec_user_role_seq.NEXTVAL INTO :new.user_role_id FROM dual;
      END IF;
END sec_user_bi;
/*******************************************************************************
Trigger to ensure insertions to SEC_USER_ROLE have a new PK from the sequence 
generator.
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Dec19 Initial creation.
*******************************************************************************/
