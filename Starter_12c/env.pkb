CREATE OR REPLACE PACKAGE BODY env
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation

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
AS
--------------------------------------------------------------------------------
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'env';

TYPE tr_client_ctx IS RECORD(
   client_id      app_log.client_id%TYPE,
   client_ip      app_log.client_ip%TYPE,
   client_host    app_log.client_host%TYPE,
   client_os_user app_log.client_os_user%TYPE,
   client_program VARCHAR2(100),
   client_module  VARCHAR2(100),
   client_action  VARCHAR2(100),
   session_user   VARCHAR2(30),
   current_schema VARCHAR2(30),
   app_id         app.app_id%TYPE
);

TYPE tr_server_ctx IS RECORD (
   db_version INTEGER,
   db_name VARCHAR2(30),
   db_instance_name VARCHAR2(30),
   server_host VARCHAR2(40),
   sid INTEGER,
   os_pid INTEGER
);

gr_client_ctx tr_client_ctx; -- global record of user info
gr_server_ctx tr_server_ctx; -- global record of DB server info
gr_empty_client_ctx tr_client_ctx; -- used for re-initializations of session context for a user

--TYPE tr_stack_data IS RECORD (
--   owner VARCHAR2(30)
--,  obj_nm VARCHAR2(30)
--,  obj_type VARCHAR2(30)
--,  line_num NUMBER
--);
--TYPE tar_stack_data IS TABLE OF tr_stack_data INDEX BY BINARY_INTEGER;

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
ins
 This private INSERT to app_log routine is handy for debugging the ENV package.
 ENV is supposed to be the lowest level in the package hierarchy (along with CNST,
 TYP, DT, STR and NUM), so it cannot call routines in the LOGS or APP_LOG_API
 packages.

 Uncomment this routine and recompile if you need to debug something within ENV.

%design
 Must use autonomous transaction in order to see the results immediately in the
 table.
------------------------------------------------------------------------------*/
PROCEDURE ins(i_log_txt IN VARCHAR2) IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   lr_app_log app_log%ROWTYPE;
BEGIN

   lr_app_log.log_id := app_log_seq.NEXTVAL;

   lr_app_log.app_id      := 0;
   lr_app_log.log_ts      := dt.get_systs;
   lr_app_log.sev_cd      := cnst.INFO;
   lr_app_log.msg_cd      := msgs.DEFAULT_MSG_CD;
   lr_app_log.routine_nm  := cnst.UNKNOWN_STR;
   lr_app_log.line_num    := NULL;
   lr_app_log.log_txt     := i_log_txt;
   lr_app_log.client_id   := get_client_id;

   INSERT INTO app_log
   VALUES lr_app_log;

   COMMIT; -- must be here for autonomous to work
END ins;

/**-----------------------------------------------------------------------------
bundle_stack_lines:
 Gets the current call_stack and parses useful information out of it into
 an array for further processing as the caller sees fit.

 In 9i a call stack looks like this:
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
0x75c30c5c        94  package body APP_CORE.ENV
0x75c30c5c       569  package body APP_CORE.ENV
0x730f6920        58  package body APP_CORE.BOTTOM
0x74be5fd0        13  package body APP_CORE.MIDDLE
0x737e7d04         5  package body APP_CORE.TOP
0x6e8d32e0         2  anonymous block

 In 10g a call stack looks like this:
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
2E943CFC        94  package body APP_CORE.ENV
2E943CFC       569  package body APP_CORE.ENV
2E908B0C        58  package body APP_CORE.BOTTOM
2E909084        13  package body APP_CORE.MIDDLE
2E9095FC         5  package body APP_CORE.TOP
2E8AF158         2  anonymous block

 lines 1-3 are header info we don't need
 line 4 is ME, the immediate block where format_call_stack was just called
 line 5 is MY Caller
 line 6 is Their Caller
 and so on...

 Much of this is from Tom Kyte's "who_called_me" procedure.
------------------------------------------------------------------------------*/
--PROCEDURE bundle_stack_lines
--(oar_stack_data OUT tar_stack_data)
--AS
--   l_call_stack  VARCHAR2(4096) DEFAULT DBMS_UTILITY.format_call_stack;
--   l_pos  PLS_INTEGER := 0;
--   l_line  VARCHAR2(255);
--   l_cnt  PLS_INTEGER := 0;
--   lar_stack_data tar_stack_data;
--BEGIN
--   --dbms_output.put_line('bundle_stack_lines:');
--   --dbms_output.put_line(substr(l_call_stack,1,255));
--   l_pos := INSTR(l_call_stack,CHR(10),1,3); --bypasses header lines
--   l_call_stack := SUBSTR(l_call_stack, l_pos + 1); --removes header lines
--
--   -- loop through lines in stack and pull out good stuff into array
--   WHILE (l_call_stack IS NOT NULL) LOOP
--      l_cnt := l_cnt + 1;
--
--      l_pos := INSTR(l_call_stack,CHR(10)); -- get pos of next linefeed
--
--      EXIT WHEN (l_pos IS NULL OR l_pos = 0); -- should exit when no more linefeeds
--
--      l_line := SUBSTR(l_call_stack, 1, l_pos - 1);
--      l_call_stack := SUBSTR(l_call_stack, l_pos + 1);
--
--      -- Trip address off left side of line
--      l_line := LTRIM(SUBSTR(l_line, INSTR(l_line,CHR(32))));
--
--      -- First thing we care about is the line number
--      lar_stack_data(l_cnt).line_num := TO_NUMBER(SUBSTR(l_line, 1, INSTR(l_line,CHR(32))-1));
--
--      -- Need whatever's left after the line number
--      l_line := LTRIM(SUBSTR(l_line, LENGTH(lar_stack_data(l_cnt).line_num)+2));
--
--      IF (l_line LIKE 'pr%') THEN
--         l_pos := LENGTH('procedure ');
--      ELSIF (l_line LIKE 'fun%') THEN
--         l_pos := LENGTH('function ');
--      ELSIF (l_line LIKE 'package body%') THEN
--         l_pos := LENGTH('package body ');
--      ELSIF (l_line LIKE 'pack%') THEN
--         l_pos := LENGTH('package ');
--      ELSIF (l_line LIKE 'anonymous%') THEN
--         l_pos := LENGTH('anonymous block ');
--      ELSE
--         l_pos := NULL;
--      END IF;
--
--      IF (l_pos IS NOT NULL) THEN
--         lar_stack_data(l_cnt).obj_type := LTRIM(RTRIM(UPPER(SUBSTR(l_line, 1, l_pos - 1))));
--      ELSE
--         lar_stack_data(l_cnt).obj_type := 'TRIGGER';
--      END IF;
--
--      l_line := SUBSTR(l_line, NVL(l_pos, 1));
--      l_pos := INSTR(l_line, '.');
--
--      IF (l_pos > 0) THEN
--         lar_stack_data(l_cnt).owner := LTRIM(RTRIM(SUBSTR(l_line, 1, l_pos - 1)));
--         lar_stack_data(l_cnt).obj_nm := LTRIM(RTRIM(SUBSTR(l_line, l_pos + 1)));
--      ELSE
--         lar_stack_data(l_cnt).owner := env.get_current_schema;
--         lar_stack_data(l_cnt).obj_nm := 'ANONYMOUSBLOCK';
--      END IF;
--   END LOOP;
--
--   FOR i IN lar_stack_data.FIRST..lar_stack_data.LAST LOOP
--      -- these three lines for testing only
----      app_log_api.ins(i_log_txt => lar_stack_data(i).owner||'.'||lar_stack_data(i).obj_type||'.'||
----                      lar_stack_data(i).obj_nm||' @ line '||lar_stack_data(i).line_num,
----                      i_routine_nm => 'env.bundle_stack_lines');
--      IF (lar_stack_data(i).obj_nm <> 'ENV') THEN
--         oar_stack_data(oar_stack_data.COUNT+1) := lar_stack_data(i);
--      END IF;
--   END LOOP;
--
--END bundle_stack_lines;

/**-----------------------------------------------------------------------------
push_trace_stack
 Private routine to place another set of tracing values onto the top of stack.
------------------------------------------------------------------------------*/
PROCEDURE push_trace_stack
(
   i_module   IN VARCHAR2 DEFAULT NULL,
   i_action   IN VARCHAR2 DEFAULT NULL,
   i_info     IN VARCHAR2 DEFAULT NULL
)
IS
   l_idx INTEGER := 0;
BEGIN
   l_idx := g_trace_stack.COUNT+1;
   g_trace_stack(l_idx).module := i_module;
   g_trace_stack(l_idx).action := i_action;
   g_trace_stack(l_idx).client_info := i_info;
END push_trace_stack;

/**-----------------------------------------------------------------------------
pop_trace_stack
 Private routine to remove the last set of tracing values from the top of the
 stack.
------------------------------------------------------------------------------*/
PROCEDURE pop_trace_stack
IS
   l_idx INTEGER := 0;
BEGIN
   l_idx := g_trace_stack.COUNT;
   IF (l_idx = 0) THEN
      RETURN;
   ELSE
      g_trace_stack.DELETE(l_idx);
   END IF;
END pop_trace_stack;

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_client_id RETURN VARCHAR2 IS
BEGIN
   -- This should have been set by init_client_ctx, when called by the front-end
   -- at the start of the session or transaction. If it is not yet set, this
   -- means the application is either not using this package, or someone logged
   -- into an account with privs on the application schema, and is triggering
   -- auditing code that requires this function.

   --ins('get_client_id[gr_client_ctx.client_id = '||gr_client_ctx.client_id||']');

   IF (gr_client_ctx.client_id IS NULL) THEN
      gr_client_ctx.client_id := SYS_CONTEXT('userenv', 'client_identifier');
      -- If no client_identifier is available, we'll have to give it something, so grab
      -- identifying information from the data dictionary.
      IF (gr_client_ctx.client_id IS NULL) THEN
         gr_client_ctx.client_id := SUBSTR(get_client_host||':'||
         $IF $$vsession_avail $THEN get_client_program||':'||$END
         get_client_os_user,1,255);
      END IF;
   END IF;

   RETURN gr_client_ctx.client_id;
END get_client_id;

--------------------------------------------------------------------------------
FUNCTION get_client_ip RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.client_ip IS NULL) THEN
      gr_client_ctx.client_ip := SYS_CONTEXT('userenv', 'ip_address');
   END IF;
   RETURN gr_client_ctx.client_ip;
END get_client_ip;

--------------------------------------------------------------------------------
FUNCTION get_client_host RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.client_host IS NULL) THEN
      gr_client_ctx.client_host := SYS_CONTEXT('userenv', 'host');
   END IF;
   RETURN gr_client_ctx.client_host;
END get_client_host;

--------------------------------------------------------------------------------
FUNCTION get_client_os_user RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.client_os_user IS NULL) THEN
      gr_client_ctx.client_os_user := SYS_CONTEXT('userenv', 'os_user');
   END IF;
   RETURN gr_client_ctx.client_os_user;
END get_client_os_user;

--------------------------------------------------------------------------------
$IF $$vsession_avail $THEN
FUNCTION get_client_program RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.client_program IS NULL) THEN
      SELECT program
        INTO gr_client_ctx.client_program
        FROM v$session
       WHERE sid = get_sid;
   END IF;
   RETURN gr_client_ctx.client_program;
END get_client_program;
$END
--------------------------------------------------------------------------------
FUNCTION get_client_module RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.client_module IS NULL) THEN
      IF (get_db_version < 10) THEN
         SELECT module
           INTO gr_client_ctx.client_module
           FROM v$session
          WHERE sid = get_sid;
      ELSE
         gr_client_ctx.client_module := SYS_CONTEXT('userenv', 'module');
      END IF;
   END IF;
   RETURN gr_client_ctx.client_module;
END get_client_module;

--------------------------------------------------------------------------------
FUNCTION get_client_action RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.client_action IS NULL) THEN
      IF (get_db_version < 10) THEN
         SELECT action
           INTO gr_client_ctx.client_action
           FROM v$session
          WHERE sid = get_sid;
      ELSE
         gr_client_ctx.client_action := SYS_CONTEXT('userenv', 'action');
      END IF;
   END IF;
   RETURN gr_client_ctx.client_action;
END get_client_action;

--------------------------------------------------------------------------------
FUNCTION get_session_user RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.session_user IS NULL) THEN
      gr_client_ctx.session_user := SYS_CONTEXT('userenv', 'session_user');
   END IF;
   RETURN gr_client_ctx.session_user;
END get_session_user;

--------------------------------------------------------------------------------
FUNCTION get_current_schema RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.current_schema IS NULL) THEN
      -- The current_schema can be statically set by calling set_current_schema. If
      -- that hasn't been called, then the current_schema will be obtained from the
      -- data dictionary for the current execution context, and placed in the local
      -- memory structure and application context.
      set_current_schema(SYS_CONTEXT('userenv', 'current_schema'));
   END IF;
   RETURN gr_client_ctx.current_schema;
END get_current_schema;

--------------------------------------------------------------------------------
FUNCTION get_db_version RETURN NUMBER IS
--   l_version     VARCHAR2(30);

BEGIN
   /*
   NOTE: Originally this routine used a read and parse of banner from v$version
   for older versions of Oracle. But nowadays, everyone is on 9iR2 or higher, so
   the old guts of this function were ripped out and replaced by the simple
   call to dbms_db_version. I'm only keeping this around for backwards compatibility.

   If you are still on an old version of Oracle trying to make the framework compile,
   I could email you the old code that relied on v$version. Alternatively, you could
   re-implement the body of this routine using dbms_utility.db_version which returns
   two parameters: the version string and compatiblity version.
   */
   IF (gr_server_ctx.db_version IS NULL) THEN
      gr_server_ctx.db_version := dbms_db_version.version;
   END IF;

   RETURN gr_server_ctx.db_version;

END get_db_version;

--------------------------------------------------------------------------------
FUNCTION get_db_name RETURN VARCHAR2 IS
BEGIN
   IF (gr_server_ctx.db_name IS NULL) THEN
      gr_server_ctx.db_name := UPPER(SYS_CONTEXT('userenv', 'con_name'));
   END IF;
   RETURN gr_server_ctx.db_name;
END get_db_name;

--------------------------------------------------------------------------------
FUNCTION get_db_instance_name RETURN VARCHAR2 IS
   l_instance_name typ.t_instance_nm;
   lx_catalog_invisible EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_catalog_invisible,-942);
BEGIN
   IF (get_db_version < 10) THEN
      SELECT instance_name
        INTO l_instance_name
        FROM v$instance
       WHERE instance_number = SYS_CONTEXT('userenv', 'instance');
   ELSE
      l_instance_name := SYS_CONTEXT('userenv', 'instance_name');
   END IF;

   RETURN l_instance_name;
EXCEPTION
   WHEN lx_catalog_invisible OR NO_DATA_FOUND THEN
      RETURN cnst.UNKNOWN_STR;
END get_db_instance_name;

--------------------------------------------------------------------------------
FUNCTION get_db_instance_id RETURN NUMBER IS
   l_instance_id NUMBER;
BEGIN
   -- v$instance.inst_id and instance_number look exactly the same. I'm unsure
   -- if and when they would ever differ within a given RAC cluster.
   -- dbms_utility.current_instance seems to provide similar functionality
   l_instance_id := SYS_CONTEXT('userenv', 'instance');

   RETURN l_instance_id;

END get_db_instance_id;

--------------------------------------------------------------------------------
FUNCTION get_server_host RETURN VARCHAR2 IS
   l_host_name typ.t_host_nm;
   lx_catalog_invisible EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_catalog_invisible,-942);
BEGIN
   IF (get_db_version < 10) THEN
      SELECT host_name
        INTO l_host_name
        FROM v$instance
       WHERE instance_number = SYS_CONTEXT('userenv', 'instance');
   ELSE
      l_host_name := SYS_CONTEXT('userenv', 'server_host');
   END IF;
   RETURN l_host_name;
EXCEPTION
   WHEN lx_catalog_invisible OR NO_DATA_FOUND THEN
      RETURN cnst.unknown_str;
END get_server_host;

--------------------------------------------------------------------------------
--FUNCTION get_global_context_memory RETURN VARCHAR2 IS
--BEGIN
--   RETURN SYS_CONTEXT('userenv', 'global_context_memory');
--END get_global_context_memory;

--------------------------------------------------------------------------------
FUNCTION get_sid RETURN INTEGER IS
BEGIN
   RETURN get_session_id;
END get_sid;

--------------------------------------------------------------------------------
FUNCTION get_session_id RETURN INTEGER IS
   l_sid INTEGER := 0;
BEGIN
   IF (get_db_version < 10) THEN
      SELECT DISTINCT sid
        INTO l_sid
        FROM v$mystat;
   ELSE
      l_sid := SYS_CONTEXT('userenv', 'sid');
   END IF;

   RETURN l_sid;

END get_session_id;

--------------------------------------------------------------------------------
$IF $$vsession_avail $THEN
FUNCTION get_os_pid RETURN INTEGER
IS
   l_pid NUMBER := 0;
   lx_catalog_invisible EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_catalog_invisible,-942);
BEGIN

   EXECUTE IMMEDIATE '
   SELECT p.spid
     FROM v$session s,
          v$process p
    WHERE s.audsid = SYS_CONTEXT(''userenv'', ''sessionid'')
      AND s.paddr = p.addr '
   INTO l_pid;

   RETURN l_pid;
EXCEPTION
   WHEN lx_catalog_invisible OR NO_DATA_FOUND THEN
      RETURN l_pid; -- just return zero
--   WHEN TOO_MANY_ROWS THEN
--      ins('env.get_os_pid found more than one row.');
--      RETURN l_pid;
END get_os_pid;
$END

--------------------------------------------------------------------------------
FUNCTION get_schema_email_address RETURN VARCHAR2
IS
BEGIN
   RETURN get_current_schema||'_'||get_db_name||'@'||get_server_host||'.'||DOMAIN;
END get_schema_email_address;

--------------------------------------------------------------------------------
FUNCTION get_db_id RETURN INTEGER
IS
   l_db_id app_env.db_id%TYPE;
BEGIN
   SELECT db_id
   INTO l_db_id
   FROM app_db
   WHERE LOWER(db_nm) = LOWER(get_db_name);

   RETURN l_db_id;
END get_db_id;

--------------------------------------------------------------------------------
FUNCTION get_db_alias(i_db IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
   l_db_alias  app_db.db_alias%TYPE;
BEGIN

   IF (UPPER(i_db) LIKE 'MSSW%') THEN
      l_db_alias := LOWER(i_db);
   ELSE
      SELECT LOWER(db_alias)
        INTO l_db_alias
        FROM app_db
       WHERE db_nm = NVL(UPPER(i_db),UPPER(env.get_db_name))
          OR db_alias = UPPER(i_db);
   END IF;

   RETURN l_db_alias;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20000, i_db || ' is not a valid database SID, service name or alias.');
END get_db_alias;

--------------------------------------------------------------------------------
FUNCTION get_app_id(i_app_cd IN app.app_cd%TYPE) RETURN NUMBER IS
   l_app_id app.app_id%TYPE;
   l_app_cd app.app_cd%TYPE;
BEGIN
   IF (i_app_cd IS NULL) THEN
      -- Here the app_cd is missing. So we are assuming the caller wants us to
      -- determine the application dynamically using the application context or
      -- data dictionary (data as set up in APP, APP_DB, and APP_ENV).

      IF (gr_client_ctx.app_id IS NULL) THEN

         --ins('get_app_id:  gr_client_ctx.app_id is NULL');

         -- Attempt to get app code from the default context. Could be set by
         -- an after logon trigger.
         l_app_cd := SYS_CONTEXT(app_core_ctx, 'app_cd');

         --ins('get_app_id:  app_cd in app_core_ctx is ['||l_app_cd||']');

         IF (l_app_cd IS NOT NULL)  THEN
            SELECT app_id
              INTO l_app_id
              FROM app
             WHERE LOWER(app_cd) = LOWER(l_app_cd);
         ELSE
         BEGIN
            SELECT app_id
              INTO l_app_id
              FROM app_env aev,
                   app_db  adb
             WHERE adb.db_nm = UPPER(SYS_CONTEXT('userenv', 'con_name'))
               AND aev.db_id = adb.db_id
               AND (
                    aev.access_account = SYS_CONTEXT('userenv', 'session_user')
                    OR
                    aev.owner_account = SYS_CONTEXT('userenv', 'current_schema')
                   );

         EXCEPTION
            WHEN TOO_MANY_ROWS THEN
               -- Multiple matches will happen in access and object-owning
               -- accounts when multiple applications run out of the same schema.
               -- We will try to get the app_id one more time from APP_DB and
               -- APP_ENV using just the access_account. After that, if we still have
               -- too many rows, then the caller is the owning schema that has
               -- the multiple apps, which will require the app_cd set in context
               -- in order to resolve. If the app_cd has not been set in context,
               -- we'll raise an error.
               BEGIN
                  SELECT app_id
                    INTO l_app_id
                    FROM app_env aev,
                         app_db  adb
                   WHERE adb.db_nm = UPPER(SYS_CONTEXT('userenv', 'con_name'))
                     AND aev.db_id = adb.db_id
                     AND aev.access_account = SYS_CONTEXT('userenv', 'session_user');
               EXCEPTION
                  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
                        RAISE_APPLICATION_ERROR(-20000, 'Unable to determine '||
                           'application from environment, Core tables or '||
                           env.app_core_ctx||'.app_cd ['||
                           NVL(SYS_CONTEXT(app_core_ctx, 'app_cd'),'Not Set')||'].');
               END; -- second attempt using just access account
         END; -- first attempt using owner or access account
         END IF;

         -- One of the three SELECT statements above should have found it by now.
         -- Store in package structure that is kept in memory. Future calls to
         -- env.get_app_id will be very quick as only this struct will be read.
         gr_client_ctx.app_id := l_app_id;

      ELSE
         l_app_id := gr_client_ctx.app_id;
      END IF;
   ELSE
      -- Here we are given the app_cd, so we'll just do a simple lookup and not
      -- assume the caller wants it stored in the session's UGA.
      SELECT app_id
        INTO l_app_id
        FROM app
       WHERE LOWER(app_cd) = LOWER(i_app_cd);
   END IF;

   RETURN l_app_id;

   -- We do not handle NO_DATA_FOUND on purpose so that the error bubbles up,
   -- clearly indicating that data and/or schemas aren't set up properly.
END get_app_id;

--------------------------------------------------------------------------------
FUNCTION get_app_cd(i_app_id IN app.app_id%TYPE DEFAULT NULL) RETURN VARCHAR2 IS
   l_app_cd app.app_cd%TYPE;
BEGIN
   IF (i_app_id IS NOT NULL) THEN
      SELECT app_cd
        INTO l_app_cd
        FROM app
       WHERE app_id = i_app_id;
   ELSE
      SELECT app_cd
        INTO l_app_cd
        FROM app
       WHERE app_id = get_app_id;
   END IF;

   RETURN l_app_cd;

   -- We do not handle NO_DATA_FOUND on purpose so that the error bubbles up,
   -- clearly indicating that data and/or schemas aren't set up properly.
END get_app_cd;

--------------------------------------------------------------------------------
FUNCTION get_env_nm(i_app_cd IN app.app_cd%TYPE DEFAULT NULL) RETURN VARCHAR2 IS
   l_env_nm app_env.env_nm%TYPE;
   l_app_id app_env.app_id%TYPE;
BEGIN
   -- i_app_cd may be empty, which will cause get_app_id to get app_cd dynamically
   l_app_id := get_app_id(i_app_cd);

   -- Get environment name by app_id
   BEGIN
      SELECT env_nm
        INTO l_env_nm
        FROM app_env
       WHERE app_id = l_app_id
         AND db_id = get_db_id
         AND owner_account = get_current_schema;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_env_nm := cnst.UNKNOWN_STR;
   END;

   RETURN l_env_nm;

END get_env_nm;

--------------------------------------------------------------------------------
FUNCTION get_env_nm(i_app_id IN app.app_id%TYPE) RETURN VARCHAR2 IS
   l_env_nm app_env.env_nm%TYPE;
   l_app_id app_env.app_id%TYPE;
BEGIN
   -- i_app_cd may be empty, which will cause get_app_id to get app_cd dynamically
   l_app_id := i_app_id;

   -- Get environment name by app_id
   BEGIN
      SELECT env_nm
        INTO l_env_nm
        FROM app_env
       WHERE app_id = l_app_id
         AND db_id = get_db_id
         AND owner_account = get_current_schema;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_env_nm := cnst.UNKNOWN_STR;
   END;

   RETURN l_env_nm;

END get_env_nm;

--------------------------------------------------------------------------------
FUNCTION get_env_id(i_app_cd IN app.app_cd%TYPE DEFAULT NULL) RETURN INTEGER IS
   l_env_id app_env.env_id%TYPE;
   l_app_id app_env.app_id%TYPE;
BEGIN
   -- i_app_cd may be empty, which will cause get_app_id to get app_cd dynamically
   l_app_id := get_app_id(i_app_cd);

   -- Get environment name by app_id
   BEGIN
      SELECT env_id
        INTO l_env_id
        FROM app_env
       WHERE app_id = l_app_id
         AND db_id = get_db_id
         AND owner_account = get_current_schema;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_env_id := null;
   END;

   RETURN l_env_id;

END get_env_id;

--------------------------------------------------------------------------------
FUNCTION get_env_id(i_app_id IN app.app_id%TYPE) RETURN INTEGER IS
   l_env_id app_env.env_id%TYPE;
   l_app_id app_env.app_id%TYPE;
BEGIN
   -- i_app_cd may be empty, which will cause get_app_id to get app_cd dynamically
   l_app_id := i_app_id;

   -- Get environment name by app_id
   BEGIN
      SELECT env_id
        INTO l_env_id
        FROM app_env
       WHERE app_id = l_app_id
         AND db_id = get_db_id
         AND owner_account = get_current_schema;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_env_id := null;
   END;

   RETURN l_env_id;

END get_env_id;

--------------------------------------------------------------------------------
FUNCTION get_dir_path(i_dir_nm IN VARCHAR2) RETURN VARCHAR2
IS
   l_dir_path all_directories.directory_path%TYPE;
BEGIN
   SELECT directory_path
   INTO l_dir_path
   FROM all_directories
   WHERE directory_name = UPPER(TRIM(i_dir_nm));

   RETURN l_dir_path;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN 'Directory '||i_dir_nm||' Not Found';
END get_dir_path;

--------------------------------------------------------------------------------
FUNCTION vld_path_format (i_path IN VARCHAR2) RETURN VARCHAR2
IS
BEGIN
   IF (SUBSTR(i_path,LENGTH(i_path),1) IN ('/','\')) THEN
      RETURN i_path;
   ELSE
      RETURN i_path||cnst.DIR_SEPCHAR;
   END IF;
END vld_path_format;

--------------------------------------------------------------------------------
--FUNCTION get_routine_nm(i_stack_level IN PLS_INTEGER DEFAULT 2) RETURN VARCHAR2
--IS
--BEGIN
----   dbms_output.put_line('From get_routine_nm');
----   FOR i IN 1..utl_call_stack.dynamic_depth() LOOP
----      dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.lexical_depth(i)),9)||
----                            str.ewc(TO_CHAR(i),6)||
----                            str.ewc(TO_CHAR(utl_call_stack.unit_line(i)),6)||
----                            str.ewc(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i)),60) );
----   END LOOP;
--
--   RETURN utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i_stack_level));
--END get_routine_nm;

--------------------------------------------------------------------------------
--FUNCTION get_error_point(i_stack_level IN PLS_INTEGER DEFAULT 1) RETURN INTEGER
--IS
--BEGIN
----   dbms_output.put_line('From get_line_of_error');
----   FOR i IN 1..utl_call_stack.error_depth() LOOP
----      dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.backtrace_line(i)),10)||
----                            str.ewc(SUBSTR(utl_call_stack.backtrace_unit(i),1,60),60) );
----   END LOOP;
--   RETURN utl_call_stack.backtrace_line(i_stack_level);
--END get_error_point;


--------------------------------------------------------------------------------
FUNCTION get_caller_nm(i_stack_level IN PLS_INTEGER DEFAULT 3) RETURN VARCHAR2
IS
   l_my_name app_log.routine_nm%TYPE;
BEGIN
--   dbms_output.put_line(dbms_utility.format_call_stack); -- 10g call stack, used to debug during 12c upgrade
--   FOR i IN 1..utl_call_stack.dynamic_depth() LOOP -- 12c call stack
--      dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.lexical_depth(i)),9)||
--                            str.ewc(TO_CHAR(i),6)||
--                            str.ewc(TO_CHAR(utl_call_stack.unit_line(i)),6)||
--                            str.ewc(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i)),60) );
--   END LOOP;
   IF (i_stack_level <= utl_call_stack.dynamic_depth) THEN
      l_my_name := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i_stack_level));
   ELSE
      l_my_name := cnst.unknown_str;
   END IF;

   RETURN l_my_name;
END get_caller_nm;

--------------------------------------------------------------------------------
FUNCTION get_caller_line(i_stack_level IN PLS_INTEGER DEFAULT 3) RETURN INTEGER
IS
   l_line_num INTEGER;
BEGIN
   IF (i_stack_level <= utl_call_stack.dynamic_depth) THEN
      l_line_num := utl_call_stack.unit_line(i_stack_level);
   ELSE
      l_line_num := NULL;
   END IF;

   RETURN l_line_num;
END get_caller_line;

--------------------------------------------------------------------------------
FUNCTION get_my_nm(i_stack_level IN PLS_INTEGER DEFAULT 2) RETURN VARCHAR2
IS
   l_my_name app_log.routine_nm%TYPE;
BEGIN
--   dbms_output.put_line(dbms_utility.format_call_stack); -- 10g call stack, used to debug during 12c upgrade
--   FOR i IN 1..utl_call_stack.dynamic_depth() LOOP -- 12c call stack
--      dbms_output.put_line( str.ewc(TO_CHAR(utl_call_stack.lexical_depth(i)),9)||
--                            str.ewc(TO_CHAR(i),6)||
--                            str.ewc(TO_CHAR(utl_call_stack.unit_line(i)),6)||
--                            str.ewc(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i)),60) );
--   END LOOP;
   IF (i_stack_level <= utl_call_stack.dynamic_depth) THEN
      l_my_name := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i_stack_level));
   ELSE
      l_my_name := cnst.unknown_str;
   END IF;

   RETURN l_my_name;
END get_my_nm;

--------------------------------------------------------------------------------
FUNCTION get_my_line(i_stack_level IN PLS_INTEGER DEFAULT 2) RETURN INTEGER
IS
   l_line_num INTEGER;
BEGIN
   IF (i_stack_level <= utl_call_stack.dynamic_depth) THEN
      l_line_num := utl_call_stack.unit_line(i_stack_level);
   ELSE
      l_line_num := NULL;
   END IF;

   RETURN l_line_num;
END get_my_line;

--------------------------------------------------------------------------------
PROCEDURE tag_session
(
   i_module   IN VARCHAR2,
   i_action   IN VARCHAR2,
   i_info     IN VARCHAR2
)
IS
BEGIN

   -- We do not use excp.throw here so ENV can maintain low-level independence
   IF (LENGTH(i_module) > 48) THEN
      RAISE_APPLICATION_ERROR(-20000, 'ERROR: (Assertion Failure) ['||get_my_nm||']'||
         ' i_module must be 48 characters or less');
   ELSIF (LENGTH(i_action) > 32) THEN
      RAISE_APPLICATION_ERROR(-20000, 'ERROR: (Assertion Failure) ['||get_my_nm||']'||
         ': i_action must be 32 characters or less');
   ELSIF (LENGTH(i_info) > 64) THEN
      RAISE_APPLICATION_ERROR(-20000, 'ERROR: (Assertion Failure) ['||get_my_nm||']'||
         ': i_info must be 64 characters or less');
   END IF;

   push_trace_stack(i_module, i_action, i_info);

   dbms_application_info.set_module(i_module, i_action);
   dbms_application_info.set_client_info(i_info);

END tag_session;

--------------------------------------------------------------------------------
PROCEDURE tag
(
   i_module   IN VARCHAR2 DEFAULT NULL,
   i_action   IN VARCHAR2 DEFAULT NULL,
   i_info     IN VARCHAR2 DEFAULT NULL
)
IS
   l_module   typ.t_module := i_module;
   l_action   typ.t_action := i_action;
   l_info     typ.t_client_id := i_info;
BEGIN

   IF (l_module IS NULL OR l_action is NULL OR l_info IS NULL) THEN
      DECLARE
         l_unit_nm     typ.t_maxobjnm;
         l_routine_nm  app_log.routine_nm%TYPE;
      BEGIN
         l_routine_nm := get_caller_nm;
         IF (INSTR(l_routine_nm,'.') > 0) THEN
            -- assume it is a package and parse package name out for later comparison
            l_unit_nm := UPPER(SUBSTR(l_routine_nm,1,INSTR(l_routine_nm,'.')-1));
         ELSE
            -- transfer name of standalone unit to l_unit_nm
            l_unit_nm := UPPER(l_routine_nm);
         END IF;

         IF (i_module IS NULL) THEN
            l_module := l_unit_nm;
         END IF;
         IF (i_action IS NULL) THEN
            -- substr to eliminate package name from routine name if dot-notation found
            l_action := SUBSTR(l_routine_nm,INSTR(l_routine_nm,'.')+1);
         END IF;
         IF (i_info IS NULL) THEN
            l_info := get_my_line;
         END IF;
      END;
   END IF;

   tag_session(l_module, l_action, l_info);

END tag;

--------------------------------------------------------------------------------
PROCEDURE untag_session(i_restore_prior_tag IN BOOLEAN DEFAULT TRUE) IS
   l_module   typ.t_module := NULL;
   l_action   typ.t_action := NULL;
   l_info     typ.t_client_id := NULL;
BEGIN
   pop_trace_stack;

   IF (i_restore_prior_tag) THEN
      IF (g_trace_stack.COUNT > 0) THEN
         l_module := g_trace_stack(g_trace_stack.COUNT).module;
         l_action := g_trace_stack(g_trace_stack.COUNT).action;
         l_info   := g_trace_stack(g_trace_stack.COUNT).client_info;
      END IF;
   END IF;

   $IF (dbms_db_version.version = 11 AND dbms_db_version.release = 1) $THEN
      IF (l_info IS NULL) THEN
         l_info := ' ';
      END IF;
      dbms_application_info.set_client_info(l_info); -- bug in unpatched 11.1 won't unset client_info
   -- This conditional would be better if I could detect the existence of a patch
   $ELSE
      dbms_application_info.set_client_info(l_info);
   $END

   dbms_application_info.set_module(l_module, l_action);
END untag_session;

--------------------------------------------------------------------------------
PROCEDURE untag(i_restore_prior_tag IN BOOLEAN DEFAULT TRUE) IS
BEGIN
   untag_session(i_restore_prior_tag);
END untag;

--------------------------------------------------------------------------------
PROCEDURE set_ctx_val
(
   i_attr_nm  IN VARCHAR2,
   i_attr_val IN VARCHAR2,
   i_ctx_nm   IN VARCHAR2 DEFAULT APP_CORE_CTX
)
IS
BEGIN
   dbms_session.set_context(i_ctx_nm, i_attr_nm, i_attr_val);
END set_ctx_val;

--------------------------------------------------------------------------------
PROCEDURE set_app_cd
(
   i_app_cd IN app.app_cd%TYPE
)
IS
BEGIN
   IF (i_app_cd IS NOT NULL) THEN

      --ins('set_app_cd: setting app_id for app_cd '||i_app_cd);

      gr_client_ctx.app_id := get_app_id(i_app_cd);
      set_ctx_val('app_cd',i_app_cd);
   ELSE
      RAISE_APPLICATION_ERROR(-20000,'ERROR: (Assertion Failure) [env.set_app_cd]'||
         ' Application Code cannot be empty.');
   END IF;
END set_app_cd;

--------------------------------------------------------------------------------
PROCEDURE set_current_schema
(
   i_schema_nm IN app_env.access_account%TYPE
)
IS
BEGIN
   IF (i_schema_nm IS NOT NULL) THEN

      --ins('set_current_schema: setting current_schema to '||i_schema_nm);

      gr_client_ctx.current_schema := UPPER(i_schema_nm);
      set_ctx_val('current_schema',UPPER(i_schema_nm));
   ELSE
      RAISE_APPLICATION_ERROR(-20000,'ERROR: (Assertion Failure) [env.set_current_schema]'||
         ' Schema Name cannot be empty.');
   END IF;
END set_current_schema;

--------------------------------------------------------------------------------
PROCEDURE init_client_ctx
(
   i_client_id   IN VARCHAR2,
   i_client_ip   IN VARCHAR2 DEFAULT NULL,
   i_client_host IN VARCHAR2 DEFAULT NULL,
   i_client_os_user IN VARCHAR2 DEFAULT NULL,
   i_app_cd      IN VARCHAR2 DEFAULT NULL
) IS
BEGIN

   -- Populate in-memory structure with new identifier. If not passed in
   gr_client_ctx.client_id := i_client_id;

   IF (i_client_ip IS NOT NULL) THEN
      gr_client_ctx.client_ip := i_client_ip;
   END IF;
   IF (i_client_host IS NOT NULL) THEN
      gr_client_ctx.client_host := i_client_host;
   END IF;
   IF (i_client_os_user IS NOT NULL) THEN
      gr_client_ctx.client_os_user := i_client_os_user;
   END IF;
   IF (i_app_cd IS NOT NULL) THEN
      set_app_cd(i_app_cd);
   END IF;
   IF (gr_client_ctx.current_schema IS NULL) THEN
      set_current_schema(SYS_CONTEXT('userenv','current_schema'));
   END IF;
   -- Populate USERENV with the given client identifier
   dbms_session.set_identifier(i_client_id);
END init_client_ctx;

--------------------------------------------------------------------------------
PROCEDURE reset_client_ctx IS
BEGIN
   dbms_session.clear_identifier;
   dbms_session.modify_package_state(dbms_session.reinitialize);
   clear_ctx; -- clears Core framework context namespace
   gr_client_ctx := gr_empty_client_ctx; -- clears global variables for this package
END reset_client_ctx;

--------------------------------------------------------------------------------
PROCEDURE clear_ctx_val
(
   i_attr_nm  IN VARCHAR2,
   i_ctx_nm   IN VARCHAR2 DEFAULT APP_CORE_CTX
)
IS
BEGIN
   dbms_session.clear_context(i_ctx_nm, NULL, i_attr_nm);
END clear_ctx_val;

--------------------------------------------------------------------------------
PROCEDURE clear_ctx
(
   i_ctx_nm   IN VARCHAR2 DEFAULT APP_CORE_CTX
)
IS
BEGIN
   -- 10g only
   --dbms_session.clear_all_context(i_ctx_nm);

   -- clear_all_context doesn't exist in 9i
   dbms_session.clear_context(i_ctx_nm, NULL, NULL);
END clear_ctx;

END env;
/
