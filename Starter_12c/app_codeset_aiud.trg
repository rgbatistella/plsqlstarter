CREATE OR REPLACE TRIGGER app_codeset_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_codeset
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
      l_chlog_mstr.chg_type_cd := i_chg_type_cd;
      l_chlog_mstr.table_nm := 'APP_CODESET';
      l_chlog_mstr.pk_id := i_pk_id;
      l_chlog_mstr.mod_by := env.get_client_id;
      l_chlog_mstr.mod_dtm := dt.get_sysdtm;
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

      prep_next_audit_rec('I',:new.codeset_id);
 
      add_chg('CODESET_ID', NULL, TO_CHAR(:new.codeset_id));
      add_chg('APP_ID', NULL, TO_CHAR(:new.app_id));
      add_chg('CODESET_NM', NULL, :new.codeset_nm);
      add_chg('CODESET_DEFN', NULL, :new.codeset_defn);
      add_chg('PARENT_CODESET_ID', NULL, TO_CHAR(:new.parent_codeset_id));
      add_chg('ACTIVE_FLG', NULL, :new.active_flg);
      add_chg('MOD_BY', NULL, :new.mod_by);
      add_chg('MOD_DTM', NULL, TO_CHAR(:new.mod_dtm,'DD Mon YYYY HH24:MI:SS'));
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.codeset_id);
 
 
      IF ((:old.codeset_id IS NULL AND :new.codeset_id IS NOT NULL) OR
          (:old.codeset_id IS NOT NULL AND :new.codeset_id IS NULL) OR
          (:old.codeset_id <> :new.codeset_id)) THEN
 
         add_chg('CODESET_ID', TO_CHAR(:old.codeset_id), TO_CHAR(:new.codeset_id));
      END IF;
 
      IF ((:old.app_id IS NULL AND :new.app_id IS NOT NULL) OR
          (:old.app_id IS NOT NULL AND :new.app_id IS NULL) OR
          (:old.app_id <> :new.app_id)) THEN
 
         add_chg('APP_ID', TO_CHAR(:old.app_id), TO_CHAR(:new.app_id));
      END IF;
 
      IF ((:old.codeset_nm IS NULL AND :new.codeset_nm IS NOT NULL) OR
          (:old.codeset_nm IS NOT NULL AND :new.codeset_nm IS NULL) OR
          (:old.codeset_nm <> :new.codeset_nm)) THEN
 
         add_chg('CODESET_NM', :old.codeset_nm, :new.codeset_nm);
      END IF;
 
      IF ((:old.codeset_defn IS NULL AND :new.codeset_defn IS NOT NULL) OR
          (:old.codeset_defn IS NOT NULL AND :new.codeset_defn IS NULL) OR
          (:old.codeset_defn <> :new.codeset_defn)) THEN
 
         add_chg('CODESET_DEFN', :old.codeset_defn, :new.codeset_defn);
      END IF;
 
      IF ((:old.parent_codeset_id IS NULL AND :new.parent_codeset_id IS NOT NULL) OR
          (:old.parent_codeset_id IS NOT NULL AND :new.parent_codeset_id IS NULL) OR
          (:old.parent_codeset_id <> :new.parent_codeset_id)) THEN
 
         add_chg('PARENT_CODESET_ID', TO_CHAR(:old.parent_codeset_id), TO_CHAR(:new.parent_codeset_id));
      END IF;
 
      IF ((:old.active_flg IS NULL AND :new.active_flg IS NOT NULL) OR
          (:old.active_flg IS NOT NULL AND :new.active_flg IS NULL) OR
          (:old.active_flg <> :new.active_flg)) THEN
 
         add_chg('ACTIVE_FLG', :old.active_flg, :new.active_flg);
      END IF;
 
      IF ((:old.mod_by IS NULL AND :new.mod_by IS NOT NULL) OR
          (:old.mod_by IS NOT NULL AND :new.mod_by IS NULL) OR
          (:old.mod_by <> :new.mod_by)) THEN
 
         add_chg('MOD_BY', :old.mod_by, :new.mod_by);
      END IF;
 
      IF ((:old.mod_dtm IS NULL AND :new.mod_dtm IS NOT NULL) OR
          (:old.mod_dtm IS NOT NULL AND :new.mod_dtm IS NULL) OR
          (:old.mod_dtm <> :new.mod_dtm)) THEN
 
         add_chg('MOD_DTM', TO_CHAR(:old.mod_dtm,'DD Mon YYYY HH24:MI:SS'), TO_CHAR(:new.mod_dtm,'DD Mon YYYY HH24:MI:SS'));
      END IF;
   ELSIF (DELETING) THEN
 
      prep_next_audit_rec('D',:old.codeset_id);
 
      add_chg('CODESET_ID', TO_CHAR(:old.codeset_id), NULL);
      add_chg('APP_ID', TO_CHAR(:old.app_id), NULL);
      add_chg('CODESET_NM', :old.codeset_nm, NULL);
      add_chg('CODESET_DEFN', :old.codeset_defn, NULL);
      add_chg('PARENT_CODESET_ID', TO_CHAR(:old.parent_codeset_id), NULL);
      add_chg('ACTIVE_FLG', :old.active_flg, NULL);
      add_chg('MOD_BY', :old.mod_by, NULL);
      add_chg('MOD_DTM', TO_CHAR(:old.mod_dtm,'DD Mon YYYY HH24:MI:SS'), NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_codeset_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_CODESET
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
