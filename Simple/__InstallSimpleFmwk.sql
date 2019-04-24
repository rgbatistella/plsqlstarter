/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

%usage
 SYSDBA> @__InstallSimpleFmwk.sql

%prereq
 The first call in this script creates an account to hold all of the instrumentation
 framework objects. Therefore, you should be logged in with an account that has
 CREATE USER and CREATE ANY CONTEXT, or just DBA privileges.  If you wish to use an
 existing account instead, just remove the DROP USER and CREATE USER section (found below).

%design
 This is the driving script to create the user and objects of the slimmed-down
 instrumentation framework.

 The script assumes you want tables in one tablespace, and indexes in another.
 If you wish to combine the table and index segments in a single tablespace, 
 please edit the table creation statements accordingly.

 This isn't a heavily over-engineered data model on purpose. Each Oracle shop
 has unique requirements. So alter the columns, code, storage, indexes, etc. as 
 you see fit. If you feel there is a basic improvement from which everyone could 
 benefit, email me with your suggestions and/or altered code, and I'll include it.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2007Nov01 Updated.
bcoulam      2010Mar18 Updated during 11g tests. Smoothed some rough edges.
bcoulam      2012Jan18 Slimmed Starter Framework down to just instrumentation components.

<i>
    __________________________  LGPL License  ____________________________
    Copyright (C) 1997-2012 Bill Coulam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
    
*******************************************************************************/

SPOOL C:\temp\__InstallSimpleFmwk.log
SET CONCAT +

-------------------------------------------------------------------------------
PROMPT Throughout this script and the framework documentation, the account that
PROMPT will own the framework packages, tables and other objects will be referred
PROMPT to as the "App schema" or "App account". This can be a new account 
PROMPT created by this script, or an existing account which you have prepared
PROMPT according to the required privs listed under CREATE USER section below.
PROMPT
SET VERIFY OFF
SET TERMOUT OFF
DEFINE app_db = ''
COLUMN name NEW_VALUE app_db
SELECT name
  FROM v$database;
SET TERMOUT ON

ACCEPT fmwk_home CHAR DEFAULT 'APP' PROMPT "Enter the name of the account that will own the framework objects (Default is APP): "
ACCEPT fmwk_pswd CHAR DEFAULT 'apppwd' PROMPT "Enter the &&fmwk_home account password (Default is apppwd): " HIDE
ACCEPT db_name CHAR DEFAULT '&&app_db' PROMPT "Confirm the database SID or service name where &&fmwk_home will be created (Default is &&app_db): "
ACCEPT default_tablespace CHAR DEFAULT 'USERS' PROMPT "Enter the framework account's default tablespace (Default is USERS): "
ACCEPT index_tablespace CHAR DEFAULT '&&default_tablespace' PROMPT "Enter the tablespace for the framework's indexes (Default is &&default_tablespace): "
ACCEPT temp_tablespace CHAR DEFAULT 'TEMP' PROMPT "Enter the framework account's default temp tablespace (Default is TEMP): "

-------------------------------------------------------------------------------
------------                        CLEANUP                          ----------
-------------------------------------------------------------------------------
DROP USER &&fmwk_home CASCADE;
DROP DIRECTORY &&fmwk_home+_dir
-------------------------------------------------------------------------------
------------                      CREATE USER                        ----------
-------------------------------------------------------------------------------
PAUSE Press RETURN to create the account, or Ctrl+C to quit...

PROMPT Creating &&fmwk_home account to hold the framework objects...

CREATE USER &&fmwk_home
  IDENTIFIED BY "&&fmwk_pswd"
  DEFAULT TABLESPACE &&default_tablespace
  TEMPORARY TABLESPACE &&temp_tablespace
  QUOTA UNLIMITED ON &&default_tablespace
  QUOTA UNLIMITED ON &&index_tablespace;

-------------------------------------------------------------------------------
------------                        GRANTS                           ----------
-------------------------------------------------------------------------------
PROMPT Granting appropriate privileges to &&fmwk_home...
-- Create privs
GRANT CREATE SYNONYM TO &&fmwk_home;
GRANT CREATE PROCEDURE TO &&fmwk_home;
GRANT CREATE SEQUENCE TO &&fmwk_home;
GRANT CREATE SESSION TO &&fmwk_home;
GRANT CREATE TABLE TO &&fmwk_home;
GRANT CREATE TRIGGER TO &&fmwk_home;
GRANT CREATE TYPE TO &&fmwk_home;
GRANT CREATE VIEW TO &&fmwk_home;
GRANT DEBUG CONNECT SESSION TO &&fmwk_home;
-- Alter privs
GRANT ALTER SESSION TO &&fmwk_home;
-- Other privs
GRANT SELECT ANY DICTIONARY TO &&fmwk_home;
GRANT CREATE JOB TO &&fmwk_home; -- 10g+
GRANT MANAGE SCHEDULER TO &&fmwk_home; --10g+

-- These two privs are used for Oracle Text (only required if installing the ProblemSolutionApp
-- in the same schema.
GRANT ctxapp TO &&fmwk_home;
GRANT EXECUTE ON CTXSYS.CTX_DDL TO &&fmwk_home;

PROMPT On newer versions of Oracle, some of the UTL packages are not granted to PUBLIC by default.
PROMPT We will grant to &&fmwk_home explicitly so the IO package will compile
GRANT EXECUTE ON UTL_FILE to &&fmwk_home;

-- These grants are only for the presentation to demonstrate things that are ordinarily
-- sub-second operations as if they took longer.
-- Remove this grant if you don't need it for your application/evaluation
GRANT EXECUTE ON dbms_lock TO &&fmwk_home;
GRANT EXECUTE ON dbms_pipe TO &&fmwk_home;
-- For demo only. Remove for distribution!!!
GRANT EXECUTE ON dbms_alert TO &&fmwk_home;
GRANT EXECUTE ON dbms_session TO &&fmwk_home;
GRANT EXECUTE ON dbms_system TO &&fmwk_home;

-------------------------------------------------------------------------------
------------                   CREATE DIRECTORY                    ------------
-------------------------------------------------------------------------------
PROMPT The script will now create one directory for use by the framework file-writing
PROMPT features.
PROMPT
PROMPT APP_DIR will be the directory on the host filesystem meant to be the root
PROMPT directory where one can find all files output by framework calls. 
PROMPT 
PROMPT You will need to set up an accommodating directory structure on your host OS 
PROMPT before proceeding with the directory creation.
PROMPT
ACCEPT dir_path CHAR DEFAULT 'C:\temp' PROMPT "Enter the full host path for DB output files (Default is C:\temp): "

SET TERMOUT OFF
DEFINE dir_sep_char = '\'
COLUMN sep_char NEW_VALUE dir_sep_char
SELECT CASE INSTR(VALUE, '\')
          WHEN 0 THEN
           '/'
          ELSE
           '\'
       END sep_char
  FROM v$parameter
 WHERE name = 'spfile';
SET TERMOUT ON
 
PAUSE Press RETURN to create the directory, or Ctrl+C to quit...

-------------------------------------------------------------------------------
------------                   CREATE DIRECTORY                    ------------
-------------------------------------------------------------------------------
PROMPT Creating directory...

CREATE OR REPLACE DIRECTORY &&fmwk_home+_dir AS '&&dir_path';

GRANT READ, WRITE ON DIRECTORY &&fmwk_home+_dir TO PUBLIC;


--PROMPT On 10g and up, we must use DBMS_JAVA to grant access to java network 
--PROMPT resources and access to directories. This does not work on XE which 
--PROMPT is missing the internal Java engine.
--SET SERVEROUTPUT ON
--DECLARE
--   l_java_avail v$option.value%TYPE;
--BEGIN
--   SELECT VALUE
--     INTO l_java_avail
--     FROM v$option
--    WHERE PARAMETER = 'Java';
--    
--   IF l_java_avail = 'TRUE' THEN
--      dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.util.PropertyPermission','*','read,write');
--      dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.net.SocketPermission','*','connect,resolve');
--      dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.io.FilePermission','&&dir_path+&&dir_sep_char+-','read,write');
--   ELSE
--      -- What does one do on XE 11g with no Java? A: Don't install the framework's MAIL package.
--      NULL;
--   END IF;
--   
--END;
--/


-------------------------------------------------------------------------------
------------               CREATE APPLICATION CONTEXT              ------------
-------------------------------------------------------------------------------
PROMPT Creating CONTEXT...
CREATE OR REPLACE CONTEXT &&fmwk_home+_ctx USING &&fmwk_home+.env
/

-- Script to show the context attributes set so far.
--SET SERVEROUTPUT ON
--DECLARE
--   l_list dbms_session.AppCtxTabTyp;
--   l_size NUMBER;
--BEGIN
--   dbms_session.list_context(list => l_list, lsize => l_size);
--   dbms_output.put_line('Number of contexts returned: '||l_list.COUNT);
--   dbms_output.put_line('Size returned: '||l_size);
--   IF (l_size > 0) THEN
--      FOR i IN l_list.first..l_list.last LOOP
--         dbms_output.put_line(l_list(i).namespace||'.'||l_list(i).attribute||'='||l_list(i).value); 
--      END LOOP;
--   END IF;
--END;
--/



PAUSE Press RETURN to create the tables in &&fmwk_home, or Ctrl+C to quit...

CONN &&fmwk_home/&&fmwk_pswd@&db_name

SET verify OFF

PROMPT Creating base tables...
-- Note that every table and every column has a comment in a standard format. 
-- The table or column is first spelled out entirely, so that abbreviations and
-- acronyms are expanded and explained. This is followed by an optional code or
-- short display name in parenthesis, then a colon, then the full explanation of 
-- the table or column. The short table code found in the parenthesis is used 
-- when creating new indexes, foreign keys, SQL table aliases, and other 
-- identifiers in PL/SQL. Consider creating automated jobs that check and enforce
-- naming standards using this short table code.

-------------------------------------------------------------------------------
PROMPT Creating table APP_PARM...
CREATE TABLE app_parm
(
 parm_id                       INTEGER              CONSTRAINT ap_parm_id_nn NOT NULL
,parm_nm                       VARCHAR2(500 CHAR)   CONSTRAINT ap_parm_nm_nn NOT NULL
,parm_display_nm               VARCHAR2(256 CHAR)
,parm_val                      VARCHAR2(4000 CHAR)
,parm_notes                    VARCHAR2(4000 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
CACHE
/

COMMENT ON TABLE app_parm IS 'Parameter (AP): Stores the parameters and configuration values used by the consuming schema.';
COMMENT ON COLUMN app_parm.parm_id IS 'Parameter ID: Surrogate key for this table. Values are created manually.';
COMMENT ON COLUMN app_parm.parm_nm IS 'Parameter Name: The unique name of the parameter.';
COMMENT ON COLUMN app_parm.parm_display_nm IS 'Parameter Display Name: Optional text used when the parameter is shown in the UI.';
COMMENT ON COLUMN app_parm.parm_val IS 'Parameter Value: The value of the parameter. Can be empty if desired.';
COMMENT ON COLUMN app_parm.parm_notes IS 'Parameter Notes: Optional notes about a parameter that have business value.';

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
PROMPT Creating table APP_LOG...
CREATE SEQUENCE app_log_seq
/

CREATE TABLE app_log
(
 log_id                         NUMBER              CONSTRAINT alg_log_id_nn NOT NULL
,log_ts                         TIMESTAMP           CONSTRAINT alg_log_ts_nn NOT NULL
,sev_cd                         VARCHAR2(30 CHAR)   CONSTRAINT alg_sev_cd_nn NOT NULL
,routine_nm                     VARCHAR2(80 CHAR)
,line_num                       INTEGER
,log_txt                        VARCHAR2(4000 CHAR)
,error_stack                    VARCHAR2(4000 CHAR)
,call_stack                     VARCHAR2(4000 CHAR)
,client_id                      VARCHAR2(80 CHAR)
,client_ip                      VARCHAR2(40 CHAR)
,client_host                    VARCHAR2(40 CHAR)
,client_os_user                 VARCHAR2(100 CHAR)
)
TABLESPACE &&default_tablespace
PCTFREE 10 PCTUSED 90
/

COMMENT ON TABLE  app_log IS 'Log (ALG): Application logging table. This table dovetails with the LOGS package. This table is one of the output targets for logging and debugging. All debugging goes to this table by default. But application and error logging only gets written here if the targets are turned on using logs.set_targets.';
COMMENT ON COLUMN app_log.log_id IS 'Log ID: Surrogate key for this table.';
COMMENT ON COLUMN app_log.log_ts IS 'Log Timestamp: Timestamp of log entry.';
COMMENT ON COLUMN app_log.sev_cd IS 'Severity: Currently limited to ERROR, WARN, INFO, DEBUG and TIME. AUDIT-class messages are supposed to be logged to APP_CHG_LOG[_DTL], not here. This column categorizes the log/message entries in varying degrees of severity.';
COMMENT ON COLUMN app_log.routine_nm IS 'Routine Name: The name of the trigger, type body, object method, standalone function or procedure, or packaged routine (in package.routine format) which generated the log message.';
COMMENT ON COLUMN app_log.line_num IS 'Line Number: The line number the caller or the framework determined should be referenced in the ROUTINE_NM for this log record.';
COMMENT ON COLUMN app_log.log_txt IS 'Log Text: Column of free-form text for logging, debugging and informational/context recording.';
COMMENT ON COLUMN app_log.error_stack IS 'Error Stack: Prior to 10g, this will be the SQLERRM, which isn''t very helpful, but better than the misinformation the call stack presented when handling an exception. After 10g and above, this will contain the value of DBMS_UTILITY.format_error_backtrace, which points us to the actual line that caused the error.';
COMMENT ON COLUMN app_log.call_stack IS 'Call Stack: Call tree automatically recorded when an error is logged by the framework.';
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
CREATE INDEX alg_routine_nm_idx ON app_log (routine_nm)
  TABLESPACE &&index_tablespace
/
ALTER TABLE app_log
  ADD CONSTRAINT alg_sev_cd_chk
  CHECK (sev_cd IN ('ERROR','WARN','INFO','DEBUG','TIME'))
/

/*
 I did not place yet another index on log_ts, as ordering by
 log_id DESC should serve the requirement to see this data in reverse 
 chronological order just fine. Also logging to this table needs to be fast to
 lessen overhead, and it less indexes aids DML performance.
*/

-------------------------------------------------------------------------------
PROMPT Creating table APP_CHG_LOG...
CREATE SEQUENCE app_chg_log_seq
/

CREATE TABLE app_chg_log
(
 chg_log_id                     NUMBER              CONSTRAINT aclg_chg_log_id_nn NOT NULL
,chg_log_dt                     DATE                CONSTRAINT aclg_chg_log_dt_nn NOT NULL
,chg_type_cd                    VARCHAR2(1)         CONSTRAINT aclg_chg_type_cd_nn NOT NULL
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
--   PARTITION P2011  VALUES LESS THAN (TO_DATE('2012Jan01', 'YYYYMonDD')),
--   PARTITION P2012  VALUES LESS THAN (TO_DATE('2013Jan01', 'YYYYMonDD')),
--   PARTITION P2013  VALUES LESS THAN (TO_DATE('2014Jan01', 'YYYYMonDD')),
--   PARTITION P2014  VALUES LESS THAN (TO_DATE('2015Jan01', 'YYYYMonDD')),
--   PARTITION P2015  VALUES LESS THAN (TO_DATE('2016Jan01', 'YYYYMonDD')),
--   PARTITION P2016  VALUES LESS THAN (TO_DATE('2017Jan01', 'YYYYMonDD')),
--   PARTITION P2017  VALUES LESS THAN (TO_DATE('2018Jan01', 'YYYYMonDD')),
--   PARTITION P2018  VALUES LESS THAN (TO_DATE('2019Jan01', 'YYYYMonDD')),
--   PARTITION P2019  VALUES LESS THAN (TO_DATE('2019Jan01', 'YYYYMonDD')),
--   PARTITION P2020  VALUES LESS THAN (TO_DATE('2019Jan01', 'YYYYMonDD')),
--   PARTITION FUTURE VALUES LESS THAN (MAXVALUE)
--)
/

COMMENT ON TABLE app_chg_log IS 'Change Log (ACLG): Tracks change transactions. The changes to individual columns are tracked in the associated detail table. This table is filled by triggers tracking changes to each table, but could be written to directly by upper layer code if needed.';
COMMENT ON COLUMN app_chg_log.chg_log_id IS 'Change Log ID: Surrogate key for this table.';
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


-------------------------------------------------------------------------------
PROMPT Creating table APP_CHG_LOG_DTL...
CREATE TABLE app_chg_log_dtl
(
 chg_log_id                     NUMBER CONSTRAINT aclgd_chg_log_id_nn NOT NULL
,column_nm                      VARCHAR2(30 CHAR)
,old_val                        VARCHAR2(4000 CHAR)
,new_val                        VARCHAR2(4000 CHAR)
,CONSTRAINT aclgd_chg_log_id_fk FOREIGN KEY (chg_log_id) REFERENCES app_chg_log (chg_log_id)
)
TABLESPACE &&default_tablespace
PCTFREE 1 PCTUSED 99
-- The following partition by reference option is available on 11g and up. If you are on
-- 8i to 10g and wish to partition this table like its parent, app_chg_log, you will need
-- to add chg_log_dt to this table and partition by that, copying the partition spec
-- from the parent table above.
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
------------                       SEED DATA                       ------------
-------------------------------------------------------------------------------
PROMPT Loading sample data...
PAUSE Press RETURN to create sample data in the framework tables, or Ctrl+C to quit...

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_VAL, PARM_NOTES)
VALUES (1, 'Default IO Directory', UPPER('&&fmwk_home+_dir'), 'Default should be adjusted for *nix systems. This parm is required for package IO to function.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_VAL, PARM_NOTES)
VALUES (2, 'Default IO File Name', '&&db_name+_&&fmwk_home+.log', 'This parameter is required for package IO to function.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_VAL, PARM_NOTES)
VALUES (3, 'Default Log File Directory', UPPER('&&fmwk_home+_dir'), 'This parameter is required by the LOGS package.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_VAL, PARM_NOTES)
VALUES (4, 'Default Log Targets', 'Screen=Y,Table=Y,File=Y', 'This parameter is required by the LOGS package.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_VAL, PARM_NOTES)
VALUES (5, 'Log Archive Directory', UPPER('&&fmwk_home+_dir'), 'This parm is required for LOGS.trim_table to function. It is typically an "archive" subfolder in the log file directory.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_VAL, PARM_NOTES)
VALUES (6, 'Debug', 'Off', 'To turn all debug messages on, use either "all", "on", "true", "yes" or "y". '||
'To turn all debug messages off, use either "none", "off", "false", "no" or "n". '||
'If finer control is needed over when debug logging takes place, use session=<session_id>, '||
'unit=<pkg1,proc2,trigger,etc.>, or user=<client_id>. See comments for logs.dbg() for a detailed explanation.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_VAL, PARM_NOTES)
VALUES (7, 'Debug Toggle Check Interval', '1', 'The amount of time, in minutes, before logs.dbg will check to see if someone has now turned on debugging by changing the Debug parameter value.');

COMMIT;

PROMPT Compiling PL/SQL objects...
PAUSE Press RETURN to compile the framework packages, views, and triggers, or Ctrl+C to quit...
@@_compile_objects.sql

PROMPT InstallSimpleFmwk is complete.
SPOOL OFF
SET VERIFY ON

