CREATE OR REPLACE TRIGGER sec_user_aiud
AFTER INSERT OR UPDATE OR DELETE ON sec_user
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
      l_chlog_mstr.chg_log_id := app_chg_log_seq.NEXTVAL;
      l_chlog_mstr.app_id := env.get_app_id;
      l_chlog_mstr.chg_log_dt := dt.get_sysdtm;
      l_chlog_mstr.chg_type_cd := i_chg_type_cd;
      l_chlog_mstr.table_nm := 'SEC_USER';
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
 
      prep_next_audit_rec('I',:new.user_id);
 
      add_chg('USER_ID', NULL, TO_CHAR(:new.user_id));
      add_chg('USER_NM', NULL, :new.user_nm);
      add_chg('PREF_NM', NULL, :new.pref_nm);
      add_chg('PMY_EMAIL_ADDR', NULL, :new.pmy_email_addr);
      add_chg('WORK_PHONE', NULL, :new.work_phone);
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.user_id);
 
 
      IF ((:old.user_nm IS NULL AND :new.user_nm IS NOT NULL) OR
          (:old.user_nm IS NOT NULL AND :new.user_nm IS NULL) OR
          (:old.user_nm <> :new.user_nm)) THEN
 
         add_chg('USER_NM', :old.user_nm, :new.user_nm);
      END IF;
 
      IF ((:old.pref_nm IS NULL AND :new.pref_nm IS NOT NULL) OR
          (:old.pref_nm IS NOT NULL AND :new.pref_nm IS NULL) OR
          (:old.pref_nm <> :new.pref_nm)) THEN
 
         add_chg('PREF_NM', :old.pref_nm, :new.pref_nm);
      END IF;

      IF ((:old.pmy_email_addr IS NULL AND :new.pmy_email_addr IS NOT NULL) OR
          (:old.pmy_email_addr IS NOT NULL AND :new.pmy_email_addr IS NULL) OR
          (:old.pmy_email_addr <> :new.pmy_email_addr)) THEN
 
         add_chg('PMY_EMAIL_ADDR', :old.pmy_email_addr, :new.pmy_email_addr);
      END IF;

      IF ((:old.work_phone IS NULL AND :new.work_phone IS NOT NULL) OR
          (:old.work_phone IS NOT NULL AND :new.work_phone IS NULL) OR
          (:old.work_phone <> :new.work_phone)) THEN
 
         add_chg('WORK_PHONE', :old.work_phone, :new.work_phone);
      END IF;
 
   ELSIF (DELETING) THEN
 
      prep_next_audit_rec('D',:old.user_id);
 
      add_chg('USER_ID', TO_CHAR(:old.user_id), NULL);
      add_chg('USER_NM', :old.user_nm, NULL);
      add_chg('PREF_NM', :old.pref_nm, NULL);
      add_chg('PMY_EMAIL_ADDR', :old.pmy_email_addr, NULL);
      add_chg('WORK_PHONE', :old.work_phone, NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END sec_user_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to SEC_USER
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
