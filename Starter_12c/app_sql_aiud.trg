CREATE OR REPLACE TRIGGER app_sql_aiud
AFTER INSERT OR UPDATE OR DELETE ON app_sql
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
      l_chlog_mstr.table_nm := 'APP_SQL';
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
 
      prep_next_audit_rec('I',:new.sql_id);
 
      add_chg('SQL_ID', NULL, TO_CHAR(:new.sql_id));
      add_chg('APP_ID', NULL, TO_CHAR(:new.app_id));
      add_chg('SQL_NAME', NULL, :new.sql_name);
      add_chg('USER_ID', NULL, TO_CHAR(:new.user_id));
      add_chg('SQL_TYPE', NULL, :new.sql_type);
      add_chg('DML_STMT', NULL, :new.dml_stmt);
      add_chg('FROM_TXT', NULL, :new.from_txt);
      add_chg('WHERE_TXT', NULL, :new.where_txt);
      add_chg('GROUP_BY_TXT', NULL, :new.group_by_txt);
      add_chg('HAVING_TXT', NULL, :new.having_txt);
      add_chg('ORDER_BY_TXT', NULL, :new.order_by_txt);
      add_chg('MOD_BY', NULL, :new.mod_by);
      add_chg('MOD_DTM', NULL, TO_CHAR(:new.mod_dtm,'DD Mon YYYY HH24:MI:SS'));
 
   ELSIF (UPDATING) THEN
 
      prep_next_audit_rec('U',:new.sql_id);
 
 
      IF ((:old.sql_id IS NULL AND :new.sql_id IS NOT NULL) OR
          (:old.sql_id IS NOT NULL AND :new.sql_id IS NULL) OR
          (:old.sql_id <> :new.sql_id)) THEN
 
         add_chg('SQL_ID', TO_CHAR(:old.sql_id), TO_CHAR(:new.sql_id));
      END IF;
 
      IF ((:old.app_id IS NULL AND :new.app_id IS NOT NULL) OR
          (:old.app_id IS NOT NULL AND :new.app_id IS NULL) OR
          (:old.app_id <> :new.app_id)) THEN
 
         add_chg('APP_ID', TO_CHAR(:old.app_id), TO_CHAR(:new.app_id));
      END IF;
 
      IF ((:old.sql_name IS NULL AND :new.sql_name IS NOT NULL) OR
          (:old.sql_name IS NOT NULL AND :new.sql_name IS NULL) OR
          (:old.sql_name <> :new.sql_name)) THEN
 
         add_chg('SQL_NAME', :old.sql_name, :new.sql_name);
      END IF;
 
      IF ((:old.user_id IS NULL AND :new.user_id IS NOT NULL) OR
          (:old.user_id IS NOT NULL AND :new.user_id IS NULL) OR
          (:old.user_id <> :new.user_id)) THEN
 
         add_chg('USER_ID', TO_CHAR(:old.user_id), TO_CHAR(:new.user_id));
      END IF;
 
      IF ((:old.sql_type IS NULL AND :new.sql_type IS NOT NULL) OR
          (:old.sql_type IS NOT NULL AND :new.sql_type IS NULL) OR
          (:old.sql_type <> :new.sql_type)) THEN
 
         add_chg('SQL_TYPE', :old.sql_type, :new.sql_type);
      END IF;
 
      IF ((:old.dml_stmt IS NULL AND :new.dml_stmt IS NOT NULL) OR
          (:old.dml_stmt IS NOT NULL AND :new.dml_stmt IS NULL) OR
          (:old.dml_stmt <> :new.dml_stmt)) THEN
 
         add_chg('DML_STMT', :old.dml_stmt, :new.dml_stmt);
      END IF;
 
      IF ((:old.from_txt IS NULL AND :new.from_txt IS NOT NULL) OR
          (:old.from_txt IS NOT NULL AND :new.from_txt IS NULL) OR
          (:old.from_txt <> :new.from_txt)) THEN
 
         add_chg('FROM_TXT', :old.from_txt, :new.from_txt);
      END IF;
 
      IF ((:old.where_txt IS NULL AND :new.where_txt IS NOT NULL) OR
          (:old.where_txt IS NOT NULL AND :new.where_txt IS NULL) OR
          (:old.where_txt <> :new.where_txt)) THEN
 
         add_chg('WHERE_TXT', :old.where_txt, :new.where_txt);
      END IF;
 
      IF ((:old.group_by_txt IS NULL AND :new.group_by_txt IS NOT NULL) OR
          (:old.group_by_txt IS NOT NULL AND :new.group_by_txt IS NULL) OR
          (:old.group_by_txt <> :new.group_by_txt)) THEN
 
         add_chg('GROUP_BY_TXT', :old.group_by_txt, :new.group_by_txt);
      END IF;
 
      IF ((:old.having_txt IS NULL AND :new.having_txt IS NOT NULL) OR
          (:old.having_txt IS NOT NULL AND :new.having_txt IS NULL) OR
          (:old.having_txt <> :new.having_txt)) THEN
 
         add_chg('HAVING_TXT', :old.having_txt, :new.having_txt);
      END IF;
 
      IF ((:old.order_by_txt IS NULL AND :new.order_by_txt IS NOT NULL) OR
          (:old.order_by_txt IS NOT NULL AND :new.order_by_txt IS NULL) OR
          (:old.order_by_txt <> :new.order_by_txt)) THEN
 
         add_chg('ORDER_BY_TXT', :old.order_by_txt, :new.order_by_txt);
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
 
      prep_next_audit_rec('D',:old.sql_id);
 
      add_chg('SQL_ID', TO_CHAR(:old.sql_id), NULL);
      add_chg('APP_ID', TO_CHAR(:old.app_id), NULL);
      add_chg('SQL_NAME', :old.sql_name, NULL);
      add_chg('USER_ID', TO_CHAR(:old.user_id), NULL);
      add_chg('SQL_TYPE', :old.sql_type, NULL);
      add_chg('DML_STMT', :old.dml_stmt, NULL);
      add_chg('FROM_TXT', :old.from_txt, NULL);
      add_chg('WHERE_TXT', :old.where_txt, NULL);
      add_chg('GROUP_BY_TXT', :old.group_by_txt, NULL);
      add_chg('HAVING_TXT', :old.having_txt, NULL);
      add_chg('ORDER_BY_TXT', :old.order_by_txt, NULL);
      add_chg('MOD_BY', :old.mod_by, NULL);
      add_chg('MOD_DTM', TO_CHAR(:old.mod_dtm,'DD Mon YYYY HH24:MI:SS'), NULL);
   END IF;
 
   INSERT INTO app_chg_log VALUES l_chlog_mstr;
 
   -- Bulk insert all change log records, if any.
   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN
 
      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST
         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);
 
   END IF;
END app_sql_aiud;
/*******************************************************************************
Trigger to track insertions, modifications or deletions to APP_SQL
 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar01 Initial creation.
*******************************************************************************/
/
