CREATE OR REPLACE TRIGGER app_env_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_env
FOR EACH ROW
DECLARE
 
   l_chlog_mstr app_chg_log%ROWTYPE;
   TYPE tt_chlog_dtl IS TABLE OF app_chg_log_dtl%ROWTYPE;
   l_chlog_dtl tt_chlog_dtl := tt_chlog_dtl();
 
   PROCEDURE prep_next_audit_rec(
    i_chg_type_cd IN app_chg_log.chg_type_cd%TYPE
   ,i_pk_id IN app_chg_log.pk_id%TYPE
   )
   IS
   BEGIN
      SELECT app_chg_log_seq.NEXTVAL INTO l_chlog_mstr.chg_log_id FROM dual;
      l_chlog_mstr.app_id := env.get_app_id('CORE');
      l_chlog_mstr.chg_log_dt := dt.get_sysdtm;
      l_chlog_mstr.chg_type_cd := i_chg_type_cd;
      l_chlog_mstr.table_nm := 'APP_ENV';
      l_chlog_mstr.pk_id := i_pk_id;
      l_chlog_mstr.client_id := env.get_client_id;
      l_chlog_mstr.client_ip := env.get_client_ip;
      l_chlog_mstr.client_host := env.get_client_host;
      l_chlog_mstr.client_os_user := env.get_client_os_user;
   END prep_next_audit_rec;
 
   PROCEDURE add_chg(
    i_column_nm IN app_chg_log_dtl.column_nm%TYPE
   ,i_old_val IN app_chg_log_dtl.old_val%TYPE DEFAULT NULL
   ,i_new_val IN app_chg_log_dtl.new_val%TYPE DEFAULT NULL
   )
   IS
      l_idx INTEGER := 0;
   BEGIN
      l_chlog_dtl.EXTEND;
      l_idx := l_chlog_dtl.LAST;
      l_chlog_dtl(l_idx).chg_log_id := l_chlog_mstr.chg_log_id;
      l_chlog_dtl(l_idx).column_nm := i_column_nm;
      l_chlog_dtl(l_idx).old_val := i_old_val;
      l_chlog_dtl(l_idx).new_val := i_new_val;
   END add_chg;
 
BEGIN
 
   IF (INSERTING) THEN

      prep_next_audit_rec('I',:new.env_id);
 
      add_chg('ENV_ID', NULL, TO_CHAR(:new.env_id));
      add_chg('ENV_NM', NULL, :new.env_nm);
      add_chg('APP_ID', NULL, TO_CHAR(:new.app_id));
      add_chg('DB_ID', NULL, TO_CHAR(:new.db_id));
      add_chg('APP_VERSION',NULL,:new.app_version);
      add_chg('OWNER_ACCOUNT', NULL, :new.owner_account);
      add_chg('ACCESS_ACCOUNT', NULL, :new.access_account);
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.env_id);
 
 
      IF ((:old.env_id IS NULL AND :new.env_id IS NOT NULL) OR
          (:old.env_id IS NOT NULL AND :new.env_id IS NULL) OR
          (:old.env_id <> :new.env_id)) THEN
 
         add_chg('ENV_ID', TO_CHAR(:old.env_id), TO_CHAR(:new.env_id));
      END IF;
 
      IF ((:old.env_nm IS NULL AND :new.env_nm IS NOT NULL) OR
          (:old.env_nm IS NOT NULL AND :new.env_nm IS NULL) OR
          (:old.env_nm <> :new.env_nm)) THEN
 
         add_chg('ENV_NM', :old.env_nm, :new.env_nm);
      END IF;
 
      IF ((:old.app_id IS NULL AND :new.app_id IS NOT NULL) OR
          (:old.app_id IS NOT NULL AND :new.app_id IS NULL) OR
          (:old.app_id <> :new.app_id)) THEN
 
         add_chg('APP_ID', TO_CHAR(:old.app_id), TO_CHAR(:new.app_id));
      END IF;
 
      IF ((:old.db_id IS NULL AND :new.db_id IS NOT NULL) OR
          (:old.db_id IS NOT NULL AND :new.db_id IS NULL) OR
          (:old.db_id <> :new.db_id)) THEN
 
         add_chg('DB_ID', TO_CHAR(:old.db_id), TO_CHAR(:new.db_id));
      END IF;
 
      IF ((:old.app_version IS NULL AND :new.app_version IS NOT NULL) OR
          (:old.app_version IS NOT NULL AND :new.app_version IS NULL) OR
          (:old.app_version <> :new.app_version)) THEN
 
         add_chg('APP_VERSION', :old.app_version, :new.app_version);
      END IF;

      IF ((:old.owner_account IS NULL AND :new.owner_account IS NOT NULL) OR
          (:old.owner_account IS NOT NULL AND :new.owner_account IS NULL) OR
          (:old.owner_account <> :new.owner_account)) THEN
 
         add_chg('OWNER_ACCOUNT', :old.owner_account, :new.owner_account);
      END IF;
 
      IF ((:old.access_account IS NULL AND :new.access_account IS NOT NULL) OR
          (:old.access_account IS NOT NULL AND :new.access_account IS NULL) OR
          (:old.access_account <> :new.access_account)) THEN
 
         add_chg('ACCESS_ACCOUNT', :old.access_account, :new.access_account);
      END IF;
 
   ELSIF (DELETING) THEN
 
      prep_next_audit_rec('D',:old.env_id);
 
      add_chg('ENV_ID', TO_CHAR(:old.env_id), NULL);
      add_chg('ENV_NM', :old.env_nm, NULL);
      add_chg('APP_ID', TO_CHAR(:old.app_id), NULL);
      add_chg('DB_ID', TO_CHAR(:old.db_id), NULL);
      add_chg('APP_VERSION', :old.app_version, NULL);
      add_chg('OWNER_ACCOUNT', :old.owner_account, NULL);
      add_chg('ACCESS_ACCOUNT', :old.access_account, NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_env_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_ENV
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
