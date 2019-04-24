SET SERVEROUTPUT ON
BEGIN
   BEGIN
      ctx_ddl.drop_preference('sol_lexer');
      dbms_output.put_line('sol_lexer dropped');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('WARNING: (sol_lexer) '||SQLERRM);
   END;

   ctx_ddl.create_preference('sol_lexer', 'BASIC_LEXER');
   -- Comment the following in if you wish words with hyphens and underscores to be indexed
   -- together. For example, if the problem text has the tokens ORA-03113. Without the
   -- printjoins attribute, ORA and 03113 would be indexed. A search on either would yield
   -- a result, but a search on ORA-03113 would not find anything. Conversly, with printjoins
   -- added like that below, the fulle "ORA-03113" would be indexed. A search on ORA or
   -- 03113 would yield no results. You'd have to search on the full hyphenated word to
   -- get the Text index to find anything.
   --ctx_ddl.set_attribute('sol_lexer', 'printjoins', '-_');
   ctx_ddl.set_attribute('sol_lexer', 'whitespace', '-_');
   ctx_ddl.set_attribute('sol_lexer', 'index_stems', 'ENGLISH');
   ctx_ddl.set_attribute('sol_lexer', 'base_letter', 'YES'); -- removes diacritics

   BEGIN
      ctx_ddl.drop_preference('sol_wordlist');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('WARNING: (sol_wordlist) '||SQLERRM);
   END;

   ctx_ddl.create_preference('sol_wordlist', 'BASIC_WORDLIST');
   ctx_ddl.set_attribute('sol_wordlist','FUZZY_MATCH','AUTO');
   ctx_ddl.set_attribute('sol_wordlist','STEMMER','AUTO');
--   ctx_ddl.set_attribute('sol_wordlist','PREFIX_INDEX','YES');
--   ctx_ddl.set_attribute('sol_wordlist','PREFIX_MIN_LENGTH',5);
--   ctx_ddl.set_attribute('sol_wordlist','PREFIX_MAX_LENGTH',9);
--    next line can make index creation and DML up to 4X slower (according to Oracle docs)
--   ctx_ddl.set_attribute('sol_wordlist', 'SUBSTRING_INDEX', 'TRUE');

--   BEGIN
--      ctx_ddl.drop_preference('sol_storage');
--   EXCEPTION
--    WHEN OTHERS THEN
--       dbms_output.put_line('WARNING: (sol_storage) '||SQLERRM);
--   END;
--
--   ctx_ddl.create_preference('sol_storage', 'BASIC_STORAGE');
--   ctx_ddl.set_attribute('sol_storage','i_table_clause','TABLESPACE sol_data');
--   ctx_ddl.set_attribute('sol_storage','k_table_clause','TABLESPACE sol_data');
--   ctx_ddl.set_attribute('sol_storage','n_table_clause','TABLESPACE sol_data');
--   ctx_ddl.set_attribute('sol_storage','r_table_clause','TABLESPACE sol_data LOB (data) STORE AS (cache)');
--   ctx_ddl.set_attribute('sol_storage','i_index_clause','TABLESPACE sol_index COMPRESS 2');

--   BEGIN
--      ctx_ddl.drop_preference('prob_multi');
--   EXCEPTION
--    WHEN OTHERS THEN
--       dbms_output.put_line('WARNING: (prob_multi) '||SQLERRM);
--   END;
--
--   ctx_ddl.create_preference('prob_multi', 'MULTI_COLUMN_DATASTORE');
--   ctx_ddl.set_attribute('prob_multi', 'COLUMNS', 'prob_key, prob_key_txt, prob_notes');

   BEGIN
      ctx_ddl.drop_section_group('sol_sectioner');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('WARNING: (sol_sectioner) '||SQLERRM);
   END;

   ctx_ddl.create_section_group('sol_sectioner', 'BASIC_SECTION_GROUP');
   ctx_ddl.add_field_section('sol_sectioner', 'prob_key', 'prob_key', TRUE);
   ctx_ddl.add_field_section('sol_sectioner', 'prob_key_txt', 'prob_key_txt', TRUE);
   ctx_ddl.add_field_section('sol_sectioner', 'prob_notes', 'prob_notes', TRUE);
   ctx_ddl.add_field_section('sol_sectioner', 'sol_notes', 'sol_notes', TRUE);

   BEGIN
      ctx_ddl.drop_preference('sol_user_ds');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('WARNING: (sol_user_ds) '||SQLERRM);
   END;

   ctx_ddl.create_preference('sol_user_ds', 'user_datastore');
   ctx_ddl.set_attribute('sol_user_ds', 'procedure', sys_context('userenv','current_schema')||'.'||'ps_ctx.concat_columns');
   ctx_ddl.set_attribute('sol_user_ds', 'output_type', 'CLOB');

END;
/

--DROP INDEX incd_multi_cidx;
--CREATE INDEX incd_multi_cidx ON incident(otx_sync_col)
--  INDEXTYPE IS CTXSYS.CONTEXT
--  PARAMETERS ('DATASTORE sol_multi
--               LEXER sol_lexer
--               WORDLIST sol_wordlist
--               SYNC (EVERY "SYSDATE+6/24")
--               TRANSACTIONAL
--               ');

BEGIN
   EXECUTE IMMEDIATE 'DROP INDEX ps_multitab_cidx';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -01418 THEN
         NULL;
      ELSE
         RAISE;
      END IF;
END;
/

CREATE INDEX ps_multitab_cidx ON ps_prob(otx_sync_col)
  INDEXTYPE IS CTXSYS.CONTEXT
  PARAMETERS ('DATASTORE sol_user_ds
               SECTION GROUP sol_sectioner
               LEXER sol_lexer
               WORDLIST sol_wordlist
               SYNC (EVERY "SYSDATE+6/24")
               TRANSACTIONAL');
COMMIT;
