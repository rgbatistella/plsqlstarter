CREATE OR REPLACE TRIGGER app_code_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_code
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
      l_chlog_mstr.chg_type_cd := i_chg_type_cd;
      l_chlog_mstr.table_nm := 'APP_CODE';
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
 
      prep_next_audit_rec('I',:new.code_id);
 
      add_chg('CODE_ID', NULL, TO_CHAR(:new.code_id));
      add_chg('CODESET_ID', NULL, TO_CHAR(:new.codeset_id));
      add_chg('CODE_VAL', NULL, :new.code_val);
      add_chg('CODE_DEFN', NULL, :new.code_defn);
      add_chg('DISPLAY_ORDER', NULL, TO_CHAR(:new.display_order));
      add_chg('EDITABLE_FLG', NULL, :new.editable_flg);
      add_chg('ACTIVE_FLG', NULL, :new.active_flg);
      add_chg('PARENT_CODE_ID', NULL, TO_CHAR(:new.parent_code_id));
      add_chg('MOD_BY', NULL, :new.mod_by);
      add_chg('MOD_DTM', NULL, TO_CHAR(:new.mod_dtm,'DD Mon YYYY HH24:MI:SS'));
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.code_id);
 
 
      IF ((:old.code_id IS NULL AND :new.code_id IS NOT NULL) OR
          (:old.code_id IS NOT NULL AND :new.code_id IS NULL) OR
          (:old.code_id <> :new.code_id)) THEN
 
         add_chg('CODE_ID', TO_CHAR(:old.code_id), TO_CHAR(:new.code_id));
      END IF;
 
      IF ((:old.codeset_id IS NULL AND :new.codeset_id IS NOT NULL) OR
          (:old.codeset_id IS NOT NULL AND :new.codeset_id IS NULL) OR
          (:old.codeset_id <> :new.codeset_id)) THEN
 
         add_chg('CODESET_ID', TO_CHAR(:old.codeset_id), TO_CHAR(:new.codeset_id));
      END IF;
 
      IF ((:old.code_val IS NULL AND :new.code_val IS NOT NULL) OR
          (:old.code_val IS NOT NULL AND :new.code_val IS NULL) OR
          (:old.code_val <> :new.code_val)) THEN
 
         add_chg('CODE_VAL', :old.code_val, :new.code_val);
      END IF;
 
      IF ((:old.code_defn IS NULL AND :new.code_defn IS NOT NULL) OR
          (:old.code_defn IS NOT NULL AND :new.code_defn IS NULL) OR
          (:old.code_defn <> :new.code_defn)) THEN
 
         add_chg('CODE_DEFN', :old.code_defn, :new.code_defn);
      END IF;
 
      IF ((:old.display_order IS NULL AND :new.display_order IS NOT NULL) OR
          (:old.display_order IS NOT NULL AND :new.display_order IS NULL) OR
          (:old.display_order <> :new.display_order)) THEN
 
         add_chg('DISPLAY_ORDER', TO_CHAR(:old.display_order), TO_CHAR(:new.display_order));
      END IF;
 
      IF ((:old.editable_flg IS NULL AND :new.editable_flg IS NOT NULL) OR
          (:old.editable_flg IS NOT NULL AND :new.editable_flg IS NULL) OR
          (:old.editable_flg <> :new.editable_flg)) THEN
 
         add_chg('EDITABLE_FLG', :old.editable_flg, :new.editable_flg);
      END IF;
 
      IF ((:old.active_flg IS NULL AND :new.active_flg IS NOT NULL) OR
          (:old.active_flg IS NOT NULL AND :new.active_flg IS NULL) OR
          (:old.active_flg <> :new.active_flg)) THEN
 
         add_chg('ACTIVE_FLG', :old.active_flg, :new.active_flg);
      END IF;
 
      IF ((:old.parent_code_id IS NULL AND :new.parent_code_id IS NOT NULL) OR
          (:old.parent_code_id IS NOT NULL AND :new.parent_code_id IS NULL) OR
          (:old.parent_code_id <> :new.parent_code_id)) THEN
 
         add_chg('PARENT_CODE_ID', TO_CHAR(:old.parent_code_id), TO_CHAR(:new.parent_code_id));
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
 
      prep_next_audit_rec('D',:old.code_id);
 
      add_chg('CODE_ID', TO_CHAR(:old.code_id), NULL);
      add_chg('CODESET_ID', TO_CHAR(:old.codeset_id), NULL);
      add_chg('CODE_VAL', :old.code_val, NULL);
      add_chg('CODE_DEFN', :old.code_defn, NULL);
      add_chg('DISPLAY_ORDER', TO_CHAR(:old.display_order), NULL);
      add_chg('EDITABLE_FLG', :old.editable_flg, NULL);
      add_chg('ACTIVE_FLG', :old.active_flg, NULL);
      add_chg('PARENT_CODE_ID', TO_CHAR(:old.parent_code_id), NULL);
      add_chg('MOD_BY', :old.mod_by, NULL);
      add_chg('MOD_DTM', TO_CHAR(:old.mod_dtm,'DD Mon YYYY HH24:MI:SS'), NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_code_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_CODE
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
