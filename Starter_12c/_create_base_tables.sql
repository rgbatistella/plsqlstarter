-- Note that every table and every column has a comment in a standard format.
-- The table or column is first spelled out entirely, so that abbreviations and
-- acronyms are expanded and explained. This is followed by an optional code or
-- short display name in parenthesis, then a colon, then the full explanation of
-- the table or column. The short table code found in the parenthesis is used
-- when creating new indexes, foreign keys, SQL table aliases, and other
-- identifiers in PL/SQL. Consider creating automated jobs that check and enforce
-- naming standards using this short table code.

PROMPT Creating tables...

-------------------------------------------------------------------------------
-- Feel free to add more attributes to the APP table, the table that holds
-- metadata about each database-centric software application you write. However,
-- be aware that a subset of the framework's tables are dedicated to holding
-- application-specific parameters that change, like application version,
-- application server home page URL, etc. The tables that hold dynamic properties/
-- parameters are the app_env, app_parm, and app_env_parm tables. This would be
-- a better place to put application properties that can be different per
-- environment.
-------------------------------------------------------------------------------

PROMPT Creating table APP...
CREATE SEQUENCE app_seq
/

CREATE TABLE app
(
 app_id                         INTEGER DEFAULT ON NULL app_seq.NEXTVAL CONSTRAINT a_app_id_nn NOT NULL
,app_cd                         VARCHAR2(5 CHAR) CONSTRAINT a_app_cd_nn NOT NULL
,app_nm                         VARCHAR2(50 CHAR) CONSTRAINT a_app_nm_nn NOT NULL
,app_descr                      VARCHAR2(4000 CHAR) CONSTRAINT a_app_descr_nn NOT NULL
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE app IS 'Applications (A): List of the applications or systems that wish to use the Core framework. In many cases, there will only be one system using Core. If you have multiple applications on the same database and they are small enough, you can create them in the same schema. If they are too large and complex, create them in separate schemas, layered on top of the Core schema using grants and synonyms.';
COMMENT ON COLUMN app.app_id IS 'Application ID: Surrogate key for this table.';
COMMENT ON COLUMN app.app_cd IS 'Application Code: Short code that indicates the system or schema owning the row, thus allowing a logical separation of records in the framework tables that belong to disparate systems.';
COMMENT ON COLUMN app.app_nm IS 'Application Name: Short name that indicates the system or schema owning the row, thus allowing a logical separation of records in the framework tables that belong to disparate systems.';
COMMENT ON COLUMN app.app_descr IS 'Application Description: In-depth description of the system, its purpose, sponsors, information stewards, etc.';

ALTER TABLE app
  ADD CONSTRAINT app_pk
  PRIMARY KEY (app_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app
   ADD CONSTRAINT app_uk
   UNIQUE (app_cd)
   USING INDEX
   TABLESPACE &&index_tablespace
/
ALTER TABLE app
   ADD CONSTRAINT app_uk2
   UNIQUE (app_nm)
   USING INDEX
   TABLESPACE &&index_tablespace
/



-------------------------------------------------------------------------------
PROMPT Creating table APP_DB...
CREATE SEQUENCE app_db_seq
/

CREATE TABLE app_db
(
 db_id                         INTEGER DEFAULT ON NULL app_db_seq.NEXTVAL CONSTRAINT adb_db_id_nn NOT NULL
,db_nm                         VARCHAR2(20 CHAR) CONSTRAINT adb_db_nm_nn NOT NULL
,db_descr                      VARCHAR2(500 CHAR) CONSTRAINT adb_db_descr_nn NOT NULL
,db_alias                      VARCHAR2(20 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE app_db IS 'Database (ADB): Stores metadata for each Oracle environment used in developing or delivering the application(s).';
COMMENT ON COLUMN app_db.db_id IS 'Database ID: Surrogate key for this table.';
COMMENT ON COLUMN app_db.db_nm IS 'Database Name: The database SID, alias or Service Name where an instance of the application can be found.';
COMMENT ON COLUMN app_db.db_descr IS 'Database Description: Description of the database environment for the current record.';
COMMENT ON COLUMN app_db.db_alias IS 'Database Alias: Optional alias for the database, e.g. MSSDV1.';

ALTER TABLE app_db
  ADD CONSTRAINT app_db_pk
  PRIMARY KEY (db_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_db
  ADD CONSTRAINT app_db_uk
  UNIQUE (db_nm)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_db
  ADD CONSTRAINT adb_db_nm_chk
  CHECK (db_nm = UPPER(db_nm))
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_ENV...
CREATE SEQUENCE app_env_seq
/

CREATE TABLE app_env
(
 env_id                        INTEGER DEFAULT ON NULL app_env_seq.NEXTVAL CONSTRAINT aev_env_id_nn NOT NULL
,app_id                        INTEGER CONSTRAINT aev_app_id_nn NOT NULL
,env_nm                        VARCHAR2(80 CHAR) CONSTRAINT aev_env_nm_nn NOT NULL
,db_id                         INTEGER CONSTRAINT aev_db_id_nn NOT NULL
,app_version                   VARCHAR2(20 CHAR)
,owner_account                 VARCHAR2(30 CHAR) CONSTRAINT aev_owner_account_nn NOT NULL
,access_account                VARCHAR2(30 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE app_env IS 'Environment (AEV): Stores the unique environments across the enterprise. Typical environments would be Development, Testing, User Acceptance, Performance, Staging, Production, etc. These environments can be on independent databases, or grouped together on shared databases. Core allows multiple applications per database, and multiple environments per application per database. This approach can save lots of money on Oracle licensing fees. See the Core API documentation for more detail on how to use this feature.';
COMMENT ON COLUMN app_env.env_id IS 'Environment ID: Surrogate key for this table.';
COMMENT ON COLUMN app_env.app_id IS 'Application ID: Foreign key to APP. Combined with an environment name as unique key, ensures that the application can be programatically determined when fed the db_name and current_schema from the System context.';
COMMENT ON COLUMN app_env.env_nm IS 'Environment Name: Identifier for the given environment record, e.g. Development, Testing, Staging, etc.';
COMMENT ON COLUMN app_env.db_id IS 'Database ID: Foreign key to APP_DB. The database in which the schema can be found.';
COMMENT ON COLUMN app_env.app_version IS 'Application Version: Alphanumeric code indicating the version of the application in the given environment. This is typically numeric, eg. version 3.1.1, and typically used by the frontend to display the version in the footer or header or title bar of the application interface.';
COMMENT ON COLUMN app_env.owner_account IS 'Owner Account: The name of the Oracle account or schema where the application''s objects are compiled.';
COMMENT ON COLUMN app_env.access_account IS 'Access Account: The name of the Oracle account or schema to which the application''s interface connects. This is most often an empty account, used by the application server''s connection pool, with permissions to read tables and views, and execute packages contained in the application owner account.';

ALTER TABLE app_env
  ADD CONSTRAINT app_env_pk
  PRIMARY KEY (env_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_env
  ADD CONSTRAINT app_env_uk1
  UNIQUE (app_id, env_nm)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_env
  ADD CONSTRAINT app_env_uk2
  UNIQUE (db_id, owner_account)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_env
  ADD CONSTRAINT aev_db_id_fk
  FOREIGN KEY (db_id)
  REFERENCES app_db (db_id)
/
ALTER TABLE app_env
  ADD CONSTRAINT aev_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/
ALTER TABLE app_env
  ADD CONSTRAINT aev_owner_account_chk
  CHECK (owner_account = UPPER(owner_account))
/
ALTER TABLE app_env
  ADD CONSTRAINT aev_access_account_chk
  CHECK (access_account = UPPER(access_account))
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_PARM...
CREATE SEQUENCE app_parm_seq
/

CREATE TABLE app_parm
(
 parm_id                       INTEGER DEFAULT ON NULL app_parm_seq.NEXTVAL CONSTRAINT ap_parm_id_nn NOT NULL
,parm_nm                       VARCHAR2(500 CHAR) CONSTRAINT ap_parm_nm_nn NOT NULL
,parm_display_nm               VARCHAR2(256 CHAR)
--,parm_default_val              VARCHAR2(4000 CHAR)
,parm_comments                 VARCHAR2(4000 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE app_parm IS 'Parameter (AP): Stores the parameters and configuration values used by the applications across the databases in an enterprise.';
COMMENT ON COLUMN app_parm.parm_id IS 'Parameter ID: Surrogate key for this table.';
COMMENT ON COLUMN app_parm.parm_nm IS 'Parameter Name: The unique name of the parameter. Enforcing a unique constraint on this column reduces redundancy.';
COMMENT ON COLUMN app_parm.parm_display_nm IS 'Parameter Display Name: Optional text used when the parameter is shown in the UI.';
--COMMENT ON COLUMN app_parm.parm_default_val IS 'Parameter Default Value: The default value of the parameter. Can be overriden by the application by using a different value when inserting APP_ENV_PARM.PARM_VAL;';
COMMENT ON COLUMN app_parm.parm_comments IS 'Parameter Comments: Any notes about a parameter that have business value.';

ALTER TABLE app_parm
  ADD CONSTRAINT app_parm_pk
  PRIMARY KEY (parm_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_parm
  ADD CONSTRAINT app_parm_uk
  UNIQUE (parm_nm)
  USING INDEX
  TABLESPACE &&index_tablespace
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_ENV_PARM...
CREATE TABLE app_env_parm
(
 env_id                        INTEGER CONSTRAINT aevp_env_id_nn NOT NULL
,parm_id                       INTEGER CONSTRAINT aevp_parm_id_nn NOT NULL
,parm_val                      VARCHAR2(4000 CHAR)
,hide_yn                       VARCHAR2(1) DEFAULT 'N' CONSTRAINT aevp_hide_yn_nn NOT NULL
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE app_env_parm IS 'Environment Parameter (AEVP): Stores the environment-specific parameters and configuration values used by the applications across the databases in an enterprise.';
COMMENT ON COLUMN app_env_parm.env_id IS 'Environment ID: Foreign key to APP_ENV. The environment wich is configured by the parameter.';
COMMENT ON COLUMN app_env_parm.parm_id IS 'Parameter ID: Foreign key to APP_PARM. The parameter for the environment of the current row.';
COMMENT ON COLUMN app_env_parm.parm_val IS 'Parameter Value: The value of the parameter for a given environment.';
COMMENT ON COLUMN app_env_parm.hide_yn IS 'Hide Y/N: A flag that indicates if the parameter should be hidden from display (Y) or not (N).';

ALTER TABLE app_env_parm
  ADD CONSTRAINT app_env_parm_uk
  UNIQUE (env_id, parm_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/

ALTER TABLE app_env_parm
  ADD CONSTRAINT aevp_env_id_fk
  FOREIGN KEY (env_id)
  REFERENCES app_env (env_id)
/
ALTER TABLE app_env_parm
  ADD CONSTRAINT aevp_parm_id_fk
  FOREIGN KEY (parm_id)
  REFERENCES app_parm (parm_id)
/
ALTER TABLE app_env_parm
  ADD CONSTRAINT aep_hide_yn_chk
  CHECK (hide_yn IN ('Y','N'))
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_EMAIL...
CREATE SEQUENCE app_email_seq
/

CREATE TABLE app_email
(
 email_id                       INTEGER DEFAULT ON NULL app_email_seq.NEXTVAL CONSTRAINT aem_email_id_nn NOT NULL
,crt_dt                         DATE NOT NULL
,app_id                         INTEGER CONSTRAINT aem_app_id_nn NOT NULL
,email_to                       VARCHAR2(4000 CHAR) CONSTRAINT aem_email_to_nn NOT NULL
,email_subject                  VARCHAR2(500  CHAR) CONSTRAINT aem_email_subject_nn NOT NULL
,email_body                     VARCHAR2(4000 CHAR) CONSTRAINT aem_email_body_nn NOT NULL
,long_body                      CLOB
,email_from                     VARCHAR2(500  CHAR)
,email_replyto                  VARCHAR2(500  CHAR)
,email_cc                       VARCHAR2(4000 CHAR)
,email_bcc                      VARCHAR2(4000 CHAR)
,email_extra                    VARCHAR2(4000 CHAR)
,sent_status                    VARCHAR2(20) DEFAULT 'Not Sent' CONSTRAINT aem_sent_status_nn NOT NULL
,sent_dt                        DATE
,smtp_error                     VARCHAR2(4000 CHAR)
,otx_sync_col                   VARCHAR2(1) DEFAULT 'N' CONSTRAINT aem_otx_sync_col_nn NOT NULL
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
/

COMMENT ON TABLE  app_email IS 'Email (AEM): Generic table for use in applications that have email requirements.';
COMMENT ON COLUMN app_email.email_id IS 'Email ID: Surrogate key for this table.';
COMMENT ON COLUMN app_email.crt_dt IS 'Create Date: Date and time (down to the second) when the email was created/generated, written to this table, and attempted to send.';
COMMENT ON COLUMN app_email.app_id IS 'Application ID: Foreign key to APP. The application which "owns" the emailed info.';
COMMENT ON COLUMN app_email.email_to IS 'To: Standard email To field.';
COMMENT ON COLUMN app_email.email_subject IS 'Subject: Standard email Subject field.';
COMMENT ON COLUMN app_email.email_body IS 'Body: Standard email Body field.';
COMMENT ON COLUMN app_email.long_body IS 'Long Body: If the email body is greater than the maximum possible length of the email_body column (currently 4000 characters), the entire body will be stored here, and the truncated body will be kept in the email_body column.';
COMMENT ON COLUMN app_email.email_from IS 'From: Standard email From field.';
COMMENT ON COLUMN app_email.email_replyto IS 'Reply-To: Standard email Reply-To field.';
COMMENT ON COLUMN app_email.email_cc IS 'CC: Standard email CC field.';
COMMENT ON COLUMN app_email.email_bcc IS 'BCC: Standard email BCC field.';
COMMENT ON COLUMN app_email.email_extra IS 'Extra Info: Flexible field for unforseen email header or MIME protocol stuff.';
COMMENT ON COLUMN app_email.sent_status IS 'Status: Indicates whether the email was sent or not. Valid values are Not Sent, Sent, Send Pending and Error.';
COMMENT ON COLUMN app_email.sent_dt IS 'Sent Time: Timestamp issued when the email is sent successfully.';
COMMENT ON COLUMN app_email.smtp_error IS 'SMTP Error: Context surrounding any errors received from the SMTP server. This should probably be the error code, followed by the error message or JavaMail error stack, depending on the implementation you choose to use.';
COMMENT ON COLUMN app_email.otx_sync_col IS 'Oracle Text Syncronization Column: Used by Oracle Text as both the "dummy" column for the MULTI_COLUMN_DATASTORE, and the search column when using the CONTAINS operator in queries. If any of the columns in the multi-column context index are updated, set this column to Y indicating it is in need of a CTX_DDL sync operation.';

ALTER TABLE app_email
  ADD CONSTRAINT app_email_pk
  PRIMARY KEY (email_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_email
  ADD CONSTRAINT aem_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/
CREATE INDEX aem_app_id_idx ON app_email (app_id)
  TABLESPACE &&index_tablespace
/

ALTER TABLE app_email
  ADD CONSTRAINT aem_sent_status_chk
  CHECK (sent_status IN ('Not Sent','Error','Send Pending','Sent'))
/
ALTER TABLE app_email
  ADD CONSTRAINT aem_otx_sync_col_chk
  CHECK (otx_sync_col IN ('Y','N'))
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_EMAIL_DOC...
CREATE SEQUENCE app_email_doc_seq
/

CREATE TABLE app_email_doc
(
 email_doc_id                   INTEGER DEFAULT ON NULL app_email_doc_seq.NEXTVAL CONSTRAINT aemd_email_doc_id_nn NOT NULL
,email_id                       INTEGER CONSTRAINT aemd_email_id_nn NOT NULL
,file_nm                        VARCHAR2(1024 CHAR) CONSTRAINT aemd_file_nm_nn NOT NULL
,doc_content                    BLOB
,doc_size                       NUMBER
,mime_type                      VARCHAR2(128 BYTE)
,otx_doc_type                   VARCHAR2(10 BYTE)
,otx_lang_cd                    VARCHAR2(2 BYTE)
,otx_charset_cd                 VARCHAR2(30 BYTE)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
/

COMMENT ON TABLE  app_email_doc IS 'Email Documents/Attachments (AEMD): Large textual or binary attachments sent out with emails recorded in APP_EMAIL.';
COMMENT ON COLUMN app_email_doc.email_doc_id IS 'Email Document ID: Surrogate key for this table.';
COMMENT ON COLUMN app_email_doc.email_id IS 'Email ID: Identifying key that ties an attachment to an email. Foreign key to the APP_EMAIL table.';
COMMENT ON COLUMN app_email_doc.file_nm IS 'Document Name: The full file name of the doc, including file extension. Certain document records can just be pointers to external sources; in which case, use this column to store the full URI to the external document. FILE_NAME was used (instead of DOC_NM), because uploading with OWS/OAS/9iAS required this name.';
COMMENT ON COLUMN app_email_doc.doc_content IS 'Document Content: The text or binary contents of the stored document.';
COMMENT ON COLUMN app_email_doc.doc_size IS 'Document Size: The size in bytes of the doc. This can be converted to a virtual column when we upgrade to 11g.';
COMMENT ON COLUMN app_email_doc.mime_type IS 'MIME Type: The standard MIME type of the doc, e.g. application/msexcel, application/msword, application/octet-stream, text/html, text/plain, image/jpg, etc.';
COMMENT ON COLUMN app_email_doc.otx_doc_type IS 'Oracle Text Document Type: Used only by Oracle Text. Valid values are IGNORE, TEXT or BINARY. IGNORE is used for records that you wish Oracle Text to skip when indexing, like images.';
COMMENT ON COLUMN app_email_doc.otx_lang_cd IS 'Oracle Text Language Code: Used only by Oracle Text. Valid values are one of the language codes recognized by Oracle. See http://download.oracle.com/docs/cd/B19306_01/server.102/b14225/applocaledata.htm#i634428.';
COMMENT ON COLUMN app_email_doc.otx_charset_cd IS 'Oracle Text Characterset Code: Used only by Oracle Text. Valid values are one of the characterset codes recognized by Oracle. See http://download.oracle.com/docs/cd/B19306_01/server.102/b14225/applocaledata.htm#i635016.';

ALTER TABLE app_email_doc
  ADD CONSTRAINT app_email_doc_pk
  PRIMARY KEY (email_doc_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_email_doc
  ADD CONSTRAINT app_email_doc_uk
  UNIQUE (email_id, file_nm)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_email_doc
   ADD CONSTRAINT aemd_email_id_fk
   FOREIGN KEY (email_id)
   REFERENCES app_email(email_id)
/
CREATE INDEX aemd_email_id_idx ON app_email_doc(email_id)
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_email_doc
  ADD CONSTRAINT aemd_otx_doc_type_chk
  CHECK (otx_doc_type IN ('IGNORE','TEXT','BINARY'))
/

-------------------------------------------------------------------------------
--CREATE SEQUENCE TABLE app_lang_seq
--/

--PROMPT Creating table APP_LANG...
--CREATE TABLE app_lang
--(
--  lang_id                       INTEGER DEFAULT ON NULL app_lang_seq.NEXTVAL CONSTRAINT alang_lang_id_nn NOT NULL,
--  lang_nm                       VARCHAR2(255 CHAR) CONSTRAINT alang_lang_nm_nn NOT NULL,
--  iana_lang_cd                  VARCHAR2(3 CHAR),
--  iso_lang_cd                   VARCHAR2(2 CHAR),
--  oracle_lang_cd                VARCHAR2(3 CHAR)
--)
--TABLESPACE &&default_tablespace
--PCTFREE 10 PCTUSED 90
--CACHE
--/
--
--COMMENT ON TABLE app_lang IS 'Languages (ALANG): Stores the different written languages that the application may support.';
--COMMENT ON COLUMN app_lang.lang_id IS 'Language ID: Surrogate key for the Application Language table.';
--COMMENT ON COLUMN app_lang.lang_nm IS 'Language Name: Common name for the given language.';
--COMMENT ON COLUMN app_lang.iana_lang_cd IS 'IANA Language Code: A two letter language code as defined by the IANA standards body.  For more information refer to http://www.iana.org/assignments/language-subtag-registry .';
--COMMENT ON COLUMN app_lang.iso_lang_cd IS 'ISO Language Code: A two letter language code as defined by ISO-639. For more information refer to http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt and http://www.loc.gov/standards/iso639-2/php/code_list.php .';
--COMMENT ON COLUMN app_lang.oracle_lang_cd IS 'Oracle Language Code: A two to three letter code, not quite to standard, for the languages recognized by Oracle.';
--
--ALTER TABLE app_lang
--  ADD CONSTRAINT app_lang_pk
--  PRIMARY KEY (lang_id)
--  USING INDEX
--  TABLESPACE &&index_tablespace
--/
--
--ALTER TABLE app_lang
--  ADD CONSTRAINT app_lang_uk
--  UNIQUE (lang_nm)
--  USING INDEX
--  TABLESPACE &&index_tablespace
--/
--
--ALTER TABLE app_lang
--  ADD CONSTRAINT alang_iso_lang_code_chk
--  CHECK (iso_lang_code IS NULL OR (iso_lang_code = LOWER(iso_lang_code))
--/
--ALTER TABLE app_lang
--  ADD CONSTRAINT alang_iana_lang_code_chk
--  CHECK (iana_lang_code IS NULL OR (iana_lang_code = LOWER(iana_lang_code))
--/
--ALTER TABLE app_lang
--  ADD CONSTRAINT alang_oracle_lang_code_chk
--  CHECK (oracle_lang_code IS NULL OR (oracle_lang_code = LOWER(oracle_lang_code))
--/

-------------------------------------------------------------------------------
/*
Design Notes:
 The following two tables are only included for development shops where some
pointy-haired boss insists on a single table for "type", aka "lookup" or "code"
tables. In general, a single structure for codes is a bad idea (based on years
of experience from numerous experts, my own personal disasters with it, and
articles you can find on the web about it (see Hoberman below)).

APP_CODESET and APP_CODE should never be used in larg, intensive environments.
Also the use of a common table for codes and lookup values does not allow child
tables to constrain their allowable values to subsets of the code pool. Foreign
keys only let you constrain to a table, not rows within a table. So from a
purist data modeling standpoint, a common lookup table is a bad idea. But in two
of the environments the author worked in, the developers complained about
hundreds of lookup tables -- even more so at a company where each lookup code
set also required another table to contain the i18n translations for each code -
- and the Java architects complained about having to create separate classes
(even with code generators in place) for each lookup code table. In both
environments.

See Also:
  Steve Hoberman (data modeling guru) and thousands of his followers agree that a
generic code model is the wrong approach for most. See
http://www.information-management.com/issues/20061201/1069942-1.html

Summary:
 The code pool created by the two tables below should suffice for most environements,
but proceed with caution since folks like Jonathan Lewis have shown how such
common code tables can wreak havoc with the optimizer in environments with large
tables and queries that demand the best access paths possible.
*/
--CREATE SEQUENCE app_codeset_seq
--/
--
--PROMPT Creating table APP_CODESET...
--CREATE TABLE app_codeset
--(
-- codeset_id                     INTEGER DEFAULT ON NULL app_codeset_seq.NEXTVAL CONSTRAINT acs_codeset_id_nn NOT NULL
--,app_id                         INTEGER CONSTRAINT acs_app_id_nn NOT NULL
--,codeset_nm                     VARCHAR2(60 CHAR)
--,codeset_defn                   VARCHAR2(255 CHAR)
--,parent_codeset_id              INTEGER
--,active_flg                     VARCHAR2(1 BYTE) DEFAULT 'Y' acs_active_flg_nn NOT NULL
--)
--TABLESPACE &&default_tablespace
--PCTFREE 10 PCTUSED 90
--CACHE
--/
--
--COMMENT ON TABLE app_codeset IS 'Codesets (ACS): Lookup table for names given to groups of related codes in the Code table. Common codeset names will be "Priority", "Request Status", etc.';
--COMMENT ON COLUMN app_codeset.codeset_id IS 'Codeset ID: Surrogate key for this table.';
--COMMENT ON COLUMN app_codeset.app_id IS 'Application ID: Foreign key to APP. This allows a subsystem to "own" a collection of codesets, that would otherwise conflict with other systems due to duplication. For example, almost every application has status codes. If not for including app_id in the AK for this table, there could only be one set of status codes for all users of this framework.';
--COMMENT ON COLUMN app_codeset.codeset_nm IS 'Codeset Name: Name for the unique code grouping.';
--COMMENT ON COLUMN app_codeset.codeset_defn IS 'Codeset Definition: Long name or short definition of the codeset''s purpose.';
--COMMENT ON COLUMN app_codeset.parent_codeset_id IS 'Parent Codeset ID: Self-referring foreign key. Filled if one set of codes belongs "underneath" or "within" another grouping or codeset.';
--COMMENT ON COLUMN app_codeset.active_flg IS 'Active Flag: Flag that indicates if the record is active (Y) or not (N).';
--
--ALTER TABLE app_codeset
--  ADD CONSTRAINT app_codeset_pk
--  PRIMARY KEY (codeset_id)
--  USING INDEX
--  TABLESPACE &&index_tablespace
--/
---- The inclusion of app_id in the AK allows multiple applications with equivalent
---- codeset names to co-exist in the same database using the same codeset table.
---- The inclusion of ACTIVE_FLG in the AK gives an application data owner the ability
---- to turn off an entire set of codes and activate a fresh set (with the same
---- codeset name).
--ALTER TABLE app_codeset
--  ADD CONSTRAINT app_codeset_uk
--  UNIQUE (app_id, codeset_nm, active_flg)
--  USING INDEX
--  TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_codeset
--  ADD CONSTRAINT acs_app_id_fk
--  FOREIGN KEY (app_id)
--  REFERENCES app (app_id)
--/
--ALTER TABLE app_codeset
--  ADD CONSTRAINT acs_parent_codeset_id_fk
--  FOREIGN KEY (parent_codeset_id)
--  REFERENCES app_codeset (codeset_id)
--/
--CREATE INDEX acs_parent_codeset_id_idx
--  ON app_codeset(parent_codeset_id)
--  TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_codeset
--  ADD CONSTRAINT acs_active_flg_chk
--  CHECK (active_flg IN ('Y','N'))
--/
--
---------------------------------------------------------------------------------
--CREATE SEQUENCE app_code_seq
--/
--
--PROMPT Creating table APP_CODE...
--CREATE TABLE app_code
--(
-- code_id                        INTEGER DEFAULT ON NULL app_code_seq.NEXTVAL CONSTRAINT acd_code_id_nn NOT NULL
--,codeset_id                     INTEGER CONSTRAINT acd_codeset_id_nn NOT NULL
--,code_val                       VARCHAR2(30 CHAR) CONSTRAINT acd_code_val_nn NOT NULL
--,code_defn                      VARCHAR2(255 CHAR)
--,display_order                  INTEGER
--,editable_flg                   VARCHAR2(1) DEFAULT 'N' CONSTRAINT acd_editable_flg_nn NOT NULL
--,active_flg                     VARCHAR2(1) DEFAULT 'Y' CONSTRAINT acd_active_flg_nn NOT NULL
--,parent_code_id                 INTEGER
--)
--TABLESPACE &&default_tablespace
--PCTFREE 10 PCTUSED 90
--CACHE
--/
--
--COMMENT ON TABLE  app_code IS 'Codes (ACD): Generic table for storing trivial reference values, like priority, status, etc. Create separate reference tables for non-trivial reference codes. Non-trivial codes would be those that are critical to the business, upon which most queries hang, which change frequently, or which have unique attributes that don''t fit here.';
--COMMENT ON COLUMN app_code.code_id IS 'Code ID: Surrogate key for this table';
--COMMENT ON COLUMN app_code.codeset_id IS 'Codeset ID: Foreign key to APP_CODESET. Allows related codes to be grouped together.';
--COMMENT ON COLUMN app_code.code_val IS 'Code Value: Stores generic codes for a given system and codeset. Although it is an alpha column, it can store purely numeric codes as well.';
--COMMENT ON COLUMN app_code.code_defn IS 'Code Definition: Short description or definition, usually tied to a short code or abbreviation that needs some explanation.';
--COMMENT ON COLUMN app_code.display_order IS 'Display Order: In case the users wish one set of values to be ordered in a non-alphabetical manner, this allows them to customize the ordering of values.';
--COMMENT ON COLUMN app_code.editable_flg IS 'Editable Flag: Flag that indicates if the code''s value should be editable through a UI (Y), or if it should never be edited (N). If there is logic in code that depends on a static code value, then this column should be set to N.';
--COMMENT ON COLUMN app_code.active_flg IS 'Active Flag: Flag that indicates if the record is active (Y) or not (N).';
--COMMENT ON COLUMN app_code.parent_code_id IS 'Parent Code ID: Self-referring foreign key. Filled if one codes belongs "underneath" a higher code.';
--
--ALTER TABLE app_code
--  ADD CONSTRAINT app_code_pk
--  PRIMARY KEY (code_id)
--  USING INDEX
--  TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_code
--  ADD CONSTRAINT app_code_uk
--  UNIQUE (codeset_id, code_val)
--  USING INDEX
--  TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_code
--  ADD CONSTRAINT acd_codeset_id_fk
--  FOREIGN KEY (codeset_id)
--  REFERENCES app_codeset (codeset_id)
--/
--CREATE INDEX acd_codeset_id_idx
--  ON app_code (codeset_id)
--  TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_code
--  ADD CONSTRAINT acd_parent_code_id_fk
--  FOREIGN KEY (parent_code_id)
--  REFERENCES app_code (code_id)
--/
--CREATE INDEX acd_parent_code_id_idx
--  ON app_code (parent_code_id)
--  TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_codeset
--  ADD CONSTRAINT acd_editable_flg_chk
--  CHECK (active_flg IN ('Y','N'))
--/
--ALTER TABLE app_codeset
--  ADD CONSTRAINT acd_active_flg_chk
--  CHECK (active_flg IN ('Y','N'))
--/

/*------------------------------------------------------------------------------
Design Notes:
The app_lock table is meant to accommodate several sorts of pessimistic locks.
This table, and its PL/SQL package (API_APP_LOCK) were originally designed to
hold large-grained logical locks for special systems that could not allow
two replicas of the same batch process to run concurrently. It was extended to
allow row-level locks as well, but frankly, if you need row-level locks, you
should use Oracle's native mechanisms to do that (DBMS_LOCK, transactions and
SELECT FOR UPDATE).

If you do choose to use this feature for logical, pessimistic locking, you should
know a few rules:

1) A lock must have a fixed name upon which all cooperating parties agree.
This can be the name of a process, screen, operation, etc. for large-grained
locks. Or if locking a table, the lock name must be the table name.

2) Finer-grained locks are possible by passing in the PK ID of the row you wish to
lock (when the row has a single-column PK), or the ROWID of the row you wish to
lock (when the PK is multi-column or from an IOT). Since the column locked_obj_id
is VARCHAR2, numeric PK IDs will be implicitly converted to string unless you
do so explicitly.

3) A lock must indicate which system requested requested it (app_id), and who or
what requested and received the lock (locker_id). If the lock requester is a
PL/SQL routine, pass in the package.routine name for the locker_id.

4) The locker_ip is optional.

If you decide to make use of this feature of Core, it needs to be used
consistently. The lock methods and lock naming scheme would need to be agreed
upon prior to the application attempting lock coordination.

Here is the general process for making use of Core's locking feature:
a) Before beginning a query, process or operation (whatever your chosen level
of granularity for locking), request a lock (api_app_lock.get_lock).
b) If the lock is already held by someone else, handle it (best option is usually
to error out, returning info on the existing lock to the user and the log so
that support can track it down and release it).
   If the lock is granted, proceed.
c) After committing changes or rolling back due to exception handling, release
the lock (api_app_lock.del_lock).

This strategy totally breaks down if the other concurrent processes or users
don't check for existing locks. So the success of these locks depends on a tech
lead reviewing code to ensure Core locking is being used correctly.

Note that the i_locked_obj_rid parameter of get_lock is provided as a mutually
exclusive alternative to i_locked_obj_id due to lock records on an IOT or on a
heap table where the PK or UK is composed of more than one column. In these
cases, pass the ROWID in as i_locked_obj_rid instead of the PK as i_locked_obj_id.
*/
CREATE SEQUENCE app_lock_seq
/

PROMPT Creating table APP_LOCK...
CREATE TABLE app_lock
(
 lock_id                        INTEGER DEFAULT ON NULL app_lock_seq.NEXTVAL CONSTRAINT alk_id_nn NOT NULL
,app_id                         INTEGER CONSTRAINT alk_app_id_nn NOT NULL
,lock_nm                        VARCHAR2(255 CHAR) CONSTRAINT alk_lock_nm_nn NOT NULL
,locked_obj_id                  VARCHAR2(60 CHAR)
,locked_obj_rid                 UROWID
,locker_ip                      VARCHAR2(40 BYTE)
,locker_id                      VARCHAR2(64 CHAR) CONSTRAINT alk_locker_id_nn NOT NULL
,locked_dtm                     DATE CONSTRAINT alk_locked_dtm_nn NOT NULL
)
TABLESPACE &&default_tablespace
PCTFREE 20 PCTUSED 80
/

COMMENT ON TABLE app_lock IS 'Logical Locks (ALK): Stores logical locks for applications that have pessimistic locking requirements.';
COMMENT ON COLUMN app_lock.lock_id IS 'Lock ID: Surrogate key for this table.';
COMMENT ON COLUMN app_lock.app_id IS 'Application ID: Foreign key to APP. The application which "owns" the lock.';
COMMENT ON COLUMN app_lock.lock_nm IS 'Lock Name: Fixed name upon which parties involved in lock coordination have agreed. This could be the name of the screen, process, module, or simply the name of a table. This, combined with the ID or RID, provides the unique key to any given lock.';
COMMENT ON COLUMN app_lock.locked_obj_id IS 'Locked Object ID: Primary key to the row of data to lock. Required for fine-grained locks.';
COMMENT ON COLUMN app_lock.locked_obj_rid IS 'Locked Object Rowid: The extended (ROWID) or logical rowid (UROWID) of the record being locked.';
COMMENT ON COLUMN app_lock.locker_ip IS 'Locker IP Address: IP address in IPv4 or IPv6 format of the client from which the user which obtained the lock. Use this value to inform concurrent lock requesters who they have to contact if they want to modify the data behind the lock.';
COMMENT ON COLUMN app_lock.locker_id IS 'Locker ID: Any valid identifier for a system, process, account, role or user requesting the lock. There needs to be a way to track who is holding a lock, so this value needs to be as specific and traceable as possible.';
COMMENT ON COLUMN app_lock.locked_dtm IS 'Lock Date and Time: When the lock was granted.';

ALTER TABLE app_lock
  ADD CONSTRAINT app_lock_pk
  PRIMARY KEY (lock_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/

/*
Note: app_id is not included in the UK on purpose. If this doesn't fit your needs,
include it, but consider the ramifications for your environment. app_id is only
included in the table so that an administrator over the entire DB could look at the
contents of APP_LOCK and determine what each application was doing with locks.
*/
ALTER TABLE app_lock
   ADD CONSTRAINT app_lock_uk
   UNIQUE (lock_nm, locked_obj_id, locked_obj_rid)
   USING INDEX
   TABLESPACE &&index_tablespace
/
ALTER TABLE app_lock
  ADD CONSTRAINT alk_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/
CREATE INDEX alk_app_id_idx ON app_lock (app_id)
  TABLESPACE &&index_tablespace
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_MSG...
CREATE SEQUENCE app_msg_seq
/

CREATE TABLE app_msg
(
 msg_id                         INTEGER DEFAULT ON NULL app_msg_seq.NEXTVAL CONSTRAINT am_msg_id_nn NOT NULL
,app_id                         INTEGER CONSTRAINT am_app_id_nn NOT NULL
,msg_cd                         VARCHAR2(60 CHAR) CONSTRAINT am_msg_cd_nn NOT NULL
,msg                            VARCHAR2(255 CHAR) CONSTRAINT am_msg_nn NOT NULL
,msg_descr                      VARCHAR2(4000 CHAR)
,msg_soln                       VARCHAR2(4000 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 20 PCTUSED 80
CACHE
/

COMMENT ON TABLE app_msg IS 'Standard Messages (AM): Stores static messages and dynamic message templates used within the systems sharing Core. Static messages are repeated in logging targets as-is. Message templates have placeholder symbols that allow contextual substitution at runtime (which allows a higher degree of message re-use within and across systems).';
COMMENT ON COLUMN app_msg.msg_id IS 'Message ID: Surrogate key for this table.';
COMMENT ON COLUMN app_msg.app_id IS 'Application ID: Foreign key to APP. Even though this column indicates which application "owns" the message, the row can and should be re-used by other applications if applicable. This is why the natural key does not include app_id.';
COMMENT ON COLUMN app_msg.msg_cd IS 'Message Code: Short code or name that identifies a message within a given subsystem.';
COMMENT ON COLUMN app_msg.msg IS 'Message: The full text of the standard message or message template. If the message is a template with placeholders, surround the substitutable placeholders with the substitution character defined in the C package (default is @).';
COMMENT ON COLUMN app_msg.msg_descr IS 'Message Description: If the message text contains placeholders, e.g. "@1@ not allowed to read from table @2@", this field provides a place to describe what those placeholders mean. In the example provided here, the MSG_DESC could be "1 = app.app_cd, 2 = table name being read."';
COMMENT ON COLUMN app_msg.msg_soln IS 'Message Solution: Optional steps, hints, or actions the user might take to report or solve the problem on their own.';

ALTER TABLE app_msg
  ADD CONSTRAINT app_msg_pk
  PRIMARY KEY (msg_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_msg
   ADD CONSTRAINT app_msg_uk
   UNIQUE (msg_cd)
   USING INDEX
   TABLESPACE &&index_tablespace
/
ALTER TABLE app_msg
  ADD CONSTRAINT am_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_EVENT...
CREATE SEQUENCE app_event_seq
/

CREATE TABLE app_event
(
 event_id                       INTEGER DEFAULT /*ON NULL app_event_seq.NEXTVAL */CONSTRAINT aevt_log_id_nn NOT NULL
,app_id                         INTEGER CONSTRAINT aevt_app_id_nn NOT NULL
,env_id                         INTEGER CONSTRAINT aevt_env_id_nn NOT NULL
,evt_ts                         TIMESTAMP CONSTRAINT aevt_evt_ts_nn NOT NULL
,name                           VARCHAR2(4000 CHAR) CONSTRAINT aevt_name_nn NOT NULL
,routine_nm                     VARCHAR2(256 CHAR)
,line_num                       INTEGER
,call_stack                     VARCHAR2(4000 CHAR)
,error_stack                    VARCHAR2(4000 CHAR)
,client_id                      VARCHAR2(80 CHAR)
,client_ip                      VARCHAR2(40 CHAR)
,client_host                    VARCHAR2(40 CHAR)
,client_os_user                 VARCHAR2(100 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
/

COMMENT ON TABLE  app_event IS 'Events (AEVT): Application event table. This table dovetails with the LOGS package. This table is one of the output targets for logging and debugging. All debugging goes to this table by default. But application and error logging only gets written here if the targets are turned on using logs.set_targets.';
COMMENT ON COLUMN app_event.event_id IS 'Event ID: Surrogate key for this table.';
COMMENT ON COLUMN app_event.app_id IS 'Application ID: Foreign key to APP. The application which "owns" the logged row.';
COMMENT ON COLUMN app_event.env_id IS 'Environment ID: Foreign key to APP_ENV. The environment wich is configured by the parameter.';
COMMENT ON COLUMN app_event.evt_ts IS 'Event Timestamp: Timestamp of log entry.';
COMMENT ON COLUMN app_event.name IS 'Event name: Column of free-form text for event, debugging and informational/context recording.';
COMMENT ON COLUMN app_event.routine_nm IS 'Routine Name: The name of the trigger, type body, object method, standalone function or procedure, or packaged routine (in package.routine format) which generated the log message.';
COMMENT ON COLUMN app_event.line_num IS 'Line Number: The line number the caller or the framework determined should be referenced in the ROUTINE_NM for this log record.';
COMMENT ON COLUMN app_event.call_stack IS 'Call Stack: The full call stack. Will be 10g-flavored if on 11g or 10g. Will be the UTL_CALL_STACK (12c) version if on 12c or higher.';
COMMENT ON COLUMN app_event.error_stack IS 'Error Stack: The full error stack and backtrace. Will be empty if no error is present at the time of logging.';
COMMENT ON COLUMN app_event.client_id IS 'Client Identifier: Optional unique identifier for the end user or automated process responsible for the generation of the log message. This can be set by the frontend using ENV.INIT_CLIENT_CTX, but will default to something useful if it has not been set.';
COMMENT ON COLUMN app_event.client_ip IS 'Client IP: Optional IPv4 or IPv6 address of the client machine.';
COMMENT ON COLUMN app_event.client_host IS 'Client Host: Optional name of the machine the client is connecting from. For direct connections (application servers, end users with SQL*Plus, OEM, Forms, DBA tools, etc.), this is available from the USERENV context using the ''host'' parameter. For 3 and n-tier applications, if you desire to store the name of the machine the end user is operating from, the application server would have to obtain it from the user''s environment and set it using env.init_client_ctx() upon connection.';
COMMENT ON COLUMN app_event.client_os_user IS 'Client OS User: The name of the logged in account on the operating system from which the client or user is connecting. This can be set by the application using env.init_client_ctx() upon connection.';

ALTER TABLE app_event
  ADD CONSTRAINT app_event_pk
  PRIMARY KEY (event_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_event
  ADD CONSTRAINT aevt_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/
ALTER TABLE app_event
  ADD CONSTRAINT aevt_env_id_fk
  FOREIGN KEY (env_id)
  REFERENCES app_env (env_id)
/
CREATE INDEX aevt_app_id_idx ON app_event (app_id)
  TABLESPACE &&index_tablespace
/
CREATE INDEX aevt_routine_nm_idx ON app_event (routine_nm)
  TABLESPACE &&index_tablespace
/

-------------------------------------------------------------------------------
PROMPT Creating table APP_LOG...
CREATE SEQUENCE app_log_seq
/

CREATE TABLE app_log
(
 log_id                         INTEGER DEFAULT ON NULL app_log_seq.NEXTVAL CONSTRAINT alg_log_id_nn NOT NULL
,event_id                       INTEGER NULL
,app_id                         INTEGER CONSTRAINT alg_app_id_nn NOT NULL
,env_id                         INTEGER CONSTRAINT alg_env_id_nn NOT NULL
,log_ts                         TIMESTAMP CONSTRAINT alg_log_ts_nn NOT NULL
,sev_cd                         VARCHAR2(30 CHAR) CONSTRAINT alg_sev_cd_nn NOT NULL
,msg_cd                         VARCHAR2(60 CHAR)
,routine_nm                     VARCHAR2(256 CHAR)
,line_num                       INTEGER
,log_txt                        VARCHAR2(4000 CHAR)
,call_stack                     VARCHAR2(4000 CHAR)
,error_stack                    VARCHAR2(4000 CHAR)
,client_id                      VARCHAR2(80 CHAR)
,client_ip                      VARCHAR2(40 CHAR)
,client_host                    VARCHAR2(40 CHAR)
,client_os_user                 VARCHAR2(100 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
/

COMMENT ON TABLE  app_log IS 'Logs (ALG): Application logging table. This table dovetails with the LOGS package. This table is one of the output targets for logging and debugging. All debugging goes to this table by default. But application and error logging only gets written here if the targets are turned on using logs.set_targets.';
COMMENT ON COLUMN app_log.log_id IS 'Log ID: Surrogate key for this table.';
COMMENT ON COLUMN app_log.event_id IS 'Event ID: Foreign Key to the Event table.';
COMMENT ON COLUMN app_log.app_id IS 'Application ID: Foreign key to APP. The application which "owns" the logged row.';
COMMENT ON COLUMN app_log.env_id IS 'Environment ID: Foreign key to APP_ENV. The environment wich is configured by the parameter.';
COMMENT ON COLUMN app_log.log_ts IS 'Log Timestamp: Timestamp of log entry.';
COMMENT ON COLUMN app_log.sev_cd IS 'Severity: Currently limited to ERROR, WARN, INFO and DEBUG. AUDIT-class messages are supposed to be logged to APP_CHG_LOG[_DTL], not here. This column classifies the log/message entries in varying degrees of severity.';
COMMENT ON COLUMN app_log.msg_cd IS 'Message Code: Foreign key to APP_MSG. Optional short code or name that groups similar messages within a system. This allows large quantities of log messages to be filtered, categorized and reported efficiently.';
COMMENT ON COLUMN app_log.routine_nm IS 'Routine Name: The name of the trigger, type body, object method, standalone function or procedure, or packaged routine (in package.routine format) which generated the log message.';
COMMENT ON COLUMN app_log.line_num IS 'Line Number: The line number the caller or the framework determined should be referenced in the ROUTINE_NM for this log record.';
COMMENT ON COLUMN app_log.log_txt IS 'Log Text: Column of free-form text for logging, debugging and informational/context recording.';
COMMENT ON COLUMN app_log.call_stack IS 'Call Stack: The full call stack. Will be 10g-flavored if on 11g or 10g. Will be the UTL_CALL_STACK (12c) version if on 12c or higher.';
COMMENT ON COLUMN app_log.error_stack IS 'Error Stack: The full error stack and backtrace. Will be empty if no error is present at the time of logging.';
COMMENT ON COLUMN app_log.client_id IS 'Client Identifier: Optional unique identifier for the end user or automated process responsible for the generation of the log message. This can be set by the frontend using ENV.INIT_CLIENT_CTX, but will default to something useful if it has not been set.';
COMMENT ON COLUMN app_log.client_ip IS 'Client IP: Optional IPv4 or IPv6 address of the client machine.';
COMMENT ON COLUMN app_log.client_host IS 'Client Host: Optional name of the machine the client is connecting from. For direct connections (application servers, end users with SQL*Plus, OEM, Forms, DBA tools, etc.), this is available from the USERENV context using the ''host'' parameter. For 3 and n-tier applications, if you desire to store the name of the machine the end user is operating from, the application server would have to obtain it from the user''s environment and set it using env.init_client_ctx() upon connection.';
COMMENT ON COLUMN app_log.client_os_user IS 'Client OS User: The name of the logged in account on the operating system from which the client or user is connecting. This can be set by the application using env.init_client_ctx() upon connection.';

ALTER TABLE app_log
  ADD CONSTRAINT app_log_pk
  PRIMARY KEY (log_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_log
  ADD CONSTRAINT alg_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/
ALTER TABLE app_log
  ADD CONSTRAINT alg_env_id_fk
  FOREIGN KEY (env_id)
  REFERENCES app_env (env_id)
/
CREATE INDEX alg_app_id_idx ON app_log (app_id)
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_log
  ADD CONSTRAINT alg_msg_cd_fk
  FOREIGN KEY (msg_cd)
  REFERENCES app_msg (msg_cd)
/
ALTER TABLE app_log
  ADD CONSTRAINT alg_event_id_fk
  FOREIGN KEY (event_id)
  REFERENCES app_event (event_id)
/
CREATE INDEX alg_msg_cd_idx ON app_log (msg_cd)
  TABLESPACE &&index_tablespace
/
CREATE INDEX alg_sev_cd_idx ON app_log (sev_cd)
  TABLESPACE &&index_tablespace
/
CREATE INDEX alg_routine_nm_idx ON app_log (routine_nm)
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_log
  ADD CONSTRAINT alg_sev_cd_chk
  CHECK (sev_cd IN ('ERROR','WARN','INFO','DEBUG'))
/
CREATE UNIQUE INDEX alg_event_idx ON app_log (event_id, log_id)
  TABLESPACE &&index_tablespace
/

/*
 Chose not to place yet another index on log_ts, as ordering by
 log_id DESC should serve the requirement to see this data in reverse
 chronological order just fine. Also logging to this table needs to be fast to
 lessen overhead, and it already has four indexes.
*/

-------------------------------------------------------------------------------
--PROMPT Creating table APP_SQL...
--CREATE SEQUENCE app_sql_seq
--/
--
--CREATE TABLE app_sql
--(
-- sql_id                         INTEGER DEFAULT ON NULL app_sql_seq.NEXTVAL CONSTRAINT asql_sql_id_nn NOT NULL
--,app_id                         INTEGER CONSTRAINT asql_app_id_nn NOT NULL
--,sql_nm                         VARCHAR2(255 CHAR) CONSTRAINT asql_sql_nm_nn NOT NULL
----,group_id                       VARCHAR2(255 CHAR)
--,user_id                        INTEGER CONSTRAINT asql_user_id_nn NOT NULL
--,sql_type                       VARCHAR2(40 CHAR)
--,dml_stmt                       VARCHAR2(4000 CHAR)
--,from_txt                       VARCHAR2(4000 CHAR)
--,where_txt                      VARCHAR2(4000 CHAR)
--,group_by_txt                   VARCHAR2(4000 CHAR)
--,having_txt                     VARCHAR2(4000 CHAR)
--,order_by_txt                   VARCHAR2(4000 CHAR)
--)
--TABLESPACE &&default_tablespace
--PCTFREE 20 PCTUSED 80
--CACHE
--/
--
--COMMENT ON TABLE app_sql IS 'Saved SQL (ASQL): Generally, system-generated dynamic SQL should be kept in the code rather than here. This table is meant to provide a place for user-created reports, personal filters, etc.';
--COMMENT ON COLUMN app_sql.sql_id IS 'SQL ID: Surrogate key for this table.';
--COMMENT ON COLUMN app_sql.app_id IS 'Application ID: Foreign key to APP. The application which "owns" the stored SQL statement.';
--COMMENT ON COLUMN app_sql.sql_nm IS 'SQL Name: A unique identifier for a given user in a system, to help users locate saved filters/queries.';
----COMMENT ON COLUMN app_sql.group_id IS 'Group ID: Unique ID of the user''s group, role, project or team. May FK to the APP_GROUP table if included in the Core schema.';
--COMMENT ON COLUMN app_sql.user_id IS 'User ID: Unique ID of the application user. May FK to the APP_USER table if included in the Core schema.';
--COMMENT ON COLUMN app_sql.sql_type IS 'SQL Type: Optional field if an application needs a further method of distinguishing otherwise similar SQL statements. For example, one could store QUERY vs. FILTER to help the calling logic figure out whether to gather just the where clause, or the select and from clauses as well. Add a check constraint for this column if you agree on a set of allowable values.';
--COMMENT ON COLUMN app_sql.dml_stmt IS 'DML Start: Contains the initial portion of the SELECT, INSERT, UPDATE or DELETE statement. If the query is sufficiently complex, such that the columns in this table do not suffice, one could store the entire statement in this column.';
--COMMENT ON COLUMN app_sql.from_txt IS 'FROM: Contains the from clause';
--COMMENT ON COLUMN app_sql.where_txt iS 'WHERE: Contains the where clause (filter)';
--COMMENT ON COLUMN app_sql.group_by_txt IS 'GROUP BY: Contains the grouping clause, if any.';
--COMMENT ON COLUMN app_sql.having_txt IS 'HAVING: Contains the having clause, if any.';
--COMMENT ON COLUMN app_sql.order_by_txt IS 'ORDER BY: Contains the order by clause (sort), if any.';
--
--ALTER TABLE app_sql
--  ADD CONSTRAINT app_sql_pk
--  PRIMARY KEY (sql_id)
--  USING INDEX
--  TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_sql
--   ADD CONSTRAINT app_sql_uk
--   UNIQUE (sql_nm, user_id, app_id)
--   USING INDEX
--   TABLESPACE &&index_tablespace
--/
--ALTER TABLE app_sql
--  ADD CONSTRAINT asql_app_id_fk
--  FOREIGN KEY (app_id)
--  REFERENCES app (app_id)
--/
----ALTER TABLE app_sql
----  ADD CONSTRAINT asql_group_id_fk
----  FOREIGN KEY (group_id)
----  REFERENCES app_group (group_id)
----/
--ALTER TABLE app_sql
--  ADD CONSTRAINT asql_user_id_fk
--  FOREIGN KEY (user_id)
--  REFERENCES app_user (user_id)
--/

-------------------------------------------------------------------------------
/*
There are at least five different methods to recording historical changes
This table represents only one of them and by no means fits the requirements of
every system out there. Feel free to extend, scrap or redesign as you see fit.
Each shop should write a job to periodically archive off, or truncate off,
the back end of this table. How many months are kept online would be up to each
shop. The table could also be partitioned, by adding mod_dtm to the front of the
PK, and partitioning by range on mod_dtm. Partitioning would make the archival/
truncation process much easier and quicker.
*/

PROMPT Creating table APP_CHG_LOG...
CREATE SEQUENCE app_chg_log_seq
/

CREATE TABLE app_chg_log
(
 chg_log_id                     INTEGER DEFAULT ON NULL app_chg_log_seq.NEXTVAL CONSTRAINT aclg_chg_log_id_nn NOT NULL
,app_id                         INTEGER CONSTRAINT aclg_app_id_nn NOT NULL
,chg_log_dt                     DATE CONSTRAINT aclg_chg_log_dt_nn NOT NULL
,chg_type_cd                    VARCHAR2(1) CONSTRAINT aclg_chg_type_cd_nn NOT NULL
,table_nm                       VARCHAR2(30 CHAR)
,pk_id                          INTEGER
,row_id                         ROWID
,client_id                      VARCHAR2(80 CHAR)
,client_ip                      VARCHAR2(40 CHAR)
,client_host                    VARCHAR2(40 CHAR)
,client_os_user                 VARCHAR2(100 CHAR)
,chg_context                    VARCHAR2(4000)
)
TABLESPACE &&default_tablespace
PCTFREE 1 PCTUSED 99
-- If you have partitioning installed and wish to take advantage of smoother
-- and easy maintainenance (for example a job that drops the oldest year of
-- changes, and adds a new partition for the new year), comment the partitioning
-- back in.
--PARTITION BY RANGE (chg_log_dt)
--(
--   PARTITION P2014  VALUES LESS THAN (TO_DATE('2015Jan01', 'YYYYMonDD')),
--   PARTITION P2015  VALUES LESS THAN (TO_DATE('2016Jan01', 'YYYYMonDD')),
--   PARTITION P2016  VALUES LESS THAN (TO_DATE('2017Jan01', 'YYYYMonDD')),
--   PARTITION P2017  VALUES LESS THAN (TO_DATE('2018Jan01', 'YYYYMonDD')),
--   PARTITION P2018  VALUES LESS THAN (TO_DATE('2019Jan01', 'YYYYMonDD')),
--   PARTITION FUTURE VALUES LESS THAN (MAXVALUE)
--)
/

COMMENT ON TABLE app_chg_log IS 'Change Log (ACLG): Tracks change transactions. The changes to individual columns are tracked in the associated detail table. This table is filled by triggers tracking changes to each table, but could be written to directly by upper layer code if needed.';
COMMENT ON COLUMN app_chg_log.chg_log_id IS 'Change Log ID: Surrogate key for this table.';
COMMENT ON COLUMN app_chg_log.app_id IS 'Application ID: Foreign key to APP. The application in which the recorded changes occurred.';
COMMENT ON COLUMN app_chg_log.chg_log_dt IS 'Change Log Date: The date and time recording when the change was detected, as per the database host on which the application runs.';
COMMENT ON COLUMN app_chg_log.chg_type_cd IS 'Change Type Code: The type of change detected and tracked. Valid values are I for Insert, U for Update or D for Delete.';
COMMENT ON COLUMN app_chg_log.table_nm IS 'Table Name: Name of the table containing the record and column being tracked.';
COMMENT ON COLUMN app_chg_log.pk_id IS 'Row Primary Key ID: The numeric, surrogate PK ID to the row being altered. This should be used for most audited tables. It can be useful for IOT tables where a physical ROWID is not available.';
COMMENT ON COLUMN app_chg_log.row_id IS 'Row ID: Row ID of the row where the change was detected. This can be used for most records in the database, but is intended for rows whose PK or UK identifier is multi-column (does not have a single value to store in SRC_PK_ID).';
COMMENT ON COLUMN app_chg_log.client_id IS 'Client Identifier: Optional unique identifier for the end user or automated process responsible for the generation of the log message. This can be set by the frontend using ENV.INIT_CLIENT_CTX, but will default to something useful if it has not been set.';
COMMENT ON COLUMN app_chg_log.client_ip IS 'Client IP: Optional IPv4 or IPv6 address of the client machine.';
COMMENT ON COLUMN app_chg_log.client_host IS 'Client Host: Optional name of the machine the client is connecting from. For direct connections (application servers, end users with SQL*Plus, OEM, Forms, DBA tools, etc.), this is available from the USERENV context using the ''host'' parameter. For 3 and n-tier applications, if you desire to store the name of the machine the end user is operating from, the application server would have to obtain it from the user''s environment and set it using env.init_client_ctx() upon connection.';
COMMENT ON COLUMN app_chg_log.client_os_user IS 'Client OS User: The name of the logged in account on the operating system from which the client or user is connecting. This can be set by the application using env.init_client_ctx() upon connection.';
COMMENT ON COLUMN app_chg_log.chg_context IS 'Change Context: Can be used for additional identifiers surrounding the person, web service or transaction that triggered the audit, like IP Address, Program Name, Terminal, etc.';

ALTER TABLE app_chg_log
  ADD CONSTRAINT app_chg_log_pk
  PRIMARY KEY (chg_log_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/

ALTER TABLE app_chg_log
  ADD CONSTRAINT aclg_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/
CREATE INDEX aclg_app_id_idx ON app_chg_log (app_id)
  TABLESPACE &&index_tablespace
/

ALTER TABLE app_chg_log
  ADD CONSTRAINT aclg_chg_type_cd_chk
  CHECK (chg_type_cd IN ('I','U','D'))
/

-- Optional indexes. If you never query the logs except in rare instances, leave the indexes off
CREATE INDEX aclg_mod_dtm_idx ON app_chg_log (chg_log_dt, table_nm)
  TABLESPACE &&index_tablespace
/
CREATE INDEX aclg_pk_id_idx ON app_chg_log (pk_id)
  TABLESPACE &&index_tablespace
/
--CREATE INDEX aclg_row_id_idx ON app_chg_log (row_id)
--  TABLESPACE &&index_tablespace
--/

PROMPT Done

-------------------------------------------------------------------------------
PROMPT Creating table APP_CHG_LOG_DTL...
CREATE TABLE app_chg_log_dtl
(
 chg_log_id                     INTEGER CONSTRAINT aclgd_chg_log_id_nn NOT NULL
,column_nm                      VARCHAR2(30 CHAR)
,old_val                        VARCHAR2(4000 CHAR)
,new_val                        VARCHAR2(4000 CHAR)
,CONSTRAINT aclgd_chg_log_id_fk
 FOREIGN KEY (chg_log_id) REFERENCES app_chg_log (chg_log_id)
)
TABLESPACE &&default_tablespace
PCTFREE 1 PCTUSED 99
-- The following option is available on 11g and up. If you are on 8i to 10g and
-- wish to partition this table like its parent, app_chg_log, you will need to
-- add chg_log_dt to this table and partition by that, copying the partition
-- spec from the parent table above.
-- PARTITION BY REFERENCE (aclgd_chg_log_id_fk)
/

COMMENT ON TABLE app_chg_log_dtl IS 'Change Log (ACLGD): Attributive entity. Tracks changes to individual columns for a given record in an application over time. The CHG_LOG_ID column links it back to the parent change transaction record which has all the metadata surrounding the captured change.';
COMMENT ON COLUMN app_chg_log_dtl.chg_log_id IS 'Change Log ID: Identifying foreign key to APP_CHG_LOG. Combined with the column_nm, forms the unique key for each change detail item.';
COMMENT ON COLUMN app_chg_log_dtl.column_nm IS 'Column Name: Name of the column where the change was detected.';
COMMENT ON COLUMN app_chg_log_dtl.old_val IS 'Old Value: The old value of the column. NULL is expected for Insert changes. Convert dates, numbers and monetary amounts with a full format before writing them here.';
COMMENT ON COLUMN app_chg_log_dtl.new_val IS 'New Value: The new value of the column. NULL is expected for Delete changes. Convert dates, numbers and monetary amounts with a full format before writing them here.';

ALTER TABLE app_chg_log_dtl
  ADD CONSTRAINT app_chg_log_dtl_uk
  UNIQUE (chg_log_id, column_nm)
  USING INDEX
  TABLESPACE &&index_tablespace
/



-------------------------------------------------------------------------------
-- SECURITY-RELATED TABLES
--
-- The tables USER, ROLE, PERMISSION and the mappings between them follow a
-- trimmed down version of the standard RBAC security model. Since breaking down
-- the permissions into their respective objects, actions and associations was
-- unecessarily complex, I chose to combine it all in the permission table, where
-- a given application can store anything from simple one-word permissions, to
-- more complex, "intelligent" permissions that could include resource/object/
-- action details like page name, section name, control name, and action name.
--
-- Permissions are assigned to roles. Roles can have 0-N permissions.
-- Roles are assigned to users. A user can have 0-N roles.
--
-- In this model, I still kept the slightly more complex concept that roles can
-- be included in a hierarchy, so that permissions can be inherited by higher
-- roles, rather than having to duplicate permissions for every role. If your
-- shop doesn't need this complexity, remove the parent column in SEC_ROLE.
-------------------------------------------------------------------------------
/*
Add the user_pwd (password) column back in if authentication will take
place inside the database instead of in a typical authentication server like
Active Directory, OID, Kerberos, etc.

Comment in the other columns if you need a little more metadata on each user, or
break the columns out into a new SEC_USER_CONTACT table, an attributive entity
that could support multiple contacts per user, plus things like addresses, pagers,
etc.

If you are using 10g, comment in the ENCRYPT clause for the password column, so
the password can be encrypted at the OS level. Note that this does not encrypt
the password for anyone who has access to the schema containing this table. To
prevent that, the password should be hashed using a homegrown hash, or the free
hashing routine in DBMS_OBFUSCATION_TOOLKIT, or the routine in DBMS_CRYPTO which
requires that you purchase the Advanced Security Option from Oracle to use.
*/
PROMPT Creating table SEC_USER...
CREATE SEQUENCE sec_user_seq
/

CREATE TABLE sec_user
(
 user_id                         INTEGER DEFAULT ON NULL sec_user_seq.NEXTVAL CONSTRAINT su_user_id_nn NOT NULL
,user_nm                         VARCHAR2(80 CHAR) CONSTRAINT su_user_nm_nn NOT NULL
--,user_pwd                        VARCHAR2(30 CHAR) --ENCRYPT NO SALT
--,last_nm                         VARCHAR2(128 CHAR)
--,first_nm                        VARCHAR2(100 CHAR)
--,middle_nm                       VARCHAR2(100 CHAR)
,pref_nm                         VARCHAR2(255 CHAR)
,pmy_email_addr                  VARCHAR2(80 CHAR)
--,alt_email_addr                  VARCHAR2(80 CHAR)
--,sms_addr                        VARCHAR2(80 CHAR)
,work_phone                      VARCHAR2(40 CHAR)
--,mobile_phone                    VARCHAR2(40 CHAR)
--,home_phone                      VARCHAR2(40 CHAR)
--,ldap_dn                         VARCHAR2(255 CHAR)
-- OR
--,ldap_uid                        VARCHAR2(255 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE sec_user IS 'User (SU): Basic table of users, their identifiers and primary contact methods. Users can include human beings, named automated agents, and even IDs for hardware.';
COMMENT ON COLUMN sec_user.user_id IS 'User ID: Surrogate key for this table, filled by SEC_USER_SEQ.';
COMMENT ON COLUMN sec_user.user_nm IS 'User Name: The user name, often called the User ID, which the user enters in a login page to identify themselves.';
--COMMENT ON COLUMN sec_user.user_pwd IS 'User Password: The password for the user. Should not be stored in clear text. Should be stored in its hashed incarnation. See Core documentation.';
--COMMENT ON COLUMN sec_user.last_nm IS 'Last Name: Last name of the application user. Can be hyphenated and have multiple last names.';
--COMMENT ON COLUMN sec_user.first_nm IS 'First Name: First name of the application user.';
--COMMENT ON COLUMN sec_user.middle_nm IS 'Middle Name: Middle name or names of the application user.';
COMMENT ON COLUMN sec_user.pref_nm IS 'Preferred Name: The user''s preferred name.';
COMMENT ON COLUMN sec_user.pmy_email_addr IS 'Primary Email Address: The primary email address to use when contacting the user.';
--COMMENT ON COLUMN sec_user.alt_email_addr IS 'Alternate Email Address: Alternate email address.';
--COMMENT ON COLUMN sec_user.sms_addr IS 'SMS Text Messing Address: Address to use when sending short messages to a text message capable device.';
COMMENT ON COLUMN sec_user.work_phone IS 'Work Phone: The daytime or work telephone number to use when contacting the user.';
--COMMENT ON COLUMN sec_user.mobile_phone IS 'Mobile Phone: The mobile phone number to use when contacting the user.';
--COMMENT ON COLUMN sec_user.home_phone IS 'Home Phone: The home phone number to use when contacting the user.';
--COMMENT ON COLUMN sec_user.ldap_dn IS 'LDAP Distinguished Name: Unique identifier for a person in an LDAP DIT. This will allow us to link an application user with their metadata in the enterprise directory.';
--COMMENT ON COLUMN sec_user.ldap_uid IS 'LDAP Unique Identifier: Any unique identifier stored by an organization's directory server for an end user. The name and nature of the identifier must be known by the application using SEC_USER.';

ALTER TABLE sec_user
  ADD CONSTRAINT sec_user_pk
  PRIMARY KEY (user_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE sec_user
  ADD CONSTRAINT sec_user_uk
  UNIQUE (user_nm)
  USING INDEX
  TABLESPACE &&index_tablespace
/

--------------------------------------------------------------------------------
PROMPT Creating table SEC_USER_APP...
CREATE TABLE sec_user_app
(
 user_id                       INTEGER CONSTRAINT sua_user_id_nn NOT NULL
,app_id                        INTEGER CONSTRAINT sua_app_id_nn NOT NULL
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE sec_user_app IS 'User Application (SUA): Map of the applications to which a user has been granted access.';
COMMENT ON COLUMN sec_user_app.user_id IS 'User ID: Foreign key to SEC_USER.';
COMMENT ON COLUMN sec_user_app.app_id IS 'Application ID: Foreign key to APP.';

ALTER TABLE sec_user_app
  ADD CONSTRAINT sec_user_app_uk
  UNIQUE (user_id, app_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE sec_user_app
  ADD CONSTRAINT sua_user_id_fk
  FOREIGN KEY (user_id)
  REFERENCES sec_user (user_id)
/
ALTER TABLE sec_user_app
  ADD CONSTRAINT sua_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/


-------------------------------------------------------------------------------
PROMPT Creating table SEC_ROLE...
CREATE SEQUENCE sec_role_seq
/

CREATE TABLE sec_role
(
 role_id                       INTEGER DEFAULT ON NULL sec_role_seq.NEXTVAL CONSTRAINT sr_role_id_nn NOT NULL
,app_id                        INTEGER CONSTRAINT sr_app_id_nn NOT NULL
,role_nm                       VARCHAR2(100 CHAR) CONSTRAINT sr_role_nm_nn NOT NULL
,role_descr                    VARCHAR2(4000 CHAR)
,role_parent_id                INTEGER
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE sec_role IS 'Role (SR): Stores the list of valid roles for each application.';
COMMENT ON COLUMN sec_role.role_id IS 'Role ID: The surrogate key for this table, filled by SEC_ROLE_SEQ.';
COMMENT ON COLUMN sec_role.app_id IS 'Application ID: Foreign key to APP. The application to which the role applies.';
COMMENT ON COLUMN sec_role.role_nm   IS 'Role Name: The name for a given role, unique within an application.';
COMMENT ON COLUMN sec_role.role_descr IS 'Role Description: Optional notes about the intended purpose and use of the role.';
COMMENT ON COLUMN sec_role.role_parent_id IS 'Role Parent ID: Self-referencing foreign key to SEC_ROLE. Indicates whether the role is "owned", "under" or "supervised by" a higher role.';

ALTER TABLE sec_role
  ADD CONSTRAINT sec_role_pk
  PRIMARY KEY (role_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/

ALTER TABLE sec_role
  ADD CONSTRAINT sec_role_uk
  UNIQUE (role_nm, app_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE sec_role
  ADD CONSTRAINT sr_role_parent_id_fk
  FOREIGN KEY (role_parent_id)
  REFERENCES sec_role (role_id)
/
ALTER TABLE sec_role
  ADD CONSTRAINT sr_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app (app_id)
/

-------------------------------------------------------------------------------
PROMPT Creating table sec_user_ROLE...
CREATE TABLE sec_user_role
(
 user_id                       INTEGER CONSTRAINT sur_user_id_nn NOT NULL
,role_id                       INTEGER CONSTRAINT sur_role_id_nn NOT NULL
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE sec_user_role IS 'User Role (SUR): Map of roles granted to users. Users may be granted one or more roles.';
COMMENT ON COLUMN sec_user_role.user_id IS 'User ID: Foreign key to SEC_USER. The user being granted a role.';
COMMENT ON COLUMN sec_user_role.role_id IS 'Role ID: Foreign key to SEC_ROLE. The role being assigned to a user.';

ALTER TABLE sec_user_role
  ADD CONSTRAINT sec_user_role_uk
  UNIQUE (user_id, role_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/

ALTER TABLE sec_user_role
  ADD CONSTRAINT sur_user_id_fk
  FOREIGN KEY (user_id)
  REFERENCES sec_user (user_id)
/
ALTER TABLE sec_user_role
  ADD CONSTRAINT sur_role_id_fk
  FOREIGN KEY (role_id)
  REFERENCES sec_role (role_id)
/

--------------------------------------------------------------------------------
PROMPT Creating table SEC_PMSN...
CREATE SEQUENCE sec_pmsn_seq
/

CREATE TABLE sec_pmsn
(
 pmsn_id                       INTEGER DEFAULT ON NULL sec_pmsn_seq.NEXTVAL CONSTRAINT sp_pmsn_id_nn NOT NULL
,app_id                        INTEGER CONSTRAINT sp_app_id_nn NOT NULL
,pmsn_nm                       VARCHAR2(256 CHAR) CONSTRAINT sp_pmsn_nm_nn NOT NULL
,pmsn_descr                    VARCHAR2(200 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE sec_pmsn IS 'Permission (SP): List of permissions to actions or objects that can be assigned to roles.';
COMMENT ON COLUMN sec_pmsn.pmsn_id IS 'Permission ID: The surrogate key for this table, filled by SEC_PMSN_SEQ.';
COMMENT ON COLUMN sec_pmsn.app_id IS 'Application ID: Foreign key to APP. The application to which the permission applies.';
COMMENT ON COLUMN sec_pmsn.pmsn_nm   IS 'Permission Name: A permission is simply a string that controls authorization to do things within an application. The string can be the name of a page, object, component, control, action on said items, or a combination. The application protects access to code paths and application resources using this permission string. So it is not important what goes in the permission name, ony that the application layers agree on its value and format.';
COMMENT ON COLUMN sec_pmsn.pmsn_descr IS 'Permission Description: Optional notes about the intended purpose of the permission.';

ALTER TABLE sec_pmsn
   ADD CONSTRAINT sec_pmsn_pk
   PRIMARY KEY (pmsn_id)
   USING INDEX
   TABLESPACE &&index_tablespace
/
ALTER TABLE sec_pmsn
  ADD CONSTRAINT sec_pmsn_uk
  UNIQUE (pmsn_nm, app_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE sec_pmsn
  ADD CONSTRAINT sp_app_id_fk
  FOREIGN KEY (app_id)
  REFERENCES app(app_id)
/

--------------------------------------------------------------------------------
PROMPT Creating table SEC_ROLE_PMSN...
CREATE TABLE sec_role_pmsn
(
 role_id                       INTEGER CONSTRAINT srp_role_id_nn NOT NULL
,pmsn_id                       INTEGER CONSTRAINT srp_pmsn_id_nn NOT NULL
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE sec_role_pmsn IS 'Role Permission (SRP): Map of the permissions that apply to a given role. A role may be given more than one permission.';
COMMENT ON COLUMN sec_role_pmsn.role_id IS 'Role ID: Foreign key to SEC_ROLE. The role being granted a permission.';
COMMENT ON COLUMN sec_role_pmsn.pmsn_id IS 'Permission ID: Foreign key to SEC_PMSN. The permission being granted to a role.';

ALTER TABLE sec_role_pmsn
  ADD CONSTRAINT sec_role_pmsn_uk
  UNIQUE (role_id, pmsn_id)
  USING INDEX
  TABLESPACE &&index_tablespace
/
ALTER TABLE sec_role_pmsn
  ADD CONSTRAINT srp_role_id_fk
  FOREIGN KEY (role_id)
  REFERENCES sec_role (role_id)
/
ALTER TABLE sec_role_pmsn
  ADD CONSTRAINT srp_pmsn_id_fk
  FOREIGN KEY (pmsn_id)
  REFERENCES sec_pmsn (pmsn_id)
/


PROMPT Done.
