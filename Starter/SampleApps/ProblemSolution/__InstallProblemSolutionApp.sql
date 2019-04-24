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
ACCEPT fmwk_home CHAR DEFAULT 'Core' PROMPT "Enter the name of the account where the Core framework resides (Default is CORE): "
ACCEPT ps_app_owner CHAR DEFAULT 'SOL' PROMPT "Enter the account that will own the Solutions application (Default is SOL): "
ACCEPT ps_app_owner_pswd CHAR DEFAULT 'sol' PROMPT "Enter the Solutions account password (Default is SOL): " HIDE
ACCEPT db_name CHAR DEFAULT '&&core_db' PROMPT "Enter the database SID or service name where these operations are to execute (Default is &&core_db): "
ACCEPT dad_name CHAR DEFAULT 'ProbSol' PROMPT "Enter the Database Access Descriptor for the Solutions app (Default is ProbSol): "

PROMPT Creating user &&ps_app_owner...

------------                       CREATE USER                        ----------
CREATE USER &&ps_app_owner
  IDENTIFIED BY "&&ps_app_owner_pswd"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;
  
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
GRANT &&fmwk_home+_FULL TO &&ps_app_owner;
-- Give ability to authorize the DAD; seems to not be needed despite what the docs say.
--GRANT EXECUTE ON dbms_epg TO &&ps_app_owner;
GRANT ctxapp TO &&ps_app_owner;
GRANT EXECUTE ON CTXSYS.CTX_DDL TO &&ps_app_owner;
-- 10g, required for text index to be transactional
GRANT CREATE JOB TO &&ps_app_owner;

PROMPT On 10g and up, we must use DBMS_JAVA to grant access to java network 
PROMPT resources and access to directories.
SET SERVEROUTPUT ON
BEGIN
   dbms_java.grant_permission(UPPER('&&ps_app_owner'),'java.util.PropertyPermission','*','read,write');
   dbms_java.grant_permission(UPPER('&&ps_app_owner'),'java.net.SocketPermission','*','connect,resolve');
   dbms_java.grant_permission(UPPER('&&ps_app_owner'),'java.io.FilePermission','C:\temp\-','read,write');
   dbms_java.grant_permission(UPPER('&&ps_app_owner'),'java.io.FilePermission','C:\temp\logs\-','read,write');
END;
/

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

CREATE OR REPLACE TRIGGER u_after_logon_trg
AFTER LOGON ON &&ps_app_owner+.SCHEMA
DECLARE
BEGIN
   env.set_app_cd('PSOL');
END u_after_logon_trg
--------------------------------------------------------------------------------
--
--Thanks to the Oracle limitation that triggers and views can't utilize invoker
-- rights, this after long trigger ensures that the appropriate app_cd is chosen
-- and placed into context BEFORE the first view is selected from (which would
-- choose the wrong app_id and place it into memory.
--
--------------------------------------------------------------------------------
;
/

@@ps_ddl.sql
SET DEFINE OFF
@@ps_ctx.pks
@@ps_ctx.pkb
SET DEFINE ON
@@_otx_prefs_and_index.sql
@@_populate_addl_core_data.sql
@@_populate_probsol_ref_data.sql
@@_populate_sample_problems.sql
SET DEFINE OFF
@@ps_dml.pks
@@ps_ui.pks
@@ps_ui.pkb
@@ps_dml.pkb
SET DEFINE ON

SPOOL OFF
SET VERIFY ON
