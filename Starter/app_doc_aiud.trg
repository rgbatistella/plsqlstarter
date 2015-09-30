CREATE OR REPLACE TRIGGER app_doc_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_doc
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
      l_chlog_mstr.table_nm := 'APP_DOC';
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
 
      prep_next_audit_rec('I',:new.doc_id);
 
      add_chg('DOC_ID', NULL, TO_CHAR(:new.doc_id));
      add_chg('APP_ID', NULL, TO_CHAR(:new.app_id));
      add_chg('FILE_NM', NULL, :new.file_nm);
      --add_chg('DOC_CONTENT', NULL, :new.doc_content);
      add_chg('DOC_SIZE', NULL, TO_CHAR(:new.doc_size));
      add_chg('MIME_TYPE', NULL, :new.mime_type);
      add_chg('OTX_DOC_TYPE', NULL, :new.otx_doc_type);
      add_chg('OTX_LANG_CD', NULL, :new.otx_lang_cd);
      add_chg('OTX_CHARSET_CD', NULL, :new.otx_charset_cd);
      add_chg('MOD_BY', NULL, :new.mod_by);
      add_chg('MOD_DTM', NULL, TO_CHAR(:new.mod_dtm,'DD Mon YYYY HH24:MI:SS'));
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.doc_id);
 
 
      IF ((:old.doc_id IS NULL AND :new.doc_id IS NOT NULL) OR
          (:old.doc_id IS NOT NULL AND :new.doc_id IS NULL) OR
          (:old.doc_id <> :new.doc_id)) THEN
 
         add_chg('DOC_ID', TO_CHAR(:old.doc_id), TO_CHAR(:new.doc_id));
      END IF;
 
      IF ((:old.app_id IS NULL AND :new.app_id IS NOT NULL) OR
          (:old.app_id IS NOT NULL AND :new.app_id IS NULL) OR
          (:old.app_id <> :new.app_id)) THEN
 
         add_chg('APP_ID', TO_CHAR(:old.app_id), TO_CHAR(:new.app_id));
      END IF;
 
      IF ((:old.file_nm IS NULL AND :new.file_nm IS NOT NULL) OR
          (:old.file_nm IS NOT NULL AND :new.file_nm IS NULL) OR
          (:old.file_nm <> :new.file_nm)) THEN
 
         add_chg('FILE_NM', :old.file_nm, :new.file_nm);
      END IF;
 
--      IF ((:old.doc_content IS NULL AND :new.doc_content IS NOT NULL) OR
--          (:old.doc_content IS NOT NULL AND :new.doc_content IS NULL) OR
--          (:old.doc_content <> :new.doc_content)) THEN
-- 
--         add_chg('DOC_CONTENT', :old.doc_content, :new.doc_content);
--      END IF;
 
      IF ((:old.doc_size IS NULL AND :new.doc_size IS NOT NULL) OR
          (:old.doc_size IS NOT NULL AND :new.doc_size IS NULL) OR
          (:old.doc_size <> :new.doc_size)) THEN
 
         add_chg('DOC_SIZE', TO_CHAR(:old.doc_size), TO_CHAR(:new.doc_size));
      END IF;
 
      IF ((:old.mime_type IS NULL AND :new.mime_type IS NOT NULL) OR
          (:old.mime_type IS NOT NULL AND :new.mime_type IS NULL) OR
          (:old.mime_type <> :new.mime_type)) THEN
 
         add_chg('MIME_TYPE', :old.mime_type, :new.mime_type);
      END IF;
 
      IF ((:old.otx_doc_type IS NULL AND :new.otx_doc_type IS NOT NULL) OR
          (:old.otx_doc_type IS NOT NULL AND :new.otx_doc_type IS NULL) OR
          (:old.otx_doc_type <> :new.otx_doc_type)) THEN
 
         add_chg('OTX_DOC_TYPE', :old.otx_doc_type, :new.otx_doc_type);
      END IF;
 
      IF ((:old.otx_lang_cd IS NULL AND :new.otx_lang_cd IS NOT NULL) OR
          (:old.otx_lang_cd IS NOT NULL AND :new.otx_lang_cd IS NULL) OR
          (:old.otx_lang_cd <> :new.otx_lang_cd)) THEN
 
         add_chg('OTX_LANG_CD', :old.otx_lang_cd, :new.otx_lang_cd);
      END IF;
 
      IF ((:old.otx_charset_cd IS NULL AND :new.otx_charset_cd IS NOT NULL) OR
          (:old.otx_charset_cd IS NOT NULL AND :new.otx_charset_cd IS NULL) OR
          (:old.otx_charset_cd <> :new.otx_charset_cd)) THEN
 
         add_chg('OTX_CHARSET_CD', :old.otx_charset_cd, :new.otx_charset_cd);
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
 
      prep_next_audit_rec('D',:old.doc_id);
 
      add_chg('DOC_ID', TO_CHAR(:old.doc_id), NULL);
      add_chg('APP_ID', TO_CHAR(:old.app_id), NULL);
      add_chg('FILE_NM', :old.file_nm, NULL);
      --add_chg('DOC_CONTENT', :old.doc_content, NULL);
      add_chg('DOC_SIZE', TO_CHAR(:old.doc_size), NULL);
      add_chg('MIME_TYPE', :old.mime_type, NULL);
      add_chg('OTX_DOC_TYPE', :old.otx_doc_type, NULL);
      add_chg('OTX_LANG_CD', :old.otx_lang_cd, NULL);
      add_chg('OTX_CHARSET_CD', :old.otx_charset_cd, NULL);
      add_chg('MOD_BY', :old.mod_by, NULL);
      add_chg('MOD_DTM', TO_CHAR(:old.mod_dtm,'DD Mon YYYY HH24:MI:SS'), NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_doc_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_DOC
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
