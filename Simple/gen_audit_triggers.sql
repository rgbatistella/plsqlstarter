--PROMPT Generating trigger comparators...
SET SERVEROUTPUT ON SIZE 1000000
SPOOL &&spool_filename_and_path
SET TERMOUT OFF
SET FEEDBACK OFF
DECLARE
   CURSOR cur_trg_hdr IS
   SELECT LOWER(ucc.table_name) table_name,
          LOWER(ucc.column_name) pk_col
     FROM user_cons_columns ucc
    WHERE ucc.position = 1
      AND ucc.table_name NOT LIKE 'DR$%' -- eliminate Oracle Text indexes
      AND ucc.table_name NOT IN ('APP_CHG_LOG','APP_CHG_LOG_DTL', 'APP_LOG', 'APP_EMAIL', 'APP_EMAIL_DOC')
      AND ucc.constraint_name IN
          (SELECT constraint_name
             FROM user_constraints
            WHERE constraint_type = 'P')
     ORDER BY table_name;
BEGIN

   FOR lr IN cur_trg_hdr LOOP
      -- The placeholders for sequence names in the following block assume that
      -- the schema is adhering to naming the sequence with the table_name + "_SEQ'
      dbms_output.put_line('CREATE OR REPLACE TRIGGER '||lr.table_name||'_biud');
      dbms_output.put_line('BEFORE INSERT OR UPDATE OR DELETE ON '||lr.table_name);
      dbms_output.put_line('FOR EACH ROW');
      dbms_output.put_line('DECLARE');
      dbms_output.put_line('');
      dbms_output.put_line('   l_chlog_mstr app_chg_log%ROWTYPE;');
      dbms_output.put_line('   TYPE tt_chlog_dtl IS TABLE OF app_chg_log_dtl%ROWTYPE;');
      dbms_output.put_line('   l_chlog_dtl tt_chlog_dtl := tt_chlog_dtl();');
      dbms_output.put_line('');
      dbms_output.put_line('   PROCEDURE prep_next_audit_rec(');
      dbms_output.put_line('    i_chg_type_cd IN app_chg_log.chg_type_cd%TYPE');
      dbms_output.put_line('   ,i_pk_id IN app_chg_log.pk_id%TYPE');
      dbms_output.put_line('   )');
      dbms_output.put_line('   IS');
      dbms_output.put_line('   BEGIN');
      dbms_output.put_line('      SELECT app_chg_log_seq.NEXTVAL INTO l_chlog_mstr.chg_log_id FROM dual;');
      dbms_output.put_line('      l_chlog_mstr.app_id := env.get_app_id;');
      dbms_output.put_line('      l_chlog_mstr.chg_log_dt := dt.get_sysdtm;');
      dbms_output.put_line('      l_chlog_mstr.chg_type_cd := i_chg_type_cd;');
      dbms_output.put_line('      l_chlog_mstr.table_nm := '''||UPPER(lr.table_name)||''';');
      dbms_output.put_line('      l_chlog_mstr.pk_id := i_pk_id;');
      dbms_output.put_line('      l_chlog_mstr.client_id := env.get_client_id;');
      dbms_output.put_line('      l_chlog_mstr.client_ip := env.get_client_ip;');
      dbms_output.put_line('      l_chlog_mstr.client_host := env.get_client_host;');
      dbms_output.put_line('      l_chlog_mstr.client_os_user := env.get_client_os_user;');
      dbms_output.put_line('   END prep_next_audit_rec;');
      dbms_output.put_line('');
      dbms_output.put_line('   PROCEDURE add_chg(');
      dbms_output.put_line('    i_column_nm IN app_chg_log_dtl.column_nm%TYPE');
      dbms_output.put_line('   ,i_old_val IN app_chg_log_dtl.old_val%TYPE DEFAULT NULL');
      dbms_output.put_line('   ,i_new_val IN app_chg_log_dtl.new_val%TYPE DEFAULT NULL');
      dbms_output.put_line('   )');
      dbms_output.put_line('   IS');
      dbms_output.put_line('      l_idx INTEGER := 0;');
      dbms_output.put_line('   BEGIN');
      dbms_output.put_line('      l_chlog_dtl.EXTEND;');
      dbms_output.put_line('      l_idx := l_chlog_dtl.LAST;');
      dbms_output.put_line('      l_chlog_dtl(l_idx).chg_log_id := l_chlog_mstr.chg_log_id;');
      dbms_output.put_line('      l_chlog_dtl(l_idx).chg_log_dt := l_chlog_mstr.chg_log_dt;');
      dbms_output.put_line('      l_chlog_dtl(l_idx).column_nm := i_column_nm;');
      dbms_output.put_line('      l_chlog_dtl(l_idx).old_val := i_old_val;');
      dbms_output.put_line('      l_chlog_dtl(l_idx).new_val := i_new_val;');
      dbms_output.put_line('   END add_chg;');
      dbms_output.put_line('');
      dbms_output.put_line('BEGIN');
      dbms_output.put_line('');
      dbms_output.put_line('   IF (INSERTING) THEN');

      dbms_output.put_line('      IF (:new.'||lr.pk_col||' IS NULL) THEN');
      -- May need to code an inner routine here or call to framework like Starter's UTIL.get_max_pk_val if
      -- the table's surrogate key is not being fed by a sequence.
      dbms_output.put_line('         SELECT '||lr.table_name||'_seq.NEXTVAL INTO :new.'||lr.pk_col||' FROM dual;');
      dbms_output.put_line('      END IF;');
      dbms_output.put_line('');
--      dbms_output.put_line('      -- Ensure the sequence is in sync with the values in the table.');
--      dbms_output.put_line('      -- Core tables frequently get new values inserted by hand unless strict policies');
--      dbms_output.put_line('      -- and admin screens are in place to provide an easy-to-use API into them. This');
--      dbms_output.put_line('      -- trigger ensures that newly inserted surrogate keys do not clash with existing');
--      dbms_output.put_line('      -- keys in case rows were inserted outside of the API or the sequence generator.');
--      dbms_output.put_line('      IF (utils.get_max_pk_val('''||lr.table_name||''') >= :new.'||lr.pk_col||') THEN');
--      dbms_output.put_line('         util.reset_seq('''||lr.table_name||'_seq'');');
--      dbms_output.put_line('         SELECT '||lr.table_name||'_seq.NEXTVAL INTO :new.'||lr.pk_col||' FROM dual;');
--      dbms_output.put_line('      END IF;');
--      dbms_output.put_line('');
      -- Comment the next two IF blocks out if the table does not have the standard crt_by/crt_dt and mod_by/mod_dt audit columns
      dbms_output.put_line('      IF (:new.mod_by IS NULL) THEN');
      dbms_output.put_line('         :new.mod_by := env.get_client_id;');
      dbms_output.put_line('      END IF;');
      dbms_output.put_line('');
      dbms_output.put_line('      IF (:new.mod_dtm IS NULL) THEN');
      dbms_output.put_line('         :new.mod_dtm := dt.get_sysdtm;');
      dbms_output.put_line('      END IF;');
      dbms_output.put_line('');
      dbms_output.put_line('      prep_next_audit_rec(''I'',:new.'||lr.pk_col||');');
      dbms_output.put_line('');

      FOR lrc IN (SELECT column_name, data_type FROM user_tab_columns WHERE table_name = UPPER(lr.table_name) ORDER BY column_id) LOOP
         IF (lrc.data_type = 'DATE') THEN
            dbms_output.put_line('      add_chg('''||lrc.column_name||''', NULL, TO_CHAR(:new.'||LOWER(lrc.column_name)||',''DD Mon YYYY HH24:MI:SS''));');
         ELSIF (lrc.data_type = 'NUMBER') THEN
            dbms_output.put_line('      add_chg('''||lrc.column_name||''', NULL, TO_CHAR(:new.'||LOWER(lrc.column_name)||'));');
         ELSE
            -- For string datatypes. Will puke a lung on XMLType, objects, LOB, etc.
            dbms_output.put_line('      add_chg('''||lrc.column_name||''', NULL, :new.'||LOWER(lrc.column_name)||');');
           
         END IF;
      END LOOP;
      dbms_output.put_line('');      
      dbms_output.put_line('   ELSIF (UPDATING) THEN');
      dbms_output.put_line('');
      dbms_output.put_line('      prep_next_audit_rec(''U'',:new.'||lr.pk_col||');');
      dbms_output.put_line('');

      FOR lrc IN (SELECT column_name, data_type FROM user_tab_columns WHERE table_name = UPPER(lr.table_name) ORDER BY column_id) LOOP
         dbms_output.put_line('');
         dbms_output.put_line('      IF ((:old.'||LOWER(lrc.column_name)||' IS NULL AND :new.'||LOWER(lrc.column_name)||' IS NOT NULL) OR');
         dbms_output.put_line('          (:old.'||LOWER(lrc.column_name)||' IS NOT NULL AND :new.'||LOWER(lrc.column_name)||' IS NULL) OR');
         dbms_output.put_line('          (:old.'||LOWER(lrc.column_name)||' <> :new.'||LOWER(lrc.column_name)||')) THEN');
         dbms_output.put_line('');

         IF (lrc.data_type = 'DATE') THEN
            dbms_output.put_line('         add_chg('''||lrc.column_name||''', TO_CHAR(:old.'||LOWER(lrc.column_name)||',''DD Mon YYYY HH24:MI:SS''), TO_CHAR(:new.'||LOWER(lrc.column_name)||',''DD Mon YYYY HH24:MI:SS''));');
         ELSIF (lrc.data_type = 'NUMBER') THEN
            dbms_output.put_line('         add_chg('''||lrc.column_name||''', TO_CHAR(:old.'||LOWER(lrc.column_name)||'), TO_CHAR(:new.'||LOWER(lrc.column_name)||'));');
         ELSE
            -- For string datatypes. Will puke a lung on XMLType, objects, LOB, etc.
            dbms_output.put_line('         add_chg('''||lrc.column_name||''', :old.'||LOWER(lrc.column_name)||', :new.'||LOWER(lrc.column_name)||');');
           
         END IF;
         dbms_output.put_line('      END IF;');
      END LOOP;

      dbms_output.put_line('   ELSIF (DELETING) THEN');
      dbms_output.put_line('');
      dbms_output.put_line('      prep_next_audit_rec(''D'',:old.'||lr.pk_col||');');
      dbms_output.put_line('');

      FOR lrc IN (SELECT column_name, data_type FROM user_tab_columns WHERE table_name = UPPER(lr.table_name) ORDER BY column_id) LOOP
         IF (lrc.data_type = 'DATE') THEN
            dbms_output.put_line('      add_chg('''||lrc.column_name||''', TO_CHAR(:old.'||LOWER(lrc.column_name)||',''DD Mon YYYY HH24:MI:SS''), NULL);');
         ELSIF (lrc.data_type = 'NUMBER') THEN
            dbms_output.put_line('      add_chg('''||lrc.column_name||''', TO_CHAR(:old.'||LOWER(lrc.column_name)||'), NULL);');
         ELSE
            -- For string datatypes. Will puke a lung on XMLType, objects, LOB, etc.
            dbms_output.put_line('      add_chg('''||lrc.column_name||''', :old.'||LOWER(lrc.column_name)||', NULL);');
           
         END IF;
      END LOOP;

      dbms_output.put_line('   END IF;');
      dbms_output.put_line('');
      dbms_output.put_line('   INSERT INTO app_chg_log VALUES l_chlog_mstr;');
      dbms_output.put_line('');
      dbms_output.put_line('   -- Bulk insert all change log records, if any.');
      dbms_output.put_line('   IF (l_chlog_dtl IS NOT NULL AND l_chlog_dtl.COUNT > 0) THEN');
      dbms_output.put_line('');
      dbms_output.put_line('      FORALL i IN l_chlog_dtl.FIRST..l_chlog_dtl.LAST');
      dbms_output.put_line('         INSERT INTO app_chg_log_dtl VALUES l_chlog_dtl(i);');
      dbms_output.put_line('');
      dbms_output.put_line('   END IF;');
      

      dbms_output.put_line('END '||lr.table_name||'_biud;');
      dbms_output.put_line('/*******************************************************************************');
      dbms_output.put_line('Trigger to track insertions, modifications or deletions to '||UPPER(lr.table_name));
      dbms_output.put_line('');
      dbms_output.put_line('Artisan      Date      Comments');
      dbms_output.put_line('============ ========= ========================================================');
      dbms_output.put_line('bcoulam      '||TO_CHAR(SYSDATE,'YYYYMonDD')||' Initial creation.');
      dbms_output.put_line('*******************************************************************************/');
      dbms_output.put_line('/');
   
   -- If spooling out tons of triggers, this is nice to visually demarcate the end of one and the start of another
   -- Remove if only running for single tables.
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   dbms_output.put_line('');
   
   END LOOP;

END;
/
SET TERMOUT ON
SPOOL OFF
SET FEEDBACK ON
