-----------------------------------------------------------------------------
-- On 9i, this block must be run as the CTXSYS user
PROMPT Creating Oracle Text preferences...
SET SERVEROUTPUT ON
BEGIN
   BEGIN
      ctx_ddl.drop_preference('otx_core_lexer');
      dbms_output.put_line('otx_core_lexer dropped');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('INFO: (otx_core_lexer) '||SQLERRM);
   END;

   ctx_ddl.create_preference('otx_core_lexer', 'BASIC_LEXER');
   ctx_ddl.set_attribute('otx_core_lexer', 'printjoins', '-_');
   ctx_ddl.set_attribute('otx_core_lexer', 'index_stems', 'ENGLISH');
   ctx_ddl.set_attribute('otx_core_lexer', 'base_letter', 'YES'); -- removes diacritics

   BEGIN
      ctx_ddl.drop_preference('otx_core_wordlist');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('INFO: (otx_core_wordlist) '||SQLERRM);
   END;

   ctx_ddl.create_preference('otx_core_wordlist', 'BASIC_WORDLIST');
   ctx_ddl.set_attribute('otx_core_wordlist', 'FUZZY_MATCH', 'AUTO');
   ctx_ddl.set_attribute('otx_core_wordlist', 'STEMMER', 'AUTO');
   -- Add these attributes back in if you wish the Context index to be more flexible and forgiving.
   --ctx_ddl.set_attribute('otx_core_wordlist', 'PREFIX_INDEX', 'YES');
   --ctx_ddl.set_attribute('otx_core_wordlist', 'PREFIX_MIN_LENGTH', 3);
   --ctx_ddl.set_attribute('otx_core_wordlist', 'PREFIX_MAX_LENGTH', 5);
   -- Next line can make index creation and DML up to 4X slower (according to Oracle docs)
   --ctx_ddl.set_attribute('otx_core_wordlist', 'SUBSTRING_INDEX', 'TRUE');
  
   BEGIN
      ctx_ddl.drop_preference('otx_core_storage');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('INFO: (otx_core_storage) '||SQLERRM);
   END;

   ctx_ddl.create_preference('otx_core_storage', 'BASIC_STORAGE');
   ctx_ddl.set_attribute('otx_core_storage', 'i_table_clause', 'TABLESPACE &&default_tablespace');
   ctx_ddl.set_attribute('otx_core_storage', 'i_index_clause', 'TABLESPACE &&default_tablespace COMPRESS 2');
   ctx_ddl.set_attribute('otx_core_storage', 'k_table_clause', 'TABLESPACE &&default_tablespace');
   ctx_ddl.set_attribute('otx_core_storage', 'n_table_clause', 'TABLESPACE &&default_tablespace');
   ctx_ddl.set_attribute('otx_core_storage', 'r_table_clause', 'TABLESPACE &&default_tablespace LOB (data) STORE AS (cache)');
   
   BEGIN
      ctx_ddl.drop_preference('otx_aem_multi_ds');
   EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('INFO: (otx_aem_multi_ds) '||SQLERRM);
   END;

   ctx_ddl.create_preference('otx_aem_multi_ds', 'MULTI_COLUMN_DATASTORE');
   ctx_ddl.set_attribute('otx_aem_multi_ds', 'COLUMNS', 
      'email_from, email_to, email_replyto, email_cc, email_bcc, email_subject, email_body, email_extra');

END;
/

CREATE OR REPLACE TRIGGER aem_biu
  BEFORE UPDATE OR INSERT ON app_email
  FOR EACH ROW
DECLARE
BEGIN
   IF (INSERTING) THEN

      :new.otx_sync_col := 'Y';

   ELSIF (updating) THEN
      IF (NVL(:old.email_from,'EMPTY') <> NVL(:new.email_from,'EMPTY') OR
          NVL(:old.email_to,'EMPTY') <> NVL(:new.email_to,'EMPTY') OR
          NVL(:old.email_replyto,'EMPTY') <> NVL(:new.email_replyto,'EMPTY') OR
          NVL(:old.email_cc,'EMPTY') <> NVL(:new.email_cc,'EMPTY') OR
          NVL(:old.email_bcc,'EMPTY') <> NVL(:new.email_bcc,'EMPTY') OR
          NVL(:old.email_subject,'EMPTY') <> NVL(:new.email_subject,'EMPTY') OR
          NVL(:old.email_body,'EMPTY') <> NVL(:new.email_body,'EMPTY') OR
          NVL(:old.email_extra,'EMPTY') <> NVL(:new.email_extra,'EMPTY')
      ) THEN
         :new.otx_sync_col := 'Y';
      END IF;
   END IF;
END aem_biu;
/

-- If the Context index on the email text fields is desired, comment this back in.
-- Creating this Context index as specified below requires the 10g CREATE JOB
-- privilege. If you are on 9i, you will need to remove the SYNC and TRANSACTIONAL
-- parameters.
DROP INDEX aem_multi_cidx FORCE;

CREATE INDEX aem_multi_cidx ON app_email(otx_sync_col) 
  INDEXTYPE IS ctxsys.CONTEXT 
  PARAMETERS ('DATASTORE otx_aem_multi_ds
               LEXER otx_core_lexer
               WORDLIST otx_core_wordlist
               STORAGE otx_core_storage
               SYNC (EVERY "SYSDATE+6/24")
               TRANSACTIONAL
               ')
/

-- Creating this Context index as specified below requires the 10g CREATE JOB
-- privilege. If you are on 9i, you will need to remove the SYNC line and 
-- TRANSACTIONAL line and create your own job to maintain the sync operation.
--DROP INDEX aemd_doc_content_cidx FORCE;
--
--CREATE INDEX aemd_doc_content_cidx ON app_doc(doc_content) 
--  INDEXTYPE IS ctxsys.CONTEXT 
--  PARAMETERS ('DATASTORE ctxsys.DIRECT_DATASTORE
--               LEXER otx_core_lexer
--               WORDLIST otx_core_wordlist
--               FORMAT COLUMN otx_doc_type
--               STORAGE otx_core_storage
--               SYNC (EVERY "SYSDATE+1")
--               TRANSACTIONAL
--               ')
--/
