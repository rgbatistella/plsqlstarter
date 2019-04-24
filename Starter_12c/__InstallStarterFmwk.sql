/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

%usage
 SYSDBA> @__InstallStarterFmwk.sql

%prereq
 The first call in this script creates an account to hold all of the framework 
 objects. Therefore, you should be logged in with an account that has
 CREATE USER and CREATE ROLE, or DBA privileges.  If you wish to use an existing
 account instead, just remove the first callout (found below) to the 
 "_create_role_user.sql" script.

%design
 This is the driving script to create the role, user and objects of the "Core"
 application framework.

 The script assumes you want tables in one tablespace, and indexes in another.
 If you wish to combine the table and index segments in a single tablespace, or
 if you wish to place the LOB columns in a tablespace dedicated to LOB storage, 
 please edit the "_create_base_tables.sql" script accordingly.

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
bcoulam      2014Feb03 Updated for 12c.

<i>
    __________________________  LGPL License  ____________________________
    Copyright (C) 1997-2008 Bill Coulam

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
ACCEPT logpath CHAR DEFAULT 'C:\Temp' PROMPT "Enter the directory for the installation log file (Default is C:\Temp): "
SPOOL &&logpath\__InstallStarterFmwk.log
SET CONCAT +

-------------------------------------------------------------------------------
PROMPT Throughout this script and the framework documentation, the account that
PROMPT will own the framework packages, tables and other objects will be referred
PROMPT to as the "Core schema" or "Core account". This can be a new account 
PROMPT created by this script, or an existing account which you have prepared
PROMPT according to the required privs listed in create_role_user.sql
PROMPT
SET VERIFY OFF
SET TERMOUT OFF
DEFINE core_db = ''

COLUMN con_name NEW_VALUE core_db
SELECT SYS_CONTEXT('USERENV','con_name') AS con_name FROM dual;
SET TERMOUT ON

ACCEPT fmwk_home CHAR DEFAULT 'Core' PROMPT "Enter the name of the account that will own the framework objects (Default is CORE): "
ACCEPT fmwk_pswd CHAR DEFAULT 'core' PROMPT "Enter the framework account password (Default is core): " HIDE
ACCEPT default_tablespace CHAR DEFAULT 'USERS' PROMPT "Enter the framework account's default tablespace (Default is USERS): "
ACCEPT index_tablespace CHAR DEFAULT '&&default_tablespace' PROMPT "Enter the tablespace for the framework's indexes (Default is &&default_tablespace): "
ACCEPT temp_tablespace CHAR DEFAULT 'TEMP' PROMPT "Enter the framework account's default temp tablespace (Default is TEMP): "
ACCEPT mydomain CHAR PROMPT "Enter your company's internet domain, e.g. cnn.com (No Default): "
ACCEPT smtp_server_address CHAR DEFAULT 'smtp.&&mydomain' PROMPT "SMTP server address (Default is smtp.&&mydomain). If none, enter None: "
ACCEPT ldap_server_address CHAR DEFAULT 'ldap.&&mydomain' PROMPT "LDAP directory server address (Default is ldap.&&mydomain+:389). If none, enter None: "
PAUSE Press RETURN to create the account, or Ctrl+C to quit...

@@_create_fmwk_schema.sql
@@_create_roles.sql

PROMPT The script will now create two directories for use by the Core framework.
PROMPT The first, named CORE_DIR, will be the directory on the host filesystem
PROMPT meant to be the root directory where one can find all files output by PL/SQL 
PROMPT calls from within the database.
PROMPT The second, named CORE_LOGS, will generally be a "logs" subfolder under
PROMPT the parent directory. As such, you will need to set up an accommodating
PROMPT directory structure on your host OS before proceeding with the directory creation.
PROMPT You could add further directories here, depending on your application requirements.
PROMPT For example, you could create a CORE_EXTAB for a directory where files are read for external tables,
PROMPT or a CORE_MAIL, for file-based records of emails sent from within Oracle, or a CORE_BFILE
PROMPT for a place where incoming binary files are dropped for later inclusion or reading.
PROMPT
ACCEPT core_dir_path CHAR DEFAULT '&&logpath' PROMPT "Enter the full path for DB output files (Default is &&logpath): "
ACCEPT core_log_path CHAR DEFAULT '&core_dir_path+\logs' PROMPT "Enter the path for DB-written log files (Default is &core_dir_path+\logs): "
ACCEPT core_mail_path CHAR DEFAULT '&core_dir_path+\mail' PROMPT "Enter the path for DB-written email files (Default is &core_dir_path+\mail): "

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
 
PAUSE Press RETURN to create the directories, or Ctrl+C to quit...

CREATE OR REPLACE DIRECTORY CORE_DIR AS '&&core_dir_path';
CREATE OR REPLACE DIRECTORY CORE_LOGS AS '&&core_log_path';
CREATE OR REPLACE DIRECTORY CORE_MAIL AS '&&core_mail_path';

GRANT READ, WRITE ON DIRECTORY CORE_DIR TO PUBLIC;
GRANT READ, WRITE ON DIRECTORY CORE_LOGS TO PUBLIC;
GRANT READ, WRITE ON DIRECTORY CORE_MAIL TO PUBLIC;

PROMPT In order to mock up a complete pilot environment, with multiple 
PROMPT applications and schemas sharing the framework on the same database, three new
PROMPT test accounts will now be created, matching the accounts found in the
PROMPT sample data for &&fmwk_home.APP_ENV.OWNER_ACCOUNT
PAUSE Press RETURN to create the test accounts, or Ctrl+C to quit...
DEFINE test_user = tkt_dev
@@_create_test_user.sql
GRANT READ, WRITE ON DIRECTORY CORE_DIR TO &&test_user;
GRANT READ, WRITE ON DIRECTORY CORE_LOGS TO &&test_user;
GRANT READ, WRITE ON DIRECTORY CORE_MAIL TO &&test_user;

DEFINE test_user = tkt_test
@@_create_test_user.sql
GRANT READ, WRITE ON DIRECTORY CORE_DIR TO &&test_user;
GRANT READ, WRITE ON DIRECTORY CORE_LOGS TO &&test_user;
GRANT READ, WRITE ON DIRECTORY CORE_MAIL TO &&test_user;

DEFINE test_user = blg
@@_create_test_user.sql
GRANT READ, WRITE ON DIRECTORY CORE_DIR TO &&test_user;
GRANT READ, WRITE ON DIRECTORY CORE_LOGS TO &&test_user;
GRANT READ, WRITE ON DIRECTORY CORE_MAIL TO &&test_user;

PROMPT On 10g and up, we must use DBMS_JAVA to grant access to java network 
PROMPT resources and access to directories.
SET SERVEROUTPUT ON
BEGIN
   dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.util.PropertyPermission','*','read,write');
   dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.net.SocketPermission','*','connect,resolve');
   dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.io.FilePermission','&&core_dir_path+&&dir_sep_char+-','read,write');
   dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.io.FilePermission','&&core_log_path+&&dir_sep_char+-','read,write');
   dbms_java.grant_permission(UPPER('&&fmwk_home'),'java.io.FilePermission','&&core_mail_path+&&dir_sep_char+-','read,write');
END;
/

PROMPT On newer versions of Oracle, some of the UTL packages are not granted to PUBLIC by default.
PROMPT We will grant to &&fmwk_home explicitly so IO and MAIL packages will compile
GRANT EXECUTE ON UTL_FILE to &&fmwk_home;
GRANT EXECUTE ON UTL_TCP to &&fmwk_home;

/* Bug in creation of Oracle Text index on 12c. Commenting out until bug is found and fixed. */
--PROMPT The script will now ensure the &&fmwk_home can use Oracle Text by granting
--PROMPT permissions on CTXSYS objects.
--PAUSE Press RETURN to grant privs on CTXSYS objects, or Ctrl+C to quit...
---- Grant required privs to execute packages in CTXSYS
--SET SERVEROUTPUT ON
--DECLARE
--   l_ctxsys_exists INTEGER := 0;
--BEGIN
--   SELECT COUNT(*)
--     INTO l_ctxsys_exists
--     FROM dba_users
--    WHERE username = 'CTXSYS';
--   
--   IF l_ctxsys_exists = 0 THEN
--      dbms_output.put_line('WARNING: The CTXSYS account required by Oracle Text seems to be missing.'||
--         'Either install Oracle Text, or remove the preferences and indexes in this script that require CTXSYS.');
--   ELSE
--      dbms_output.put_line('CTXSYS found. Granting CTXAPP role and privs on CTXSYS objects to &&fmwk_home...');
--      
--      EXECUTE IMMEDIATE 'GRANT ctxapp TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_CLS TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_DDL TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_DOC TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_OUTPUT TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_QUERY TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_REPORT TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_THES TO &&fmwk_home';
--      EXECUTE IMMEDIATE 'GRANT EXECUTE ON CTXSYS.CTX_ULEXER TO &&fmwk_home';
--   END IF;
--END;
--/

PAUSE Press RETURN to create the tables in &&fmwk_home, or Ctrl+C to quit...


CONN &&fmwk_home/&&fmwk_pswd@&core_db

SET verify OFF

PROMPT Creating base tables...
@@_create_base_tables.sql

--PROMPT Creating Oracle Text indexes...
/* Currently the Oracle Text index on the email table will not create. Seems
to be a bug in 12c. No exact matches on My Oracle Support. So leaving out of
install for now.

This is the error message I'm getting:

CREATE INDEX aem_multi_cidx ON app_email(otx_sync_col)
*
ERROR at line 1:
ORA-29855: error occurred in the execution of ODCIINDEXCREATE routine
ORA-20000: Oracle Text error:
DRG-50857: oracle error in dretbase
ORA-20000: Oracle Text error:
DRG-10502: index 1085 does not exist
ORA-06512: at "CTXSYS.DRUE", line 160
ORA-06512: at "CTXSYS.DRVXMD", line 196
ORA-06512: at line 1
ORA-06512: at "CTXSYS.DRUE", line 160
ORA-06512: at "CTXSYS.TEXTINDEXMETHODS", line 366
*/
--@@_otx_prefs_and_index.sql

PROMPT Loading sample data...
PAUSE Press RETURN to create sample data in the framework tables, or Ctrl+C to quit...
@@_populate_sample_data.sql

PROMPT Compiling PL/SQL objects...
PAUSE Press RETURN to compile the framework packages, views, and triggers, or Ctrl+C to quit...
@@_compile_objects.sql

PROMPT Resetting sequences in case data loading used hard-coded PK values...
PAUSE Press RETURN to reset the sequences, or Ctrl+C to quit...
SET SERVEROUTPUT ON
SET CONCAT +
DECLARE
   l_exclude_arr ddl_utils.type_obj_nm_arr;
BEGIN
   l_exclude_arr('DDL_UTILS') := 'Y';
   l_exclude_arr('API_APP_LOG') := 'Y';
   
   ddl_utils.refresh_grants(i_grantee => UPPER('&&fmwk_home+_FULL'));
   
   -- since we populated the rows in the Core ref tables by hand, this will
   -- bump up the sequences so they don't clash with values we've already 
   -- used.
   ddl_utils.reset_seq('app_seq');
   ddl_utils.reset_seq('app_db_seq');
   ddl_utils.reset_seq('app_env_seq');
   ddl_utils.reset_seq('app_msg_seq');
   ddl_utils.reset_seq('app_parm_seq');
   ddl_utils.reset_seq('sec_role_seq');
   ddl_utils.reset_seq('sec_user_seq');
   ddl_utils.reset_seq('sec_pmsn_seq');
END;
/

PROMPT Now the objects exist in the &fmwk_home account, we can create private
PROMPT synonyms in the test application accounts.
PAUSE Press RETURN to create the synonyms in the test accounts, or Ctrl+C to quit...

-- Calling this script creates synonyms in other accounts. Therefore this script
-- requires the Framework account to have CREATE ANY SYNONYM priv
DEFINE fmwk_consumer = TKT_DEV
@@_create_synonyms_for_fmwk_objects.sql
GRANT REFERENCES ON sec_user TO &&fmwk_consumer;

DEFINE fmwk_consumer = TKT_TEST
@@_create_synonyms_for_fmwk_objects.sql
GRANT REFERENCES ON sec_user TO &&fmwk_consumer;

DEFINE fmwk_consumer = BLG
@@_create_synonyms_for_fmwk_objects.sql
GRANT REFERENCES ON sec_user TO &&fmwk_consumer;

-- Since PL/SQL can't use the privs granted to the CORE_FULL role, we
-- must also grant privs directly to the framework-using schemas.
SET SERVEROUTPUT ON SIZE 1000000 
BEGIN
   ddl_utils.refresh_grants(i_grantee =>'TKT_DEV');
   ddl_utils.refresh_grants(i_grantee =>'TKT_TEST');
   ddl_utils.refresh_grants(i_grantee =>'BLG');
END;
/

PROMPT InstallStarterFmwk is complete.
PROMPT If there were any errors, review them in &&logpath\__InstallStarterFmwk.log
SPOOL OFF
SET VERIFY ON
