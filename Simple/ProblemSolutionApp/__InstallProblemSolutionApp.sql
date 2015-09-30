/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

%usage
 SYSDBA> @__InstallProblemSolutionApp.sql

%prereq
 The first call in this script creates an account to hold the Problem-Solution
 application database objects. Therefore, you should be logged in with an account that has
 DBA privileges.  If you wish to use an existing account instead, just remove the 
 DROP USER and CREATE USER section (found below).

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2007Nov01 Created.
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

/*
In order for the Embedded PL/SQL Gateway to handle HTTP requests, the listener
must be listening for HTTP. To configure this, I found the easiest route is
adding the following descriptor to my local listener.ora file under the 
LISTENER DESCRIPTION_LIST:

   (DESCRIPTION=
     (ADDRESS=(PROTOCOL=tcp)(HOST=localhost)(PORT=8080))(Presentation=HTTP)(Session=RAW)
   )

Note: If you are on version 11, you can run the following script to get a quick
      overview of your current EPG setup:
      @$ORACLE_HOME/rdbms/admin/epgstat.sql
      
      On 10g, I found it helpful to get the database to show me the xdbconfig.xml file,
      which is kept within the database itself, inside the XML repository. This can be
      viewed by using SQL*Plus:
      SQL> SET LONG 1000000
      SQL> SET PAGES 500
      SQL> SET LINES 120
      SQL> SELECT dbms_xdb.cfg_get().getClobVal() FROM dual;

-- This is the recommended method of changing the EPG's settings, through the DBMS_EPG 
-- API:
SET SERVEROUTPUT ON
BEGIN
   DBMS_XDB.setHTTPPort(8080);
END;
/

-- If you are having trouble, this is another method of changing the port the database
-- XML DB Protocol Server listens on.
DECLARE
   l_xml XMLTYPE;
BEGIN
   SELECT UPDATEXML(dbms_xdb.cfg_get()
                   ,'/xdbconfig/descendant::http-port/text()'
                   ,'8090')
     INTO l_xml
     FROM dual;
   dbms_xdb.cfg_update(l_xml);
END;
/

-- This is the method of changing the protocol server's logging level (there are many)
execute dbms_epg.set_global_attribute('log-level', 3);
execute dbms_output.put_line(dbms_epg.get_global_attribute('log-level'));

-- A little block to display current DAD mappings, probably borrowed from Tim Hall
SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
  l_paths  DBMS_EPG.varchar2_table;
BEGIN
  DBMS_EPG.get_all_dad_mappings (
    dad_name => 'ProbSol',
    paths    => l_paths);

  DBMS_OUTPUT.put_line('Mappings');
  DBMS_OUTPUT.put_line('========');
  FOR i IN 1 .. l_paths.count LOOP
    DBMS_OUTPUT.put_line(l_paths(i));
  END LOOP;
END;
/

-- And a little block to display the DAD attributes
SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
  l_attr_names   DBMS_EPG.varchar2_table;
  l_attr_values  DBMS_EPG.varchar2_table;
BEGIN
  DBMS_OUTPUT.put_line('Attributes');
  DBMS_OUTPUT.put_line('==========');

  DBMS_EPG.get_all_dad_attributes (
    dad_name    => 'ProbSol',
    attr_names  => l_attr_names,                       
    attr_values => l_attr_values);

  FOR i IN 1 .. l_attr_names.count LOOP
    DBMS_OUTPUT.put_line(l_attr_names(i) || '=' || l_attr_values(i));
  END LOOP;
END;
/

*/

SPOOL C:\temp\_InstallProblemSolutionApp.log

SET CONCAT +

SET VERIFY OFF
SET TERMOUT OFF
DEFINE core_db = ''
COLUMN name NEW_VALUE core_db
SELECT name
  FROM v$database;
SET TERMOUT ON

-- The following must run as SYS or a user with SYSDBA privs
ACCEPT fmwk_home CHAR DEFAULT 'APP' PROMPT "Enter the name of the account where the Simple framework resides (Default is APP): "
ACCEPT ps_app_owner CHAR DEFAULT 'SOL' PROMPT "Enter the account that will own the Solutions application (Default is SOL): "
ACCEPT ps_app_owner_pswd CHAR DEFAULT 'sol' PROMPT "Enter the Solutions account password (Default is SOL): " HIDE
ACCEPT db_name CHAR DEFAULT '&&core_db' PROMPT "Enter the database SID or service name where these operations are to execute (Default is &&core_db): "
ACCEPT default_tablespace CHAR DEFAULT 'USERS' PROMPT "Enter the Solutions account's default tablespace (Default is USERS): "
ACCEPT temp_tablespace CHAR DEFAULT 'TEMP' PROMPT "Enter the Solutions account's default temp tablespace (Default is TEMP): "
ACCEPT dad_name CHAR DEFAULT 'ProbSol' PROMPT "Enter the Database Access Descriptor for the Solutions app (Default is ProbSol): "

PROMPT Creating user &&ps_app_owner...

------------                       CREATE USER                        ----------
CREATE USER &&ps_app_owner
  IDENTIFIED BY "&&ps_app_owner_pswd"
  DEFAULT TABLESPACE &&default_tablespace
  TEMPORARY TABLESPACE &&temp_tablespace
  QUOTA UNLIMITED ON &&default_tablespace;
  
GRANT SELECT_CATALOG_ROLE TO &&ps_app_owner;
GRANT EXECUTE_CATALOG_ROLE TO &&ps_app_owner;
GRANT SELECT ANY DICTIONARY TO &&ps_app_owner;
GRANT CREATE SYNONYM TO &&ps_app_owner;
GRANT CREATE PROCEDURE TO &&ps_app_owner;
GRANT CREATE SEQUENCE TO &&ps_app_owner;
GRANT CREATE SESSION TO &&ps_app_owner;
GRANT CREATE SYNONYM TO &&ps_app_owner;
GRANT CREATE TABLE TO &&ps_app_owner;
GRANT CREATE TRIGGER TO &&ps_app_owner;
GRANT CREATE TYPE TO &&ps_app_owner;
GRANT CREATE VIEW TO &&ps_app_owner;
-- Alter privs
GRANT ALTER SESSION TO &&ps_app_owner;
-- Other privs
GRANT DEBUG CONNECT SESSION TO &&ps_app_owner;
-- Give ability to authorize the DAD; seems to not be needed despite what the docs say.
--GRANT EXECUTE ON dbms_epg TO &&ps_app_owner;
GRANT ctxapp TO &&ps_app_owner;
GRANT EXECUTE ON CTXSYS.CTX_DDL TO &&ps_app_owner;
-- 10g, required for text index to be transactional
GRANT CREATE JOB TO &&ps_app_owner;

--PROMPT On 10g and up, we must use DBMS_JAVA to grant access to java network 
--PROMPT resources and access to directories. This does not work on XE which 
--PROMPT is missing the internal Java engine.
--SET SERVEROUTPUT ON
--BEGIN
--   dbms_java.grant_permission(UPPER('&&ps_app_owner'),'java.util.PropertyPermission','*','read,write');
--   dbms_java.grant_permission(UPPER('&&ps_app_owner'),'java.net.SocketPermission','*','connect,resolve');
--   dbms_java.grant_permission(UPPER('&&ps_app_owner'),'java.io.FilePermission','&&dir_path+&&dir_sep_char+-','read,write');
--END;
--/

-- Next we create a DAD, and map it to a path used in browser URLs.
BEGIN
   dbms_epg.create_dad(dad_name => '&&dad_name', PATH => '/solutions/*');
END;
/

-- Add a few more virtual paths just in case the users forget the main one
BEGIN
   dbms_epg.map_dad(dad_name => '&&dad_name', PATH => '/sol/*');
END;
/
BEGIN
   dbms_epg.map_dad(dad_name => '&&dad_name', PATH => '/probsol/*');
END;
/
BEGIN
   dbms_epg.map_dad(dad_name => '&&dad_name', PATH => '/ps/*');
END;
/

-- Now we can give the DAD a default homepage and other useful attributes
BEGIN
   dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'default-page', attr_value => 'ps_ui.main');
   dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'authentication-mode', attr_value => 'Basic');

   -- "database-username" says the given DAD is being given the privs of the specified account.
   --
   -- If this is run from a schema other than the one mapping the DAD to itself,
   -- then you will need ALTER ANY USER system priv.
   --
   -- With ANONYMOUS unlocked, if you add this attribute, no login will be required
   -- to execute routines stored in the target user schema. With this commented
   -- out, you can run just about anything in any schema, but you will be prompted
   -- for a login every time.
   --
   -- There is another mode too, where the database-username is set, but the
   -- user is not authorized. See the following Oracle doc for further info:
   -- http://download.oracle.com/docs/cd/B28359_01/appdev.111/b28424/adfns_web.htm#CHEIJCAD
   --
   dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'database-username', attr_value => '&&ps_app_owner');

   -- Use either of the following attributes to get more communicative error pages
   -- More information on the error-style DAD directive can be obtained at:
   -- My Oracle Support, Note ID: 224496.1
   --dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'error-style', attr_value => 'ApacheStyle');
   dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'error-style', attr_value => 'ModplsqlStyle');
   --dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'error-style', attr_value => 'DebugStyle');

   -- Use this to ensure only certain routines, authorized routines (mapping 
   -- user in cookie or session to roles and authorized objects), or routines
   -- matching a certain parameter are allowed to run. It must be a function that
   -- returns a boolean value.
   --dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'request-validation-function', attr_value => 'auth_func');
   
   -- Used for unstructured upload/download
   --dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'document-procedure', attr_value => 'docs.download');
   --dbms_epg.set_dad_attribute(dad_name => '&&dad_name', attr_name => 'document-table-name', attr_value => 'ps_doc');
   COMMIT;
END;
/

-- Unlock the ANONYMOUS account while we are still SYSDBA, otherwise the 
-- embedded gateway will prompt us for the username and password of the XDB
-- security realm every time we begin a session with the mapped application.
ALTER USER anonymous ACCOUNT UNLOCK;

-- Using DBA privs, grant Core objects directly to sample app schema, so we can
-- write PL/SQL against them.
@@_grants_from_core_to_sol.sql

CONN &&ps_app_owner/&&ps_app_owner_pswd@&db_name

-- Here we give the DAD the right to execute procedures as if it were the
-- target user. Multiple users can authorize a single DAD.
BEGIN
   dbms_epg.authorize_dad(dad_name => '&&dad_name', USER => UPPER('&&ps_app_owner'));
END;
/

@@_create_synonyms_for_core_objs.sql

-- The following must run from the schema that will own the Problem/Solution tables and code
PROMPT Cleaning up previous installations...
DROP TABLE ps_sol CASCADE CONSTRAINTS PURGE;
DROP TABLE ps_prob CASCADE CONSTRAINTS PURGE;
DROP TABLE ps_prob_src PURGE;
DROP SEQUENCE ps_prob_seq;
DROP SEQUENCE ps_sol_seq;
DROP SEQUENCE ps_prob_src_seq;

PROMPT Creating new objects...
CREATE SEQUENCE ps_prob_src_seq;
CREATE SEQUENCE ps_prob_seq;
CREATE SEQUENCE ps_sol_seq;

CREATE TABLE ps_prob_src
(
 prob_src_id INTEGER NOT NULL
,prob_src_nm VARCHAR2(30 CHAR) NOT NULL
,prob_src_defn VARCHAR2(255 CHAR) NOT NULL
,display_order NUMBER NOT NULL
,active_flg VARCHAR2(1 BYTE) DEFAULT 'Y' NOT NULL
,prnt_prob_src_id INTEGER
,CONSTRAINT ps_prob_src_pk PRIMARY KEY (prob_src_id)
,CONSTRAINT ps_prob_src_uk UNIQUE (prob_src_nm)
,CONSTRAINT pps_active_flg_chk CHECK (active_flg IN ('Y','N'))
,CONSTRAINT pps_prnt_prob_src_id_fk FOREIGN KEY (prnt_prob_src_id) REFERENCES ps_prob_src (prob_src_id)
)
/
CREATE INDEX pps_prnt_prob_src_id_idx ON ps_prob_src(prnt_prob_src_id)
/
COMMENT ON TABLE ps_prob_src IS 'Problem Source: User-amendable list of the various sources of problems encountered in an IT shop.';
COMMENT ON COLUMN ps_prob_src.prob_src_id IS 'Problem Source ID: Surrogate key for this table. Currently filled manually by data population scripts.';
COMMENT ON COLUMN ps_prob_src.prob_src_nm IS 'Problem Source Value: Name or code for the source system, environment, hardware or software from which the error was first detected or originated.';
COMMENT ON COLUMN ps_prob_src.prob_src_defn IS 'Problem Source Definition: Full definition of the source system, environment, hardware or software from which the error was first detected or originated.';
COMMENT ON COLUMN ps_prob_src.display_order IS 'Display Order: In case the users wish one set of values to be ordered in a non-alphabetical manner, this allows them to customize the ordering of values.';
COMMENT ON COLUMN ps_prob_src.active_flg IS 'Active Flag: Flag that indicates if the record is active (Y) or not (N).';
COMMENT ON COLUMN ps_prob_src.prnt_prob_src_id IS 'Parent Problem Source ID: Self-referring foreign key. Filled if the sources of problems become so numerous that categorization or hierarchy is needed.';

CREATE TABLE ps_prob
(
 prob_id INTEGER NOT NULL
,prob_key VARCHAR2(50 CHAR) NOT NULL
,prob_key_txt VARCHAR2(4000 CHAR)
,prob_notes VARCHAR2(4000 CHAR)
,prob_src_id INTEGER
,otx_sync_col VARCHAR2(1 BYTE) DEFAULT 'N' NOT NULL
,CONSTRAINT ps_prob_pk PRIMARY KEY (prob_id)
,CONSTRAINT ps_prob_uk UNIQUE (prob_key, prob_key_txt)
,CONSTRAINT ps_prob_src_id_fk FOREIGN KEY (prob_src_id) REFERENCES ps_prob_src (prob_src_id)
)
/
CREATE INDEX psp_prob_src_id_idx ON ps_prob(prob_src_id)
/
COMMENT ON TABLE ps_prob IS 'Problem: Record of the errors, issues and problems encountered day-to-day.';
COMMENT ON COLUMN ps_prob.prob_id IS 'Problem ID: Surrogate key for records in this table.';
COMMENT ON COLUMN ps_prob.prob_key IS 'Problem Key: Typically the OS, Database, or application-specific error
 ID or name. Usually found at the top of an error stack, or in the title of error and warning dialogs. If
 this problem is not related to an identifiable error, give the problem a short name or code which
 adequately identifies the situation.';
COMMENT ON COLUMN ps_prob.prob_key_txt IS 'Problem Key Text: Optional. Typically the error message that came
 with the error ID, minus the specific non-repeatable, contextual information.';
COMMENT ON COLUMN ps_prob.prob_notes IS 'Problem Notes: You could use this field to store context surrounding
 the problem, like time of day it was observed, environment, concurrent processes, contacts, vendor case
 IDs, etc.';
COMMENT ON COLUMN ps_prob.prob_src_id IS 'Problem Source ID: Optional ID of the problem source. FK to PS_PROB_SRC.';
COMMENT ON COLUMN ps_prob.otx_sync_col IS 'Oracle Text Sync Column: A dummy column used as both the base column for multi-column context indexes, as well as the column that must be updated to Y whenever any data is changed or added so that the Oracle Text CTX_DDL.sync procedure will pick up the changes.';

CREATE TABLE ps_sol
(
 sol_id INTEGER NOT NULL
,prob_id INTEGER NOT NULL
,sol_notes VARCHAR2(4000)
,CONSTRAINT ps_sol_pk PRIMARY KEY (sol_id)
,CONSTRAINT pss_prob_id_fk FOREIGN KEY (prob_id) REFERENCES ps_prob (prob_id)
)
/
COMMENT ON TABLE ps_sol IS 'Solution: Record of the possible solutions to a given problem. Some problems 
 will have only one solutions, others may have several alternatives.';
COMMENT ON COLUMN ps_sol.sol_id IS 'Solution ID: Surrogate key for records in this table.';
COMMENT ON COLUMN ps_sol.prob_id IS 'Problem ID: Foreign key to PS_PROB.';
COMMENT ON COLUMN ps_sol.sol_notes IS 'Solution Notes: Steps to take to solve the related problem.';

CREATE INDEX pss_prob_id_idx ON ps_sol (prob_id)
/

PROMPT Populating new objects...
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,  'ORA Errors', 'Oracle Errors of all kinds (ORA, PLS, TNS, etc.)', 1, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,'Oracle Database','Problems with Oracle Database Server',1.1,'Y',1);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,'Oracle EPG','Problems with Oracle Embedded PL/SQL Gateway',1.2,'Y',1);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,'Oracle Text','Problems using Oracle Text',1.3,'Y',1);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,  'Windows', 'Windows error messages, shortcuts, tips and tricks.', 2, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,  'Shell', 'Problems working with shell scripts.', 3, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,  'Linux', 'Linux annoyances.', 4, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,  'Java', 'Issues workinng with Java.', 5, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,  'SubVersion', 'Problems with Subversion.', 6, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.nextval,  'App Server', 'Issues with the application server.', 7, 'Y', NULL);
COMMIT;

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.nextval
   ,'ORA-03113'
   ,'End-of-file on communication channel (Network connection lost)'
   ,'Common error encountered when connection to the database is severed.'
   ,1
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.nextval
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'ORA-03113')
   ,'This error sometimes happens when you encounter nasty bugs in Oracle. 
   But the most typical explanation for a 3113 is that something about the network between you and the database went sour. 
   Check your cable or wireless. 
   Ensure the database host and database are still reachable with ping and tnsping.
   Usually a 3113 just goes away when you try to connect again.');

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.nextval
   ,'TNS-12523'
   ,'TNS:listener could not find instance appropriate for the client connection.'
   ,'Encountered this error in the listener.log of both 10g XE and 10g EE when attempting to contact the EPG over http, port 8080.'
   ,1
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.nextval
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'TNS-12523')
   ,'One solution to this problem turned out to be a local client firewall (Sophos). It had a default configuration from 
   corporate HQ engineering that prevented http requests. Both turning off the firewall and later getting engineering to
   put me in the special Oracle group where that sort of traffic was allowed solved my problem.');

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.nextval
   ,'DAD Not Reachable'
   ,'Attempts to reach procs in the schema behind the DAD returned nothing. No 404 error page. No HTML whatsoever. Just a blank page.'
   ,'Mainly tried changing the port being used by the EPG to listen for HTTP traffic. No luck. 
   Tried the same with Oracle XE which comes with a built-in setup for HTTP traffic to support APEX. Still didn''t work.'
   ,2
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.nextval
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'DAD Not Reachable')
   ,'No error message or returned HTML should have been a big clue that the HTTP request was not reaching the EPG.
   Checking the Windows application log didn''t help. Finally checked the laptop''s firewall client logs 
   and found tnslsnr.exe and oracle.exe were being rejected by the firewall. Got the engineering group to
   add me to a special Oracle group that allows that kind of TCP traffic on my laptop. EPG is working fine now.');   

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.nextval
   ,'printjoins'
   ,''
   ,'Using the printjoins attribute of the Oracle Text lexer preference does not seem to be working. Indexing
   with printjoins in the lexer does not complain and the tokens in the underlying DR$ index table seem fine.
   But attempts to search with the CONTAINS operator don''t yield expected results. This is true for both
   dashes and underscore characters.'
   ,3
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.nextval
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'printjoins')
   ,'You must escape the "-" or "_" characters if the user inputs them in the search string in order for the CONTAINS operator to see them and include them in the search against the Context index.');   

--------------------------------------------------------------------------------
INSERT INTO ps_prob
   (prob_id
   ,prob_key
   ,prob_key_txt
   ,prob_notes
   ,prob_src_id
   ,otx_sync_col)
VALUES
   (ps_prob_seq.nextval
   ,'Explorer Stinks'
   ,'Much functionality was lost with Windows NT 3.51 File Explorer. Really miss double panes.'
   ,''
   ,4
   ,'Y');

INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.nextval
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'Explorer Stinks')
   ,'Download and enjoy FreeCommander. http://www.freecommander.com. Has everything a developer needs.');   
INSERT INTO ps_sol
   (sol_id
   ,prob_id
   ,sol_notes)
VALUES
   (ps_sol_seq.nextval
   ,(SELECT prob_id FROM ps_prob WHERE prob_key = 'Explorer Stinks')
   ,'You could also try eXplorer2 from zabkat.');   

COMMIT;
 
PROMPT Compiling packages...
SET DEFINE OFF
@@ps_dml.pks
@@ps_ui.pks
@@ps_ctx.pks
@@ps_ui.pkb
@@ps_dml.pkb
@@ps_ctx.pkb
@@_otx_prefs_and_index.sql
SET DEFINE ON

SPOOL OFF
SET VERIFY ON
