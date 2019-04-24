CREATE OR REPLACE TRIGGER app_log_bi
  BEFORE INSERT ON app_log  
  FOR EACH ROW
DECLARE
BEGIN
   IF (:new.app_id IS NULL) THEN
      :new.app_id := env.get_app_id;
   END IF;
   IF (:new.log_ts IS NULL) THEN
      :new.log_ts := dt.get_systs;
   END IF;
   IF (:new.sev_cd IS NULL) THEN
      :new.sev_cd := cnst.ERROR;
   END IF;
   IF (:new.client_id IS NULL) THEN
      :new.client_id := env.get_client_id;
   END IF;
   IF (:new.client_ip IS NULL) THEN
      :new.client_ip := env.get_client_ip;
   END IF;
   IF (:new.client_host IS NULL) THEN
      :new.client_host := env.get_client_host;
   END IF;
   IF (:new.client_os_user IS NULL) THEN
      :new.client_os_user := env.get_client_os_user;
   END IF;
   
END app_log_bi;
/*******************************************************************************
Ensures the new row has the required fields filled.

Artisan      Date      Comments
------------ --------- ------------------------------------------------------
bcoulam      2008Jan13 Initial creation.
*******************************************************************************/
/
