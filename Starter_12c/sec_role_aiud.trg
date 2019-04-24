CREATE OR REPLACE TRIGGER sec_role_aiud
AFTER INSERT OR UPDATE OR DELETE ON sec_role
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
      l_chlog_mstr.table_nm := 'SEC_ROLE';
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
 
      prep_next_audit_rec('I',:new.role_id);
 
      add_chg('ROLE_ID', NULL, TO_CHAR(:new.role_id));
      add_chg('APP_ID', NULL, TO_CHAR(:new.app_id));
      add_chg('ROLE_NM', NULL, :new.role_nm);
      add_chg('ROLE_DESCR', NULL, :new.role_descr);
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.role_id);
 
 
      IF ((:old.role_id IS NULL AND :new.role_id IS NOT NULL) OR
          (:old.role_id IS NOT NULL AND :new.role_id IS NULL) OR
          (:old.role_id <> :new.role_id)) THEN
 
         add_chg('ROLE_ID', TO_CHAR(:old.role_id), TO_CHAR(:new.role_id));
      END IF;
 
      IF ((:old.app_id IS NULL AND :new.app_id IS NOT NULL) OR
          (:old.app_id IS NOT NULL AND :new.app_id IS NULL) OR
          (:old.app_id <> :new.app_id)) THEN
 
         add_chg('APP_ID', TO_CHAR(:old.app_id), TO_CHAR(:new.app_id));
      END IF;
 
      IF ((:old.role_nm IS NULL AND :new.role_nm IS NOT NULL) OR
          (:old.role_nm IS NOT NULL AND :new.role_nm IS NULL) OR
          (:old.role_nm <> :new.role_nm)) THEN
 
         add_chg('ROLE_NM', :old.role_nm, :new.role_nm);
      END IF;
 
      IF ((:old.role_descr IS NULL AND :new.role_descr IS NOT NULL) OR
          (:old.role_descr IS NOT NULL AND :new.role_descr IS NULL) OR
          (:old.role_descr <> :new.role_descr)) THEN
 
         add_chg('ROLE_DESCR', :old.role_descr, :new.role_descr);
      END IF;
 
   ELSIF (DELETING) THEN
 
      prep_next_audit_rec('D',:old.role_id);
 
      add_chg('ROLE_ID', TO_CHAR(:old.role_id), NULL);
      add_chg('APP_ID', TO_CHAR(:old.app_id), NULL);
      add_chg('ROLE_NM', :old.role_nm, NULL);
      add_chg('ROLE_DESCR', :old.role_descr, NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END sec_role_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to SEC_ROLE
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
