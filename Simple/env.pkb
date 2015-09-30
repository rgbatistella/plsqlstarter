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

TYPE tr_client_ctx IS RECORD(
   client_id      app_log.client_id%TYPE,
   client_ip      app_log.client_ip%TYPE,
   client_host    app_log.client_host%TYPE,
   client_os_user app_log.client_os_user%TYPE,
   client_program VARCHAR2(100),
   client_module  VARCHAR2(100),
   client_action  VARCHAR2(100),
   session_user   typ.t_maxobjnm,
   current_schema typ.t_maxobjnm
);

TYPE tr_server_ctx IS RECORD (
   db_version INTEGER,
   db_name typ.t_maxobjnm,
   db_instance_name typ.t_maxobjnm,   
   server_host typ.t_maxobjnm,
   sid INTEGER,
   os_pid INTEGER
);

gr_client_ctx tr_client_ctx; -- global record of user info
gr_server_ctx tr_server_ctx; -- global record of DB server info
gr_empty_client_ctx tr_client_ctx; -- used for re-initializations of session context for a user

TYPE tr_stack_data IS RECORD (
   owner typ.t_maxobjnm
,  obj_nm typ.t_maxobjnm
,  obj_type typ.t_maxobjnm
,  line_num NUMBER
);
TYPE tar_stack_data IS TABLE OF tr_stack_data INDEX BY BINARY_INTEGER;

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

   SELECT app_log_seq.NEXTVAL
     INTO lr_app_log.log_id
     FROM dual;

   lr_app_log.log_ts      := dt.get_systs;
   lr_app_log.sev_cd      := cnst.INFO;
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
PROCEDURE bundle_stack_lines
(oar_stack_data OUT tar_stack_data)
AS
   l_call_stack  VARCHAR2(4096) DEFAULT DBMS_UTILITY.format_call_stack;
   l_pos  PLS_INTEGER := 0;
   l_line  VARCHAR2(255);
   l_cnt  PLS_INTEGER := 0;
   lar_stack_data tar_stack_data;
BEGIN
   --dbms_output.put_line('bundle_stack_lines:');
   --dbms_output.put_line(substr(l_call_stack,1,255));
   l_pos := INSTR(l_call_stack,CHR(10),1,3); --bypasses header lines
   l_call_stack := SUBSTR(l_call_stack, l_pos + 1); --removes header lines

   -- loop through lines in stack and pull out good stuff into array
   WHILE (l_call_stack IS NOT NULL) LOOP
      l_cnt := l_cnt + 1;

      l_pos := INSTR(l_call_stack,CHR(10)); -- get pos of next linefeed

      EXIT WHEN (l_pos IS NULL OR l_pos = 0); -- should exit when no more linefeeds

      l_line := SUBSTR(l_call_stack, 1, l_pos - 1);
      l_call_stack := SUBSTR(l_call_stack, l_pos + 1);

      -- Trip address off left side of line
      l_line := LTRIM(SUBSTR(l_line, INSTR(l_line,CHR(32))));
      
      -- First thing we care about is the line number
      lar_stack_data(l_cnt).line_num := TO_NUMBER(SUBSTR(l_line, 1, INSTR(l_line,CHR(32))-1));

      -- Need whatever's left after the line number
      l_line := LTRIM(SUBSTR(l_line, LENGTH(lar_stack_data(l_cnt).line_num)+2));

      IF (l_line LIKE 'pr%') THEN
         l_pos := LENGTH('procedure ');
      ELSIF (l_line LIKE 'fun%') THEN
         l_pos := LENGTH('function ');
      ELSIF (l_line LIKE 'package body%') THEN
         l_pos := LENGTH('package body ');
      ELSIF (l_line LIKE 'pack%') THEN
         l_pos := LENGTH('package ');
      ELSIF (l_line LIKE 'anonymous%') THEN
         l_pos := LENGTH('anonymous block ');
      ELSE
         l_pos := NULL;
      END IF;

      IF (l_pos IS NOT NULL) THEN
         lar_stack_data(l_cnt).obj_type := LTRIM(RTRIM(UPPER(SUBSTR(l_line, 1, l_pos - 1))));
      ELSE
         lar_stack_data(l_cnt).obj_type := 'TRIGGER';
      END IF;

      l_line := SUBSTR(l_line, NVL(l_pos, 1));
      l_pos := INSTR(l_line, '.');

      IF (l_pos > 0) THEN
         lar_stack_data(l_cnt).owner := LTRIM(RTRIM(SUBSTR(l_line, 1, l_pos - 1)));
         lar_stack_data(l_cnt).obj_nm := LTRIM(RTRIM(SUBSTR(l_line, l_pos + 1)));
      ELSE
         lar_stack_data(l_cnt).owner := env.get_current_schema;
         lar_stack_data(l_cnt).obj_nm := 'ANONYMOUSBLOCK';
      END IF;
   END LOOP;

   FOR i IN lar_stack_data.FIRST..lar_stack_data.LAST LOOP
      -- these three lines for testing only
--      app_log_api.ins(i_log_txt => lar_stack_data(i).owner||'.'||lar_stack_data(i).obj_type||'.'||
--                      lar_stack_data(i).obj_nm||' @ line '||lar_stack_data(i).line_num,
--                      i_routine_nm => 'env.bundle_stack_lines');
      IF (lar_stack_data(i).obj_nm <> 'ENV') THEN
         oar_stack_data(oar_stack_data.COUNT+1) := lar_stack_data(i);
      END IF;
   END LOOP;

END bundle_stack_lines;

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
   -- initialize point at which we examine the existing trace stack
   l_idx := g_trace_stack.COUNT;
   
   -- Only add to the stack if a new module or action is beginning
   IF (l_idx = 0) THEN
      l_idx := g_trace_stack.COUNT+1;
   ELSIF (
       (g_trace_stack(l_idx).module IS NULL AND i_module IS NOT NULL) OR
       (g_trace_stack(l_idx).module IS NOT NULL AND g_trace_stack(l_idx).module <> i_module) OR
       (g_trace_stack(l_idx).action IS NULL AND i_action IS NOT NULL) OR
       (g_trace_stack(l_idx).action IS NOT NULL AND g_trace_stack(l_idx).action <> i_action)
      ) THEN
      l_idx := g_trace_stack.COUNT+1; -- create new entry on stack
   ELSE
      NULL; -- just update latest entry on stack
   END IF;
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
         gr_client_ctx.client_id := SUBSTR(get_client_host||':'||get_client_program||':'||get_client_os_user,1,255);
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
      gr_client_ctx.client_os_user := sys_context('userenv', 'os_user');
   END IF;
   RETURN gr_client_ctx.client_os_user;
END get_client_os_user;

--------------------------------------------------------------------------------
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
         gr_client_ctx.client_module := sys_context('userenv', 'module');
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
         gr_client_ctx.client_action := sys_context('userenv', 'action');
      END IF;
   END IF;
   RETURN gr_client_ctx.client_action;
END get_client_action;

--------------------------------------------------------------------------------
FUNCTION get_session_user RETURN VARCHAR2 IS
BEGIN
   IF (gr_client_ctx.session_user IS NULL) THEN
      gr_client_ctx.session_user := sys_context('userenv', 'session_user');
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
      gr_server_ctx.db_name := sys_context('userenv', 'db_name');
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
       WHERE instance_number = sys_context('userenv', 'instance');
   ELSE
      l_instance_name := sys_context('userenv', 'instance_name');
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
   l_instance_id := sys_context('userenv', 'instance');
   
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
       WHERE instance_number = sys_context('userenv', 'instance');
   ELSE
      l_host_name := sys_context('userenv', 'server_host');
   END IF;
   RETURN l_host_name;
EXCEPTION
   WHEN lx_catalog_invisible OR NO_DATA_FOUND THEN
      RETURN cnst.unknown_str;
END get_server_host;

--------------------------------------------------------------------------------
--FUNCTION get_global_context_memory RETURN VARCHAR2 IS
--BEGIN
--   RETURN sys_context('userenv', 'global_context_memory');
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
      l_sid := sys_context('userenv', 'sid');
   END IF;
   
   RETURN l_sid;
   
END get_session_id;

--------------------------------------------------------------------------------
FUNCTION get_os_pid RETURN INTEGER
IS
   l_pid NUMBER := 0;
   lx_catalog_invisible EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_catalog_invisible,-942);
BEGIN

   SELECT p.spid
     INTO l_pid
     FROM v$session s
         ,v$process p
    WHERE s.audsid = SYS_CONTEXT('USERENV', 'sessionid')
      AND s.paddr = p.addr;

--   EXECUTE IMMEDIATE '
--   SELECT p.spid
--     FROM v$session s,
--          v$process p
--    WHERE s.audsid = SYS_CONTEXT(''userenv'', ''sessionid'')
--      AND s.paddr = p.addr '
--   INTO l_pid;

   RETURN l_pid;
EXCEPTION
   WHEN lx_catalog_invisible OR NO_DATA_FOUND THEN
      RETURN l_pid; -- just return zero
--   WHEN TOO_MANY_ROWS THEN
--      ins('env.get_os_pid found more than one row.');
--      RETURN l_pid;
END get_os_pid;

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
FUNCTION who_called_me (
 i_stack_level IN PLS_INTEGER DEFAULT 2
)   RETURN VARCHAR2
IS
   lar_stack_data  tar_stack_data;
   l_my_name app_log.routine_nm%TYPE;
BEGIN
   bundle_stack_lines(lar_stack_data);
   IF (i_stack_level <= lar_stack_data.COUNT) THEN
      IF (UPPER(lar_stack_data(i_stack_level).obj_type) = 'PACKAGE BODY') THEN
         l_my_name := get_routine_nm(lar_stack_data(i_stack_level).obj_nm,
                                     lar_stack_data(i_stack_level).line_num);
      ELSE
         l_my_name := lar_stack_data(i_stack_level).obj_nm;
      END IF;
   ELSE
      l_my_name := cnst.UNKNOWN_STR;
   END IF;
   
   RETURN l_my_name;
END who_called_me;

--------------------------------------------------------------------------------
FUNCTION who_am_i(i_stack_level IN PLS_INTEGER DEFAULT 1) RETURN VARCHAR2 IS
   lar_stack_data tar_stack_data;
   l_my_name app_log.routine_nm%TYPE;
BEGIN
   bundle_stack_lines(lar_stack_data);
   IF (i_stack_level <= lar_stack_data.COUNT) THEN
      IF (UPPER(lar_stack_data(i_stack_level).obj_type) = 'PACKAGE BODY') THEN
         l_my_name := get_routine_nm(lar_stack_data(i_stack_level).obj_nm,
                                     lar_stack_data(i_stack_level).line_num);
      ELSE
         l_my_name := lar_stack_data(i_stack_level).obj_nm;
      END IF;
   ELSE
      l_my_name := cnst.UNKNOWN_STR;
   END IF;
   
   RETURN l_my_name;
END who_am_i;

--------------------------------------------------------------------------------
FUNCTION get_routine_nm
(
   i_pkg_nm   IN VARCHAR2,
   i_line_num IN INTEGER
) RETURN VARCHAR2
IS
   l_routine_nm app_log.routine_nm%TYPE;
BEGIN
   SELECT package_name || '.' || routine_name
     INTO l_routine_nm
     FROM -- Use RANK to get the containing routine, the one closest to the given line number
          (SELECT t.package_name,
                  t.routine_name,
                  t.start_line,
                  RANK() OVER(ORDER BY t.start_line DESC) rnk
             FROM -- Use TRANSLATE to parse the declarations into just the routine names, so they can be joined
                  -- to USER_ARGUMENTS to eliminate inner (nested) routines.
                  (
                  SELECT name AS package_name,
                         line AS start_line,
                         RTRIM(SUBSTR(after_token,1,INSTR(TRANSLATE(after_token,CHR(13)||CHR(10)||CHR(32)||'(/-','++++++'),'+')-1)) routine_name,
                         text AS orig_src_line
                    FROM -- Get all the routine declarations that came before the caller's line. One of them
                         -- must be the routine that contains the line.
                         (SELECT name,
                                 line,
                                 text,
                                 DECODE(SIGN(INSTR(UPPER(text), 'PROCEDURE')),
                                        1,
                                        TRIM(SUBSTR(UPPER(text), INSTR(UPPER(text), 'PROCEDURE') + 10)),
                                        TRIM(SUBSTR(UPPER(text), INSTR(UPPER(text), 'FUNCTION') + 9))
                                 ) after_token
                            FROM user_source
                           WHERE type = 'PACKAGE BODY'
                             AND name = UPPER(i_pkg_nm)
                             AND line <= i_line_num -- only look at code before the caller's line number
                             AND (UPPER(TRIM(text)) LIKE 'PROCEDURE%' OR UPPER(TRIM(text)) LIKE 'FUNCTION%'))
                  ) t
                  -- DISTINCT and analytic ROW_NUMBER yielded same response time, so went with more readable SQL
                  -- 2010Mar30: Unfortunately, this hides private routines as well, so going back to behavior
                  -- where inner routines mess it up.
--                 ,(SELECT DISTINCT package_name, object_name FROM user_arguments) ua
--            WHERE ua.package_name = t.package_name
--              AND t.routine_name = ua.object_name -- eliminates inner routines
          )
    WHERE rnk = 1;

    RETURN l_routine_nm;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
END get_routine_nm;

--------------------------------------------------------------------------------
FUNCTION line_num_here(i_stack_level IN PLS_INTEGER DEFAULT 1) RETURN INTEGER
IS
   lar_stack_data  tar_stack_data;
BEGIN
   bundle_stack_lines(lar_stack_data);
   IF (i_stack_level <= lar_stack_data.COUNT) THEN
      RETURN lar_stack_data(i_stack_level).line_num;
   ELSE
      RETURN NULL;
   END IF;
END line_num_here;

--------------------------------------------------------------------------------
PROCEDURE caller_meta
(
   o_owner       OUT typ.t_maxobjnm,
   o_caller_type OUT user_objects.object_type%TYPE,
   o_unit_nm     OUT user_objects.object_name%TYPE,
   o_routine_nm  OUT app_log.routine_nm%TYPE,
   o_line_num    OUT app_log.line_num%TYPE,
   i_stack_level IN PLS_INTEGER DEFAULT 1
) IS
   lar_stack_data tar_stack_data;
BEGIN
   bundle_stack_lines(lar_stack_data);

   --ins('caller_meta: lar_stack_data.COUNT = '||lar_stack_data.COUNT);
   
   IF (i_stack_level <= lar_stack_data.COUNT) THEN
      o_owner       := lar_stack_data(i_stack_level).owner;
      o_caller_type := lar_stack_data(i_stack_level).obj_type;
      o_unit_nm     := lar_stack_data(i_stack_level).obj_nm;
      -- get underlying procedure/function name if called from package
      IF (UPPER(lar_stack_data(i_stack_level).obj_type) = 'PACKAGE BODY') THEN
         --ins('caller_meta: calling get_routine_nm('''||lar_stack_data(i_stack_level).obj_nm||
         --                                       ''','||lar_stack_data(i_stack_level).line_num||')');
         o_routine_nm := get_routine_nm(lar_stack_data(i_stack_level).obj_nm,
                                        lar_stack_data(i_stack_level).line_num);
      ELSE
         o_routine_nm := lar_stack_data(i_stack_level).obj_nm;
      END IF;
      o_line_num := lar_stack_data(i_stack_level).line_num;
   ELSE
      o_owner       := cnst.unknown_user;
      o_caller_type := NULL;
      o_unit_nm     := cnst.unknown_str;
      o_routine_nm  := cnst.unknown_str;
      o_line_num    := NULL;
   END IF;
END caller_meta;

--------------------------------------------------------------------------------
PROCEDURE tag_session
(
   i_module   IN typ.t_module DEFAULT NULL,
   i_action   IN typ.t_action DEFAULT NULL,
   i_info     IN typ.t_client_info DEFAULT NULL
)
IS
   l_module   typ.t_module := i_module;
   l_action   typ.t_action := i_action;
   l_info     typ.t_client_info := i_info;
BEGIN
   -- I no longer check parameter lengths as that is now governed by the subtypes
   
   IF (l_module IS NULL OR l_action is NULL OR l_info IS NULL) THEN
      DECLARE
         l_unit_nm     typ.t_maxobjnm;
         l_owner       typ.t_maxobjnm;
         l_caller_type user_objects.object_type%TYPE;
         l_routine_nm  app_log.routine_nm%TYPE;
         l_line_num    app_log.line_num%TYPE;
      BEGIN
         env.caller_meta(l_owner, l_caller_type, l_unit_nm, l_routine_nm, l_line_num, 1);
         IF (i_module IS NULL) THEN
            l_module := l_unit_nm;
         END IF;
         IF (i_action IS NULL) THEN
            -- substr to eliminate package name from routine name, dot-notation found
            l_action := SUBSTR(l_routine_nm,INSTR(l_routine_nm,'.')+1);
         END IF;
         IF (i_info IS NULL) THEN
            l_info := l_line_num;
         END IF;
      END;
   END IF;

   push_trace_stack(l_module, l_action, l_info);

   dbms_application_info.set_module(l_module, l_action);
   dbms_application_info.set_client_info(l_info);

END tag_session;

--------------------------------------------------------------------------------
PROCEDURE tag
(
   i_module   IN typ.t_module DEFAULT NULL,
   i_action   IN typ.t_action DEFAULT NULL,
   i_info     IN typ.t_client_info DEFAULT NULL
)
IS
BEGIN   
   tag_session(i_module, i_action, i_info);
END tag;

--------------------------------------------------------------------------------
PROCEDURE untag_session(i_restore_prior_tag IN BOOLEAN DEFAULT TRUE) IS
   l_module   typ.t_module := NULL;
   l_action   typ.t_action := NULL;
   l_info     typ.t_client_info := NULL;
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
PROCEDURE tag_longop(io_longop IN OUT env.t_longop)
IS
BEGIN
   -- TO-DO: Consider getting object_id of DB object possibly named in work_target,
   -- because a NULL or 0 target parameter causes Oracle to fill the target column
   -- of v$session_longops with a big, unrecognizable, unreferenceable number
   dbms_application_info.set_session_longops(rindex      => io_longop.row_key
                                            ,slno        => io_longop.sl_num
                                            ,target      => io_longop.work_target_id
                                            ,target_desc => io_longop.work_target
                                            ,context     => NULL
                                            ,op_name     => io_longop.op_nm
                                            ,totalwork   => io_longop.total_work
                                            ,sofar       => io_longop.work_done
                                            ,units       => io_longop.units_of_measure);
END tag_longop;

--------------------------------------------------------------------------------
PROCEDURE set_ctx_val
(
   i_attr_nm  IN VARCHAR2,
   i_attr_val IN VARCHAR2,
   i_ctx_nm   IN VARCHAR2 DEFAULT FMWK_CTX
)
IS
BEGIN
   --ins('set_ctx_val: i_attr_nm ['||i_attr_nm||'] i_attr_val['||i_attr_val||'] i_ctx_nm ['||I_ctx_nm||']');
   dbms_session.set_context(i_ctx_nm, i_attr_nm, i_attr_val);
END set_ctx_val;

--------------------------------------------------------------------------------
PROCEDURE set_current_schema
(
   i_schema_nm IN VARCHAR2
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
   i_client_os_user IN VARCHAR2 DEFAULT NULL
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
   i_ctx_nm   IN VARCHAR2 DEFAULT FMWK_CTX
)
IS
BEGIN
   dbms_session.clear_context(i_ctx_nm, NULL, i_attr_nm);
END clear_ctx_val;

--------------------------------------------------------------------------------
PROCEDURE clear_ctx
(
   i_ctx_nm   IN VARCHAR2 DEFAULT FMWK_CTX
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
