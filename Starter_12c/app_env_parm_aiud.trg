CREATE OR REPLACE TRIGGER app_env_parm_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_env_parm
FOR EACH ROW
DECLARE
 
   l_chlog_mstr app_chg_log%ROWTYPE;
   TYPE tt_chlog_dtl IS TABLE OF app_chg_log_dtl%ROWTYPE;
   l_chlog_dtl tt_chlog_dtl := tt_chlog_dtl();
 
   PROCEDURE prep_next_audit_rec(
    i_chg_type_cd IN app_chg_log.chg_type_cd%TYPE
   ,i_row_id IN ROWID
   )
   IS
   BEGIN
      l_chlog_mstr.chg_log_id := app_chg_log_seq.NEXTVAL;
      l_chlog_mstr.app_id := env.get_app_id;
      l_chlog_mstr.chg_log_dt := dt.get_sysdtm;
      l_chlog_mstr.chg_type_cd := i_chg_type_cd;
      l_chlog_mstr.table_nm := 'APP_ENV_PARM';
      l_chlog_mstr.row_id := i_row_id;
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
 
      prep_next_audit_rec('I',:new.rowid);
 
      add_chg('ENV_ID', NULL, TO_CHAR(:new.env_id));
      add_chg('PARM_ID', NULL, TO_CHAR(:new.parm_id));
      add_chg('PARM_VAL', NULL, :new.parm_val);
      add_chg('HIDE_YN', NULL, :new.hide_yn);
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.rowid);
 
 
      IF ((:old.env_id IS NULL AND :new.env_id IS NOT NULL) OR
          (:old.env_id IS NOT NULL AND :new.env_id IS NULL) OR
          (:old.env_id <> :new.env_id)) THEN
 
         add_chg('ENV_ID', TO_CHAR(:old.env_id), TO_CHAR(:new.env_id));
      END IF;
 
      IF ((:old.parm_id IS NULL AND :new.parm_id IS NOT NULL) OR
          (:old.parm_id IS NOT NULL AND :new.parm_id IS NULL) OR
          (:old.parm_id <> :new.parm_id)) THEN
 
         add_chg('PARM_ID', TO_CHAR(:old.parm_id), TO_CHAR(:new.parm_id));
      END IF;
 
      IF ((:old.parm_val IS NULL AND :new.parm_val IS NOT NULL) OR
          (:old.parm_val IS NOT NULL AND :new.parm_val IS NULL) OR
          (:old.parm_val <> :new.parm_val)) THEN
 
         add_chg('PARM_VAL', :old.parm_val, :new.parm_val);
      END IF;
 
      IF ((:old.hide_yn IS NULL AND :new.hide_yn IS NOT NULL) OR
          (:old.hide_yn IS NOT NULL AND :new.hide_yn IS NULL) OR
          (:old.hide_yn <> :new.hide_yn)) THEN
 
         add_chg('HIDE_YN', :old.hide_yn, :new.hide_yn);
      END IF;
 
   ELSIF (DELETING) THEN
 
      prep_next_audit_rec('D',:old.rowid);
 
      add_chg('ENV_ID', TO_CHAR(:old.env_id), NULL);
      add_chg('PARM_ID', TO_CHAR(:old.parm_id), NULL);
      add_chg('PARM_VAL', :old.parm_val, NULL);
      add_chg('HIDE_YN', :old.hide_yn, NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_env_parm_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_ENV_PARM
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
