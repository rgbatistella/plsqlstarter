CREATE OR REPLACE TRIGGER app_msg_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_msg
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
      l_chlog_mstr.app_id := env.get_app_id;
      l_chlog_mstr.chg_log_dt := dt.get_sysdtm;
      l_chlog_mstr.chg_type_cd := i_chg_type_cd;
      l_chlog_mstr.table_nm := 'APP_MSG';
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
 
      prep_next_audit_rec('I',:new.msg_id);
 
      add_chg('MSG_ID', NULL, TO_CHAR(:new.msg_id));
      add_chg('APP_ID', NULL, TO_CHAR(:new.app_id));
      add_chg('MSG_CD', NULL, :new.msg_cd);
      add_chg('MSG', NULL, :new.msg);
      add_chg('MSG_DESCR', NULL, :new.msg_descr);
      add_chg('MSG_SOLN', NULL, :new.msg_soln);
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.msg_id);
 
 
      IF ((:old.msg_id IS NULL AND :new.msg_id IS NOT NULL) OR
          (:old.msg_id IS NOT NULL AND :new.msg_id IS NULL) OR
          (:old.msg_id <> :new.msg_id)) THEN
 
         add_chg('MSG_ID', TO_CHAR(:old.msg_id), TO_CHAR(:new.msg_id));
      END IF;
 
      IF ((:old.app_id IS NULL AND :new.app_id IS NOT NULL) OR
          (:old.app_id IS NOT NULL AND :new.app_id IS NULL) OR
          (:old.app_id <> :new.app_id)) THEN
 
         add_chg('APP_ID', TO_CHAR(:old.app_id), TO_CHAR(:new.app_id));
      END IF;
 
      IF ((:old.msg_cd IS NULL AND :new.msg_cd IS NOT NULL) OR
          (:old.msg_cd IS NOT NULL AND :new.msg_cd IS NULL) OR
          (:old.msg_cd <> :new.msg_cd)) THEN
 
         add_chg('MSG_CD', :old.msg_cd, :new.msg_cd);
      END IF;
 
      IF ((:old.msg IS NULL AND :new.msg IS NOT NULL) OR
          (:old.msg IS NOT NULL AND :new.msg IS NULL) OR
          (:old.msg <> :new.msg)) THEN
 
         add_chg('MSG', :old.msg, :new.msg);
      END IF;
 
      IF ((:old.msg_descr IS NULL AND :new.msg_descr IS NOT NULL) OR
          (:old.msg_descr IS NOT NULL AND :new.msg_descr IS NULL) OR
          (:old.msg_descr <> :new.msg_descr)) THEN
 
         add_chg('MSG_DESCR', :old.msg_descr, :new.msg_descr);
      END IF;
 
      IF ((:old.msg_soln IS NULL AND :new.msg_soln IS NOT NULL) OR
          (:old.msg_soln IS NOT NULL AND :new.msg_soln IS NULL) OR
          (:old.msg_soln <> :new.msg_soln)) THEN
 
         add_chg('MSG_SOLN', :old.msg_soln, :new.msg_soln);
      END IF;
 
   ELSIF (DELETING) THEN
 
      prep_next_audit_rec('D',:old.msg_id);
 
      add_chg('MSG_ID', TO_CHAR(:old.msg_id), NULL);
      add_chg('APP_ID', TO_CHAR(:old.app_id), NULL);
      add_chg('MSG_CD', :old.msg_cd, NULL);
      add_chg('MSG', :old.msg, NULL);
      add_chg('MSG_DESCR', :old.msg_descr, NULL);
      add_chg('MSG_SOLN', :old.msg_descr, NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_msg_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_MSG
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
bcoulam      2008May02 Changed msg_desc to msg_descr.
*******************************************************************************/
/
