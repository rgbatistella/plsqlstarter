CREATE OR REPLACE PACKAGE env
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Package of routines that get or set information about the user's session and
 execution environment.

%warn
 I worry that wrapping calls to SYS_CONTEXT will bypass Oracle optimizations
 for SYS_CONTEXT, optimizations that allow SYS_CONTEXT to sail past the usual
 limitations of calling PL/SQL functions from within SQL statements. I did a
 brief test on a table with 500K rows. The cost reported by the CBO was greater,
 but the response time was about the same. If you discover that calling these
 wrapped versions of SYS_CONTEXT calls is slower, by all means, use the direct
 calls to SYS_CONTEXT instead.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008Jan20 Added a few more functions.
bcoulam      2008May19 Added context functions, caller_meta, get_routine_nm,
                       line_num_here, and fixed private bundle_stack_lines to
                       work with both 10g and 9i call stacks. Eliminated
                       redundant get_app_id and get_app_cd functions. Renamed
                       get_current_user to get_current_schema (the current_user
                       USERENV attribute is deprecated as of 10g). Simplified
                       get_env_nm. Also added set and clear context routines.
bcoulam      2008Aug18 Added vld_path_format to ensure directory paths end in a
                       slash.
bcoulam      2012Jan24 Added set_current_schema. See proc comments for explanation.
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
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------
-- basic trace structure type
-- datatype of fields is hard-coded due to one user's environment where access
-- to v$session was not allowed.
TYPE trace_info IS RECORD (
 module typ.t_module,
 action typ.t_action,
 client_info typ.t_client_id
);
-- trace stack datatype
TYPE tar_trace_info IS TABLE OF trace_info INDEX BY PLS_INTEGER;

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------
DOMAIN CONSTANT VARCHAR2(30) := '&&mydomain';
APP_CORE_CTX CONSTANT VARCHAR2(20) := 'app_core_ctx';

-- Global in-memory structure to keep track of the trace info used by the tag/untag
-- routines. This is used to reset the trace info back to its previous values when the
-- calling module finishes and returns control to the calling routine.
g_trace_stack tar_trace_info;

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
Simple wrappers around SYS_CONTEXT functions and environment metadata readily
available in the data dictionary.
------------------------------------------------------------------------------*/
FUNCTION get_client_id RETURN VARCHAR2;
FUNCTION get_client_ip RETURN VARCHAR2;
FUNCTION get_client_host RETURN VARCHAR2;
FUNCTION get_client_os_user RETURN VARCHAR2;
-- Following conditional compilation eliminates get_client_program if v$session
-- is not available.
$IF $$vsession_avail $THEN
FUNCTION get_client_program RETURN VARCHAR2; -- derived from [g]v$session. Not in USERENV
$END
FUNCTION get_client_module RETURN VARCHAR2;
FUNCTION get_client_action RETURN VARCHAR2;
FUNCTION get_session_user RETURN VARCHAR2;
FUNCTION get_current_schema RETURN VARCHAR2; -- could be different from session user if current_schema was altered

FUNCTION get_db_version RETURN NUMBER; -- stand-in for older systems missing DBMS_DB_VERSION
FUNCTION get_db_name RETURN VARCHAR2;
FUNCTION get_db_instance_name RETURN VARCHAR2; -- if RAC db, returns SID/SERVICE NAME otherwise
FUNCTION get_db_instance_id RETURN NUMBER; -- if RAC db, returns 1 otherwise
FUNCTION get_server_host RETURN VARCHAR2; -- name of db host

-- Note: get_sid and get_session_id do the same thing; get_sid is just easier to remember.
FUNCTION get_sid RETURN INTEGER; -- db session ID ([g]v$session.sid)
FUNCTION get_session_id RETURN INTEGER; -- db session ID ([g]v$session.sid)
-- Following conditional compilation eliminates get_os_pid if v$session
-- is not available. v$process is the main requirement, but since the ADDR
-- from v$session is the only way to join to v$process, the whole routine
-- would not work without v$session.
$IF $$vsession_avail $THEN
FUNCTION get_os_pid RETURN INTEGER; -- db host operating system process ID
$END
--FUNCTION get_global_context_memory RETURN VARCHAR2;
FUNCTION get_schema_email_address RETURN VARCHAR2; --fake email address db.schema@host

/**-----------------------------------------------------------------------------
get_db_id:
 Uses the db_name returned by sys_context to query APP_DB and return a numeric
 ID for the current database.
------------------------------------------------------------------------------*/
FUNCTION get_db_id RETURN INTEGER;

/**-----------------------------------------------------------------------------
get_db_alias
 Given a database identifier, will return the database alias. If the identifier
 is not given, will return the alias for the local database.
------------------------------------------------------------------------------*/
FUNCTION get_db_alias(i_db IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_app_id:
 If the app_cd is given, returns the app_id from the APP table.

 If the app_cd is missing, will return app_id from the in-memory record private
 to ENV. If this has not been filled yet, it will attempt to determine the
 application transparently using values from the USERENV context and the DB Name,
 matching up to data in APP, APP_DB and APP_ENV. In environments where multiple
 applications share the same owning schema, they must set the app_cd into the
 default env.APP_CORE_CTX context at the time of connection. They can do this by
 ensuring they call env.init_client_ctx and passing in the app_cd at the start of
 their session. Or they can do this by calling env.set_ctx_val directly.

 If the app_cd cannot be determined, an error is raised.

%param i_app_cd  Name of the application, as stored in table APP.
------------------------------------------------------------------------------*/
FUNCTION get_app_id (i_app_cd IN app.app_cd%TYPE DEFAULT NULL) RETURN NUMBER;

/**-----------------------------------------------------------------------------
get_app_cd:
 If the app_id is given, returns the app code from the APP table.

 If the app_id is missing, will transparently attempt to get the app_id using
 get_app_id().

 If the app_cd cannot be determined, will return NULL.

%param i_app_id ID of the application, as stored in table APP.
------------------------------------------------------------------------------*/
FUNCTION get_app_cd(i_app_id IN app.app_id%TYPE DEFAULT NULL) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_env_nm:
 Queries APP_ENV to determine the name of the current environment, given the
 current schema, database name and application.

%param i_app_cd Optional application code.
------------------------------------------------------------------------------*/
FUNCTION get_env_nm(i_app_cd IN app.app_cd%TYPE DEFAULT NULL) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_env_nm:
 Queries APP_ENV to determine the name of the current environment, given the
 current schema, database name and application.

%param i_app_id Optional application id.
------------------------------------------------------------------------------*/
FUNCTION get_env_nm(i_app_id IN app.app_id%TYPE) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_env_id:
 Queries APP_ENV to determine the id of the current environment, given the
 current schema, database name and application.

%param i_app_cd Optional application code.
------------------------------------------------------------------------------*/
FUNCTION get_env_id(i_app_cd IN app.app_cd%TYPE DEFAULT NULL) RETURN INTEGER;

/**-----------------------------------------------------------------------------
get_env_id:
 Queries APP_ENV to determine the id of the current environment, given the
 current schema, database name and application.

%param i_app_id Optional application code.
------------------------------------------------------------------------------*/
FUNCTION get_env_id(i_app_id IN app.app_id%TYPE) RETURN INTEGER;

/**-----------------------------------------------------------------------------
get_dir_path:
 Queries all_directories to find the directory path behind a given 9i-style
 directory name.
------------------------------------------------------------------------------*/
FUNCTION get_dir_path(i_dir_nm IN VARCHAR2) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
vld_path_format:
 Ensures that there is a directory slash character after a given path. If the
 given path does not end in a slash, one will be appended. This is useful for
 routines that piece together full paths, where the content and validity of the
 path piece is uncertain. When Oracle directory objects are created, they may or
 may not have the trailing slash.
------------------------------------------------------------------------------*/
FUNCTION vld_path_format (i_path IN VARCHAR2) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_caller_nm:
 By default, returns the name of the package or standalone one level further up
 in the call stack, which represents the caller of the routine that called this
 function. When called indirectly by another layer in the framework, the stack
 level needs to be increased from the default to find out who the real
 caller's caller is.

%credit
 Inspiration for this routine and the code behind it came from Tom Kyte.

%param i_stack_level The depth in the stack to look for caller info.
------------------------------------------------------------------------------*/
FUNCTION get_caller_nm(i_stack_level IN PLS_INTEGER DEFAULT 3) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_caller_line:
 Returns the line from which the call was made. If called from within other
 framework routines, may need to increase the stack level.

%param i_stack_level The depth in the stack to look for caller info.
------------------------------------------------------------------------------*/
FUNCTION get_caller_line(i_stack_level IN PLS_INTEGER DEFAULT 3) RETURN INTEGER;

/**-----------------------------------------------------------------------------
get_routine_nm:
 Given a package name and line number, returns the name of the routine within
 which that line number currently falls. The ability of a subroutine to
 introspect and find its own name is a basic ability of most programming and
 scripting languages, but not PL/SQL. Hence the reason for this routine.

 By parsing the call stack (available in most versions of Oracle) or using the
 new $$PLSQL_UNIT and $$PLSQL_LINE directives, we can get at the package and
 line. Either of these methods can produce the inputs required for this
 function.

%note
 This was originally a private function, meant to be used exclusively by the
 caller_meta() routine. However, since it could be useful in other contexts, it
 was exposed. The logging library indirectly uses this routine heavily so that
 the callers of the logging routines do not have to pass in their location, name
 or containing package explicitly. If you only desire to use this function for
 logging purposes, use the LOGS package instead, and inherit this ability by
 default.

%caveat
 If you still need to call this function, know that it is only useful for
 _packaged_ routines.

 The accuracy of this function depends on the code following one simple
 convention, which is:

    Always immediately follow the PROCEDURE and FUNCTION declaration with its name.

    Example: CREATE OR REPLACE PACKAGE test AS
             ...
             PROCEDURE first_proc( <-- fine
                ...
             );
             FUNCTION get_val... <-- fine
             PROCEDURE -- inline comment about this proc
                second_proc; <-- will not work with env.get_routine_nm()
             END test;

 If you allow the routine name to go on a line separate from its declaration,
 this function will not work and return NULL.

%design
 Two designs were tested, one where the metadata for each package was stored
 in a table and maintained by trigger (nature of DDL in AFTER ALTER triggers
 requires that the trigger submit jobs to update the table), and one where the
 metadata is gathered at the time of request. Running a test of 1700 random
 line numbers within a schema with 140 packages, the persistent table version
 returned accurate routine names in 1.3 seconds for 1700 total calls, whereas
 the dynamic version got the same results in 2.8 seconds. Since get_routine_nm
 wouldn't be called that heavily within most production environments, I decided
 to eliminate the overhead of the extra moving parts and stick with the dynamic
 version instead. That is why this routine just uses one complex SQL statement,
 instead of a static table or materialized result set.

%param i_pkg_nm  Name of the package in which to find the routine name by line
                 number.
%param i_line_num  The line number which the caller is claiming as the location
                   of the introspection request.
------------------------------------------------------------------------------*/
--FUNCTION get_routine_nm
--(
--   i_pkg_nm   IN VARCHAR2,
--   i_line_num IN INTEGER
--) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_my_nm
 By default, returns the name of the package or standalone that called this
 function. When called indirectly by another layer in the framework, the stack
 level needs to be increased from the default to find out who the real caller is.

%credit
 Inspiration for this routine and the code behind it came from Tom Kyte.
 Updated for 12c to use UTL_CALL_STACK.

%param i_stack_level The depth in the stack to look for caller info.
------------------------------------------------------------------------------*/
FUNCTION get_my_nm(i_stack_level IN PLS_INTEGER DEFAULT 2) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_my_line
 Wrapper function to get the caller's current line number. When called
 indirectly by another layer in the framework, the stack level needs to be
 increased from the default to find out

%param i_stack_level The depth in the stack to look for caller info.
------------------------------------------------------------------------------*/
FUNCTION get_my_line(i_stack_level IN PLS_INTEGER DEFAULT 2) RETURN INTEGER;

/**-----------------------------------------------------------------------------
line_num_here:
 Looks in the call stack to the given depth and returns the line number from
 which line_num_here was called.

%note
 This is not necessary from 9.2.0.6 onwards where you can use $$PLSQL_LINE to
 get the same result. However, in 9.2.0.6, you have to set the
 _plsql_conditional_compilation flag to TRUE in order to use it.

%usage
 <code>
   -- When you want to record a line number other than the line at which the
   -- LOGS routine is called. This is analagous to the old method of setting
   -- a "marker" variable before each chunk of code, which would get recorded
   -- with any error/info logging for context and later research:

   --l_line := $$PLSQL_LINE; -- implemenation for >= 9.2.0.6
   l_line := env.line_num_here; -- implementation for <= 9.2.0.5
   mypkg.do_something_useful(i_date, l_length);
   logs.dbg(i_msg=>'Did something useful', i_line_num => l_line);

   -- When you are OK with recording the line number as the line from which the
   -- call to logs was made, use this simpler method instead:

   -- >= 9.2.0.6
   logs.info('Awaiting pipe message', 'DBMS_PIPE Listener', $$PLSQL_LINE);
   -- <= 9.2.0.5
   logs.info('Awaiting pipe message', 'DBMS_PIPE Listener', env.line_num_here);

   -- Remember that the LOGS routines transparently determine routine name and
   -- line number for you. So unless you want to use a custom name, like
   -- DBMS_PIPE Listener in the examples above, don't worry about line number,
   -- for example:
   logs.info('Awaiting pipe message');

------------------------------------------------------------------------------*/
--FUNCTION line_num_here(i_stack_level IN PLS_INTEGER DEFAULT 1) RETURN INTEGER;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
caller_meta:
 Returns all the metadata about the caller at the given level in the call stack.
 It is anticipated that the only consumer of this proc will be the LOGS library
 routines (msg, err, warn, info and dbg).
 The caller data includes the fully qualified routine name, which is the name of
 the type body, function, proc, trigger or package.routine_name. If the caller
 is an anonymous block, the name will be ANONYMOUSBLOCK.

%param o_owner  The schema name of the owner of the caller DB object.
%param o_caller_type  The PL/SQL unit type, including ANONYMOUS BLOCK
%param o_unit_nm  The PL/SQL unit name. For packages, this is limited to the package
                  name.
%param o_routine_nm  For packages, this is the the full name of the calling object.
                     Will be package.routine_nm for packaged routines.
%param o_line_num  The line number in the call stack from which the call was made.
%param i_stack_level  How deep to look in the stack for for the callers metadata.
                      Defaults to 1 level deep (immediate caller). The framework
                      components must use stack level 2 to get one layer above
                      where they sit in the call stack.
------------------------------------------------------------------------------*/
--PROCEDURE caller_meta
--(
--   o_owner       OUT typ.t_maxobjnm,
--   o_caller_type OUT user_objects.object_type%TYPE,
--   o_unit_nm     OUT user_objects.object_name%TYPE,
--   o_routine_nm  OUT app_log.routine_nm%TYPE,
--   o_line_num    OUT app_log.line_num%TYPE,
--   i_stack_level IN PLS_INTEGER DEFAULT 1
--);

/**-----------------------------------------------------------------------------
tag_session/tag:
 Sets MODULE, ACTION and CLIENT_INFO in v$session to the provided values. Use
 this routine frequently to instrument your code and DDL/DML upgrade scripts.

 Since this places custom tags in v$session, it gives DBAs more visibility into
 the systems they manage, and a better ability to measure, tune, find and track.

 Remember to clear these values out using env.untag_session, or else the values
 will remain for the duration of the session, possibly causing those
 investigating issues to pursue the wrong path.

%usage
 <code>
   exec env.tag_session('CR53885','Re-create Constraint','CONTACTS_UK');

   ALTER TABLE contacts
   DROP CONSTRAINT contacts_uk
   ...
   ALTER TABLE contacts
   ADD CONSTRAINT contacts_uk
   ...
   exec ddl_utils.analyze_index('CONTACTS_UK');
   exec env.untag_session;
 </code>

%param i_module The governing "module", usually the change request/ticket#.
                The PL/SQL package name is also a frequently-used value.
                If not given, the name of the calling package (if any) will be
                determined transparently.
                Limited to 48 characters.
%param i_action The current "action", usually something like "Create Index",
                "Move Table", etc. The packaged procedure/function name is also a
                frequently-used value. If not given, the name of the calling
                routine will be determined transparently.
                Limited to 32 characters.
%param i_info The detail of the current step, usually the name of the table,
              index or constraint being created/altered/queried. If not supplied,
              the line number from which tag_session was called in the calling
              routine will be used instead.
              Limited to 64 characters.
------------------------------------------------------------------------------*/
PROCEDURE tag_session
(
   i_module   IN VARCHAR2,
   i_action   IN VARCHAR2,
   i_info     IN VARCHAR2
);
-- New version that doesn't require caller to pass anything in. Also shorter name.
PROCEDURE tag
(
   i_module   IN VARCHAR2 DEFAULT NULL,
   i_action   IN VARCHAR2 DEFAULT NULL,
   i_info     IN VARCHAR2 DEFAULT NULL
);


/**-----------------------------------------------------------------------------
untag_session/untag:
 Sets MODULE, ACTION and CLIENT_INFO in v$session to NULL.

%note
 Make sure to call this after calling tag_session(). Otherwise the info fed to
 tag_session will remain attached to your session, fooling administrators into
 thinking your session is still working on the module indicated in v$session,
 when in fact your session has ended or moved on to other actions.

%param i_restore_prior_tag If TRUE (the default), will attempt to read the global
                           variable, gv_trace_info to see if prior trace data is
                           stored there. If so, it will use these values instead
                           of NULL. This allows modules called by other modules
                           to restore the module/action/info as it was prior to
                           the current module call and use of tag/tag_session.
------------------------------------------------------------------------------*/
PROCEDURE untag_session(i_restore_prior_tag IN BOOLEAN DEFAULT TRUE);
-- New version that doesn't require caller to pass anything in. Also shorter name.
PROCEDURE untag(i_restore_prior_tag IN BOOLEAN DEFAULT TRUE);

/**-----------------------------------------------------------------------------
set_ctx_val:
 You associate this routine with an application-specific context during
 application context creation. Then call this routine when setting the values
 of attributes within the context. If the application context (the Oracle docs
 seem to use "application context" and context namespace interchangeably) is
 not named, the default namespace for the Core framework will be used.

%note
 The Core framework uses this routine to maintain the value of the in-memory
 debug flag parameter.

%usage
 <code>
    CREATE CONTEXT my_ctx USING env.set_ctx_val;
    exec env.set_ctx_val('remote_login_attempts','5','my_ctx');
    -- followed by calls to PL/SQL stored objects that include controls on
    -- remote login attempts by querying the in-memory context value using
    -- SYS_CONTEXT('my_ctx','remote_login_attempts')
 </code>

%param i_attr_nm  Name of the attribute whose value will be set in the context
                  for the current session.
%param i_attr_val  Value of the attribute within the application context.
%param i_ctx_nm  Name of the application context. Defaults to framework's context.
------------------------------------------------------------------------------*/
PROCEDURE set_ctx_val
(
   i_attr_nm  IN VARCHAR2,
   i_attr_val IN VARCHAR2,
   i_ctx_nm   IN VARCHAR2 DEFAULT APP_CORE_CTX
);

/**-----------------------------------------------------------------------------
set_app_cd:
 Takes a short code for a given application (found listed in the APP table),
 and sets it as the value for the "app_cd" attribute in the Core application
 context.

 This routine is meant to be called by jobs, or DBAs manually running routines
 by anonymous block. In these situations the client or user ID might not be
 readily known or relevant, and only the app_cd is needed to activate the
 framework's dynamic views. This could be called at the top of the "what" block
 in the job. A great place for the call is within the initialization section of
 a package. If you are designing a system that resides in its own dedicated
 schema, this routine need only be called once from an AFTER LOGON trigger. But
 if you have the unfortunate luck of working in a schema that serves multiple
 applications, this routine will need to be called explicitly by the packages
 and jobs dedicated to a given system.

%param i_app_cd Application code as found in APP.APP_CD
------------------------------------------------------------------------------*/
PROCEDURE set_app_cd
(
   i_app_cd IN app.app_cd%TYPE
);

/**-----------------------------------------------------------------------------
set_current_schema:
 Takes an Oracle account/schema name, and places it in the session's client
 context memory structure for later use when read by get_current_schema.

 For most systems where the application resides in one schema, and calls upon
 services in the framework in the same or another schema, this routine is not
 necessary as the framework will determine the current schema being used for
 execution dynamically. I call this a two layer use of the framework.

 However, for systems where schema A calls upon a definer-rights stored
 routine in schema B, or a view or trigger in schema B (neither of which can
 use invoker-rights), which make use of the framework, any attempt to get the
 application's current schema will return schema B, not schema A as it should.
 I call this a three or N-layer use of the framework, which it really wasn't
 designed for.

 So this routine was added to allow a session to statically place its object-
 owning or DB access account name (see app_env.owner_account and access_account
 columns and how they help map applications and databases to named environments)
 into memory where it can be retrieved by the framework calls within schema B.
 This call would ideally be done within an AFTER LOGON trigger in the schema to
 which the application server connects.

%param i_schema_nm Valid Oracle account name. Will be uppercased before being
                   stored. So ensure it matches a valid account value in
                   APP_ENV.
------------------------------------------------------------------------------*/
PROCEDURE set_current_schema
(
   i_schema_nm IN app_env.access_account%TYPE
);

/**-----------------------------------------------------------------------------
init_client_ctx:
 Takes a user identifier from the caller (usually the presentation layer that
 served up the login screen to the user), and places it in the session's
 client_identifier USERENV application context area. This can be used by
 standard Oracle auditing, or FGA, or custom trigger-based auditing, to report
 who (within the application's users sharing the connection pool) did what, and
 when.

%param i_client_id User's login ID, be it employee ID, name, LDAP DN, whatever
                   can identify the end user. If this is an automated process,
                   assign it a name and use that name consistently here and when
                   logging.

%param i_client_ip Optional IP address. If using connection pools and shared schemas,
                   this will default to the address of the application server,
                   unless you pass it the user's IP address explicitly.

%param i_client_host Optional name of the machine or terminal from the which the
                     user is logging in to use the application. Again, for
                     applications using connection pools, this will default to
                     the application server's host name unless the front end
                     passes the client machine name explicitly.

%param i_client_os_user Optional operating system login ID. This is more useful
                        when the user is connected directly to the database,
                        or for automated processes. But if the front end layer
                        has this information, they should feel free to pass it in.

%param i_app_cd An application code from APP.APP_CD. Mandatory if this is an
                environment where multiple applications share a single schema.
------------------------------------------------------------------------------*/
PROCEDURE init_client_ctx
(
   i_client_id   IN VARCHAR2,
   i_client_ip   IN VARCHAR2 DEFAULT NULL,
   i_client_host IN VARCHAR2 DEFAULT NULL,
   i_client_os_user IN VARCHAR2 DEFAULT NULL,
   i_app_cd      IN VARCHAR2 DEFAULT NULL
);

/**-----------------------------------------------------------------------------
reset_client_ctx:
 Must be called by the front-end layer controlling transactions and access to the
 connection pool. This empties the client context and resets package state, so that
 the next user who inherits these in-memory objects doesn't also inherit the same
 values.

%warn
 This routine re-initializes several things, including the session state that
 held the dbms_output buffer. So make sure you are pulling relevant text out of the
 buffer (if you are using dbms_output.get_line(s)) before you call reset_client_ctx.
------------------------------------------------------------------------------*/
PROCEDURE reset_client_ctx;

/**-----------------------------------------------------------------------------
clear_ctx_val:
 This routine will set the value of the attribute within the given namespace to
 NULL.

%usage
 Call this routine when the value of an in-memory application context attribute
 is no longer needed. This prevents the value from being inherited by other
 connections or sessions (I lose track of which is which).

%param i_attr_nm  Name of the attribute whose value will be set to NULL.
%param i_ctx_nm Name of the application context. Defaults to framework's context.
------------------------------------------------------------------------------*/
PROCEDURE clear_ctx_val
(
   i_attr_nm  IN VARCHAR2,
   i_ctx_nm   IN VARCHAR2 DEFAULT APP_CORE_CTX
);

/**-----------------------------------------------------------------------------
clear_ctx:
 This routine will set the value of all attributes within the given namespace to
 NULL.

%usage
 Call this routine when a session is over and the connection is about to be
 returned to the pool. This prevents the values in the namespace from being
 inherited by other connections or sessions (I lose track of which is which).

%param i_ctx_nm Name of the application context. Defaults to framework's context.
------------------------------------------------------------------------------*/
PROCEDURE clear_ctx
(
   i_ctx_nm   IN VARCHAR2 DEFAULT APP_CORE_CTX
);

END env;
/
