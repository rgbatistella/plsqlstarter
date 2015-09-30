CREATE OR REPLACE PACKAGE env
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
                       Added tag_longop. See proc comments for explanation.
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

-- Note: all of the fields in this record should be set before the first call to tag_longops 
-- (except optional work_target_id, and row_key/sl_num which the system sets for you).
-- Only need to update work_done and possibly the op_nm/work_target (if long call does multiple things)
-- on subsequent calls to update the progress in v$session_longops
TYPE t_longop IS RECORD (
  total_work     NUMBER DEFAULT 0 -- total units of work you know the process must complete; typically is number of rows to process
 ,work_done      NUMBER DEFAULT 0 -- amount of work done so far
 ,units_of_measure VARCHAR2(32 BYTE) DEFAULT NULL -- units of measure for the values in total_work and work_done; typically 'rows'
 ,op_nm          VARCHAR2(64 BYTE) DEFAULT 'Unknown' -- the routine name, business process being run, etc.
 ,work_target    VARCHAR2(32 BYTE) DEFAULT 'Unknown' -- the name of the current object being worked upon by DDL or DML
 ,work_target_id PLS_INTEGER DEFAULT 0 -- to be useful, could be step ID in the business process
 ,row_key        PLS_INTEGER DEFAULT dbms_application_info.set_session_longops_nohint -- first call should be -1, afterwards holds internal row key
 ,sl_num         PLS_INTEGER -- used internally by Oracle to communicate handles between calls to set_session_longops
);

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------
FMWK_CTX CONSTANT VARCHAR2(20) := LOWER('&&fmwk_home+_ctx');

-- Global in-memory structure to keep track of the trace info used by the tag/untag
-- routines. This is used to reset the trace info back to its previous values when the
-- calling module finishes and returns control to the calling routine.
g_trace_stack tar_trace_info;

-- Global in-memory structure to hold the call stack or error backtrace when
-- required by the error handling parts of the framework.
g_call_stack  typ.t_maxcol;

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
FUNCTION get_client_program RETURN VARCHAR2; -- Not in USERENV. Requires access to [g]v$session.
FUNCTION get_client_module RETURN VARCHAR2; -- Not in USERENV prior to 9i.
FUNCTION get_client_action RETURN VARCHAR2;
FUNCTION get_session_user RETURN VARCHAR2;
FUNCTION get_current_schema RETURN VARCHAR2; -- Could be different from session user if current_schema was altered

FUNCTION get_db_version RETURN NUMBER; -- stand-in for older systems missing DBMS_DB_VERSION
FUNCTION get_db_name RETURN VARCHAR2;
FUNCTION get_db_instance_name RETURN VARCHAR2; -- if RAC db, returns SID/SERVICE NAME otherwise
FUNCTION get_db_instance_id RETURN NUMBER; -- if RAC db, returns 1 otherwise
FUNCTION get_server_host RETURN VARCHAR2; -- name of db host

-- Note: get_sid and get_session_id do the same thing; get_sid is just easier to remember.
FUNCTION get_sid RETURN INTEGER; -- db session ID ([g]v$session.sid)
FUNCTION get_session_id RETURN INTEGER; -- db session ID ([g]v$session.sid)

-- get_os_pid requires acess to [g]v$session and [g]v$process
FUNCTION get_os_pid RETURN INTEGER; -- db host operating system process ID

--FUNCTION get_global_context_memory RETURN VARCHAR2;

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
who_called_me:
 By default, returns the name of the package or standalone one level further up
 in the call stack, which represents the caller of the routine that called this
 function. When called indirectly by another layer in the framework, the stack
 level needs to be increased from the default to find out who the real 
 caller's caller is.

%credit
 Inspiration for this routine name and the code behind it came from Tom Kyte.

%param i_stack_level The depth in the stack to look for caller info.
------------------------------------------------------------------------------*/
FUNCTION who_called_me(i_stack_level IN PLS_INTEGER DEFAULT 2)  RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
who_am_i:
 By default, returns the name of the package or standalone that called this 
 function. When called indirectly by another layer in the framework, the stack
 level needs to be increased from the default to find out who the real caller is.

%credit
 Inspiration for this routine name and the code behind it came from Tom Kyte.

%param i_stack_level The depth in the stack to look for caller info.
------------------------------------------------------------------------------*/
FUNCTION who_am_i(i_stack_level IN PLS_INTEGER DEFAULT 1)  RETURN VARCHAR2;

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
FUNCTION get_routine_nm
(
   i_pkg_nm   IN VARCHAR2,
   i_line_num IN INTEGER
) RETURN VARCHAR2;

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
FUNCTION line_num_here(i_stack_level IN PLS_INTEGER DEFAULT 1) RETURN INTEGER;

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
PROCEDURE caller_meta
(
   o_owner       OUT typ.t_maxobjnm,
   o_caller_type OUT user_objects.object_type%TYPE,
   o_unit_nm     OUT user_objects.object_name%TYPE,
   o_routine_nm  OUT app_log.routine_nm%TYPE,
   o_line_num    OUT app_log.line_num%TYPE,
   i_stack_level IN PLS_INTEGER DEFAULT 1
);

/**-----------------------------------------------------------------------------
tag_session/tag:
 Sets MODULE, ACTION and CLIENT_INFO to the provided values. These values are
 visible in V$SESSION and other performance views. Use this routine frequently 
 to instrument your code and DDL/DML upgrade scripts.
 
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
 
%param i_module The governing "module", usually the change request/ticket#, the
                business process, or PL/SQL package name. If not given, the name
                of the calling package (if any) will be determined transparently.
                Truncated by Oracle to 48 characters.
%param i_action The current "action", usually something like "Create Index",
                "Move Table", etc. The packaged procedure/function name is also a
                frequently-used value. If not given, the name of the calling 
                routine will be determined transparently.
                Truncated by Oracle to 32 characters.
%param i_info The detail of the current step, usually the name of the table,
              index or constraint being created/altered/queried. Could be the
              ID of the business item being processed, or a running count 
              indicating how much work is done and how much there is left to go.
              If not supplied, the line number from which tag_session was 
              called in the calling routine will be used instead.
              Truncated by Oracle to 64 characters.
------------------------------------------------------------------------------*/
PROCEDURE tag_session
(
   i_module   IN typ.t_module DEFAULT NULL,
   i_action   IN typ.t_action DEFAULT NULL,
   i_info     IN typ.t_client_info DEFAULT NULL
);
-- New version that doesn't require caller to pass anything in. Also shorter name.
PROCEDURE tag
(
   i_module   IN typ.t_module DEFAULT NULL,
   i_action   IN typ.t_action DEFAULT NULL,
   i_info     IN typ.t_client_info DEFAULT NULL
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
                           variable, g_trace_stack to see if prior trace data is
                           stored there. If so, it will use these values instead
                           of NULL. This allows modules called by other modules
                           to restore the module/action/info as it was prior to 
                           the current module call and use of tag/tag_session.
------------------------------------------------------------------------------*/
PROCEDURE untag_session(i_restore_prior_tag IN BOOLEAN DEFAULT TRUE);
-- New version that doesn't require caller to pass anything in. Also shorter name.
PROCEDURE untag(i_restore_prior_tag IN BOOLEAN DEFAULT TRUE);

/**-----------------------------------------------------------------------------
tag_longop:
 Call once before beginning long call/operation, which seeds a row in v$session_longops.
 Then call periodically during the operation to update the work_done attribute to communicate,
 in real-time, the progress of the operation. If the operation does multiple things and
 changes the object it is processing, also update the total_work, op_nm and work_target
 to indicate the change in direction and new set of work.
 
%note
 All of the fields in this record should be set before the first call to tag_longops 
(except optional work_target_id, and row_key/sl_num which the system sets for you).

%usage

%param i_longop Record of attributes used by underlying call to dbms_application_info
------------------------------------------------------------------------------*/
PROCEDURE tag_longop(io_longop IN OUT env.t_longop);

/**-----------------------------------------------------------------------------
set_ctx_val:
 You associate this routine with an application-specific context during
 application context creation. Then call this routine when setting the values
 of attributes within the context. If the application context (the Oracle docs
 seem to use "application context" and "context namespace" interchangeably) is
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
   i_ctx_nm   IN VARCHAR2 DEFAULT FMWK_CTX
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
   i_schema_nm IN VARCHAR2
); 

/**-----------------------------------------------------------------------------
init_client_ctx :
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
------------------------------------------------------------------------------*/
PROCEDURE init_client_ctx
(
   i_client_id   IN VARCHAR2,
   i_client_ip   IN VARCHAR2 DEFAULT NULL,
   i_client_host IN VARCHAR2 DEFAULT NULL,
   i_client_os_user IN VARCHAR2 DEFAULT NULL
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
   i_ctx_nm   IN VARCHAR2 DEFAULT FMWK_CTX
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
   i_ctx_nm   IN VARCHAR2 DEFAULT FMWK_CTX
);

END env;
/
