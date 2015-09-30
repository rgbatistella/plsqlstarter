CREATE OR REPLACE TRIGGER app_parm_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_parm
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
      l_chlog_mstr.table_nm := 'APP_PARM';
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
 
      prep_next_audit_rec('I',:new.parm_id);
 
      add_chg('PARM_ID', NULL, TO_CHAR(:new.parm_id));
      add_chg('PARM_NM', NULL, :new.parm_nm);
      add_chg('PARM_DISPLAY_NM', NULL, :new.parm_display_nm);
      add_chg('PARM_COMMENTS', NULL, :new.parm_comments);
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.parm_id);
 
 
      IF ((:old.parm_id IS NULL AND :new.parm_id IS NOT NULL) OR
          (:old.parm_id IS NOT NULL AND :new.parm_id IS NULL) OR
          (:old.parm_id <> :new.parm_id)) THEN
 
         add_chg('PARM_ID', TO_CHAR(:old.parm_id), TO_CHAR(:new.parm_id));
      END IF;
 
      IF ((:old.parm_nm IS NULL AND :new.parm_nm IS NOT NULL) OR
          (:old.parm_nm IS NOT NULL AND :new.parm_nm IS NULL) OR
          (:old.parm_nm <> :new.parm_nm)) THEN
 
         add_chg('PARM_NM', :old.parm_nm, :new.parm_nm);
      END IF;
 
      IF ((:old.parm_display_nm IS NULL AND :new.parm_display_nm IS NOT NULL) OR
          (:old.parm_display_nm IS NOT NULL AND :new.parm_display_nm IS NULL) OR
          (:old.parm_display_nm <> :new.parm_display_nm)) THEN
 
         add_chg('PARM_DISPLAY_NM', :old.parm_display_nm, :new.parm_display_nm);
      END IF;
 
      IF ((:old.parm_comments IS NULL AND :new.parm_comments IS NOT NULL) OR
          (:old.parm_comments IS NOT NULL AND :new.parm_comments IS NULL) OR
          (:old.parm_comments <> :new.parm_comments)) THEN
 
         add_chg('PARM_COMMENTS', :old.parm_comments, :new.parm_comments);
      END IF;
 
   ELSIF (DELETING) THEN
 
      prep_next_audit_rec('D',:old.parm_id);
 
      add_chg('PARM_ID', TO_CHAR(:old.parm_id), NULL);
      add_chg('PARM_NM', :old.parm_nm, NULL);
      add_chg('PARM_DISPLAY_NM', :old.parm_display_nm, NULL);
      add_chg('PARM_COMMENTS', :old.parm_comments, NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_parm_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_PARM
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
