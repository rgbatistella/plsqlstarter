CREATE OR REPLACE PACKAGE BODY logs
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008Feb08 Refactored heavily from the msg package.
bcoulam      2008May15 Added line number as an optional parameter to most logging
                       routines.
bcoulam      2008May20 Added fine-grained filters to debug mode, so debug logs
                       only get written for certain packages, session or user.                       

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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'logs';

-- Needed to retain caller's output preferences across multiple calls to msg
g_to_file BOOLEAN;
g_to_table BOOLEAN;
g_to_screen BOOLEAN;

-- Needed for any logging to a file, defaults if user doesn't supply
g_file_dir VARCHAR2(500);
g_file_nm VARCHAR2(255);
g_debug_check_interval INTEGER;

-- Private type used to dynamically controlling debugging
TYPE tr_debug IS RECORD (
   debugging_on BOOLEAN,
   session_override BOOLEAN,
   dbg_check_interval INTEGER, -- in terms of minutes
   last_checked_dtm DATE,
   debug_type VARCHAR2(20),
   debug_trig VARCHAR2(4000)
);
gr_debug tr_debug;

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
format_log_txt:
 Format the given message and metadata into a standard format for logging,
 making data mining of the logs easier.
------------------------------------------------------------------------------*/
FUNCTION format_log_txt
(
   i_msg IN VARCHAR2
,  i_msg_cd IN VARCHAR2 DEFAULT msgs.DEFAULT_MSG_CD
,  i_sev_cd IN VARCHAR2 DEFAULT cnst.INFO
,  i_routine_nm IN VARCHAR2 DEFAULT NULL
,  i_line_num IN VARCHAR2 DEFAULT NULL
)
  RETURN VARCHAR2
IS
   l_log_dtm DATE := dt.get_sysdtm;
BEGIN
   RETURN SUBSTR(
      TO_CHAR(l_log_dtm,'YYYY/MM/DD')||cnst.PIPECHAR||
      TO_CHAR(l_log_dtm,'HH24:MI:SS')||cnst.PIPECHAR||
      env.get_db_name||cnst.PIPECHAR||
      env.get_sid||cnst.PIPECHAR||
      env.get_app_cd||cnst.PIPECHAR||
      env.get_client_id||cnst.PIPECHAR||
      NVL(i_routine_nm, cnst.UNKNOWN_STR)||cnst.PIPECHAR|| -- calling package.routine, trigger, type body, etc.
      NVL(TO_CHAR(i_line_num), '-')||cnst.PIPECHAR||
      i_sev_cd||cnst.PIPECHAR||
      i_msg_cd||cnst.PIPECHAR|| 
      NVL(i_msg,'Message missing. Figure out why!')   
   ,1, cnst.max_vc2_len -- UTL_FILE limited to 32K
   );
END format_log_txt;

/**-----------------------------------------------------------------------------
format_tbl_txt:
 Supposedly formats the given message for table insertion, but this was 
 simplified to just fill with a message if the given message is empty, since 
 the identifying fields -- crucial in format_log_txt -- are handled as separate 
 columns in APP_LOG.
 
 This routine also ensures the text going into APP_LOG is short enough for the
 column.
------------------------------------------------------------------------------*/
FUNCTION format_tbl_txt(i_msg IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
   RETURN SUBSTR(NVL(i_msg, 'Message missing. Figure out why!'),
                 1,
                 cnst.MAX_COL_LEN);
END format_tbl_txt;

/**-----------------------------------------------------------------------------
vld_format_debug_val:
 Validates, simplifies and formats the Debug parameter value.
 Called by set_dbg and check_debug_toggle to ensure a) the caller used the
 right syntax in the value they gave for the debug filter, and b) the validated
 debug parameter value is formatted properly to aid in its processing (package
 names uppercased, strings trimmed, etc.)
------------------------------------------------------------------------------*/
PROCEDURE vld_debug_toggle_format(i_parm_val IN app_env_parm.parm_val%TYPE)
IS
   l_parm_val app_env_parm.parm_val%TYPE := LOWER(TRIM(i_parm_val));
BEGIN
   -- Ensure the call to parms.get_parm_val actually pulled back a value
   excp.assert(i_expr => i_parm_val IS NOT NULL,
               i_msg => 'i_parm_val is empty. Cannot validate the format of an empty parameter.'); 

   -- Value must first pass syntax check. I do not try to ensure session ID,
   -- package names, or client ID are valid and known to the database. The
   -- expert developer doing the debugging just needs to type accurately.
   excp.assert(i_expr => (l_parm_val IN ('all','none','off','on','true','false','y','n','yes','no') OR
                          l_parm_val LIKE 'session=%' OR
                          l_parm_val LIKE 'unit=%' OR
                          l_parm_val LIKE 'user=%'),
               i_msg => DEBUG_PARM_NM||' value invalid. Must follow this syntax: '||
               'off|all|session=<session_id>|unit=<pkg1[,pkg2...]>|user=<client_id>');

   -- If validation passed, now we format and pull apart the value to find out what
   -- the caller wanted us to debug.
   IF (l_parm_val LIKE 'unit=%' OR l_parm_val LIKE 'user=%' OR l_parm_val LIKE 'session=%') THEN
      gr_debug.debugging_on := TRUE;
      gr_debug.debug_type := SUBSTR(l_parm_val,1,INSTR(l_parm_val,'=')-1);
      
      IF (l_parm_val LIKE 'user=%') THEN
         -- Leave client ID untouched, as character case may matter
         -- with regard to unique user identifiers.
         gr_debug.debug_trig := TRIM(SUBSTR(TRIM(i_parm_val),INSTR(TRIM(i_parm_val),'=')+1));

      ELSIF (l_parm_val LIKE 'unit=%') THEN
         gr_debug.debug_trig := TRIM(UPPER(SUBSTR(l_parm_val,INSTR(l_parm_val,'=')+1)));

      ELSIF (l_parm_val LIKE 'session=%') THEN
         gr_debug.debug_trig := SUBSTR(l_parm_val,INSTR(l_parm_val,'=')+1);

         excp.assert(i_expr => num.ianb(gr_debug.debug_trig),
                     i_msg => DEBUG_PARM_NM||' value invalid. Session ID ['||
                              gr_debug.debug_trig||'] must be numeric.');
      END IF;
                    
   ELSE
      -- reduce flexible toggle values to single value
      IF (l_parm_val IN ('all','on','true','y','yes')) THEN
         gr_debug.debugging_on := TRUE;
         gr_debug.debug_type := 'all';
         gr_debug.debug_trig := NULL;
      ELSIF (l_parm_val IN ('off','none','false','n','no')) THEN
         gr_debug.debugging_on := FALSE;
         gr_debug.debug_type := 'off';
         gr_debug.debug_trig := NULL;
      END IF;
   END IF;
END vld_debug_toggle_format;

/**-----------------------------------------------------------------------------
check_debug_toggle:
 Called by dbg() only if N minutes have passed. This interval is controlled by
 the "Debug Toggle Check Interval" in APP_PARM_VW). When called, it updates the 
 timestamp stored in the global debug structure, then reads the current debug 
 toggle value for the application in APP_PARM_VW.
 
 If a caller has called set_dbg directly from a session, then debug is turned 
 on, period; this function will therefore not bother to read APP_PARM_VW since a
 manual call is overriding the dynamic debugging feature.
------------------------------------------------------------------------------*/
PROCEDURE check_debug_toggle
IS
BEGIN
   gr_debug.last_checked_dtm := dt.get_sysdtm; --update timestamp no matter what
   
   -- Only read the table if debugging isn't being overidden by a manual
   -- call through set_dbg.
   IF (NOT gr_debug.session_override) THEN
      --If the parameter couldn't be found assume debugging is off.
      vld_debug_toggle_format(NVL(parm.get_val(DEBUG_PARM_NM),'Off'));

   END IF;
      
END check_debug_toggle;

--------------------------------------------------------------------------------
PROCEDURE get_targets_for_env
(
   o_to_screen OUT BOOLEAN,
   o_to_table  OUT BOOLEAN,
   o_to_file   OUT BOOLEAN
) IS
   l_str app_env_parm.parm_val%TYPE;
   l_str_targets str_tt;
   l_target_nm VARCHAR2(10); -- left-hand side of the tag/value pair
   PROCEDURE get_target_bool(i_str_target IN VARCHAR2, io_target IN OUT BOOLEAN)
   IS
      l_target_val VARCHAR2(10);
   BEGIN
      l_target_val := SUBSTR(i_str_target,INSTR(i_str_target,'=')+1);
      IF (LOWER(l_target_val) IN ('y','yes','on','true','1')) THEN
         io_target := TRUE;
      ELSE
         io_target := FALSE;
      END IF;
   END get_target_bool;
BEGIN
   -- lowercase the whole thing to make matching easier
   l_str := parm.get_val('Default Log Targets');
   IF (l_str IS NOT NULL) THEN
      -- break the parameter value into its components by the delimiter
      l_str_targets := str.parse_list(l_str);
         
      FOR i IN l_str_targets.FIRST..l_str_targets.LAST LOOP
         l_target_nm := TRIM(SUBSTR(l_str_targets(i),1,INSTR(l_str_targets(i),'=')-1));
            
         IF (l_target_nm = TARGET_SCREEN) THEN
            get_target_bool(l_str_targets(i), o_to_screen);
         ELSIF (l_target_nm = TARGET_TABLE) THEN
            get_target_bool(l_str_targets(i), o_to_table);
         ELSIF (l_target_nm = TARGET_FILE) THEN
            get_target_bool(l_str_targets(i), o_to_file);
         END IF;
      END LOOP;
   ELSE
      -- couldn't find the parameter for the given environment, so default to 
      -- table logging only, which should succeed if APP_LOG is created.
      o_to_screen := FALSE;
      o_to_table := TRUE;
      o_to_file := FALSE;
   END IF;
END get_targets_for_env;

/**-----------------------------------------------------------------------------
to_file:
 The to_file routine is mainly used by the logs.msg routine if File is one of the 
 log targets. However, this public interface is provided to allow the programmer 
 to override the current session's target. There may be a need, for example, to 
 have most output going to the application's log table, but occassionally need to 
 send a line or two to a special file. This allows the programmer to avoid 
 having to set/reset the target more than once for the transaction/session.

 If to_file is called, the programmer should supply a filename. The directory
 will be supplied with a default unless you override it.

%param i_msg The message to be logged to a file. Must be less than 32K characters.

%param i_msg_cd Optional message code. If you supply the message code, but no
                message, the message will be pulled from APP_MSG and logged.

%param i_sev_cd Optional message type. Will default to INFO unless explicitly
                designated as ERROR, WARN or DEBUG (%see C package).

%param i_routine_nm Optional message source. Usually the package.routine where
                    the message came from. Could be the name of a trigger,
                    object method, type body, etc.

%param i_file_nm The name of the file if you wish the logging to go to a file
                 other than the default (%see io.get_default_filename)

%param i_file_dir The name of the directory. Only required if you pass i_file_nm
                  and wish the file to be written to a directory other than the
                  default (%see io.get_default_dir).

------------------------------------------------------------------------------*/
PROCEDURE to_file
(
   i_msg        IN VARCHAR2 DEFAULT NULL, -- must be <= 32K
   i_msg_cd     IN app_log.msg_cd%TYPE DEFAULT msgs.DEFAULT_MSG_CD,
   i_sev_cd     IN app_log.sev_cd%TYPE DEFAULT cnst.info,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL,
   i_file_nm    IN VARCHAR2 DEFAULT io.get_default_filename,
   i_file_dir   IN VARCHAR2 DEFAULT io.get_default_dir
) IS
BEGIN
   io.write_line(format_log_txt(i_msg, i_msg_cd, i_sev_cd, i_routine_nm, i_line_num),
                  NVL(i_file_nm, g_file_nm),
                  NVL(i_file_dir, g_file_dir));
END to_file;

/**-----------------------------------------------------------------------------
to_table:
 The to_table routine is mainly used by the logs.msg routine if Table is one of 
 the log targets. However, this public interface is provided to allow the 
 programmer to override the current session's target. There may be a need, for 
 example, to have most output going to the application's log file, but 
 occassionally need to send a line or two to the APP_LOG table. This allows the 
 programmer to avoid having to set/reset the target more than once for the 
 transaction/session.

 By default, when to_table is called the message will be inserted into the
 app_log table.

%param i_msg The message to be logged to a file. Must be less than 4K characters.

%param i_msg_cd Optional message code. If you supply the message code, but no
                message, the message will be pulled from APP_MSG and logged.

%param i_sev_cd Optional message type. Will default to INFO unless explicitly
                designated as ERROR, WARN or DEBUG (%see C package).

%param i_routine_nm Optional message source. Usually the package.routine where
                    the message came from. Could be the name of a trigger,
                    object method, type body, etc.
------------------------------------------------------------------------------*/
PROCEDURE to_table
(
   i_log_txt    IN app_log.log_txt%TYPE, -- must be <= 4K
   i_msg_cd     IN app_log.msg_cd%TYPE DEFAULT msgs.DEFAULT_MSG_CD,
   i_sev_cd     IN app_log.sev_cd%TYPE DEFAULT cnst.INFO,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
BEGIN
   app_log_api.ins(
      format_tbl_txt(i_log_txt),
      i_sev_cd,
      i_msg_cd,
      i_routine_nm,
      i_line_num
   );
END to_table;


--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_targets RETURN VARCHAR2
IS
BEGIN
   RETURN
   TARGET_SCREEN||'['||util.bool_to_str(g_to_screen)||'] '||
   TARGET_TABLE||'['||util.bool_to_str(g_to_table)||'] '||
   TARGET_FILE||'['||util.bool_to_str(g_to_file)||']';
END get_targets;

--------------------------------------------------------------------------------
FUNCTION get_log_dir RETURN VARCHAR2
IS
BEGIN
   RETURN (g_file_dir);
END get_log_dir;

--------------------------------------------------------------------------------
FUNCTION get_log_nm RETURN VARCHAR2
IS
BEGIN
   RETURN (g_file_nm);
END get_log_nm;

--------------------------------------------------------------------------------
FUNCTION get_log_path RETURN VARCHAR2
IS
BEGIN
   RETURN env.vld_path_format(env.get_dir_path(g_file_dir))||g_file_nm;
END get_log_path;

--------------------------------------------------------------------------------
PROCEDURE set_targets
(
   i_stdout   IN BOOLEAN DEFAULT FALSE,
   i_table    IN BOOLEAN DEFAULT FALSE,
   i_file     IN BOOLEAN DEFAULT FALSE
)
IS
BEGIN

   g_to_screen := i_stdout;
   g_to_table := i_table;
   g_to_file := i_file;

END set_targets;

--------------------------------------------------------------------------------
PROCEDURE set_log_dir(i_file_dir IN VARCHAR2)
IS
BEGIN
   g_file_dir := i_file_dir;
END set_log_dir;

--------------------------------------------------------------------------------
PROCEDURE set_log_nm(i_file_nm IN VARCHAR2)
IS
BEGIN
   g_file_nm := i_file_nm;
END set_log_nm;

--------------------------------------------------------------------------------
PROCEDURE set_log_parms
(
   i_file_dir IN VARCHAR2 DEFAULT io.get_default_filename,
   i_file_nm  IN VARCHAR2 DEFAULT io.get_default_dir
)
IS
BEGIN
   set_log_nm(i_file_nm);
   set_log_dir(i_file_dir);
END set_log_parms;

--------------------------------------------------------------------------------
PROCEDURE set_dbg (i_state IN BOOLEAN)
IS
BEGIN
   IF (i_state) THEN
      gr_debug.debugging_on := TRUE;
      gr_debug.debug_type := 'all';
      gr_debug.debug_trig := NULL;
      gr_debug.session_override := TRUE;
   ELSE
      gr_debug.debugging_on := FALSE;
      gr_debug.debug_type := 'off';
      gr_debug.debug_trig := NULL;
      gr_debug.session_override := FALSE;
   END IF;
END set_dbg;

--------------------------------------------------------------------------------
PROCEDURE set_dbg (i_dbg_val IN VARCHAR2)
IS
BEGIN
   vld_debug_toggle_format(i_dbg_val);
   IF (gr_debug.debugging_on) THEN
      gr_debug.session_override := TRUE;
   ELSE
      gr_debug.session_override := FALSE;
   END IF;
END set_dbg;

--------------------------------------------------------------------------------
PROCEDURE msg
(
   i_msg_cd     IN app_log.msg_cd%TYPE,
   i_sev_cd     IN app_log.sev_cd%TYPE,
   i_msg        IN VARCHAR2 DEFAULT NULL,
   i_reraise    IN BOOLEAN DEFAULT FALSE,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
   l_msg typ.t_maxvc2;
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   IF (i_routine_nm IS NULL) THEN
      l_routine_nm := env.get_caller_nm;
   END IF;

   IF (i_line_num IS NULL) THEN
      l_line_num := env.get_caller_line;
   END IF;
   
   -- if msg is blank, try to look it up based on the code
   IF (i_msg IS NULL) THEN
      l_msg := msgs.get_msg(i_msg_cd);
   ELSE
      l_msg := i_msg;
   END IF;
   
   -- log message to targets
   IF (g_to_screen OR g_to_file) THEN
      -- Add backtrace if available as IO.p does not add it automatically like APP_LOG_API does
      IF (utl_call_stack.error_depth > 0) THEN
         l_msg := SUBSTR(l_msg,1,1980)||CHR(10)||
                  '-- BACKTRACE --'||CHR(10)||
                  dbms_utility.format_error_backtrace;
      END IF;
   END IF;
   
   IF (g_to_screen) THEN
      io.p(format_log_txt(l_msg, NVL(i_msg_cd, msgs.DEFAULT_MSG_CD), NVL(i_sev_cd, cnst.INFO), l_routine_nm, l_line_num));
   END IF;
   
   IF (g_to_table) THEN
      to_table(l_msg, NVL(i_msg_cd, msgs.DEFAULT_MSG_CD), NVL(i_sev_cd, cnst.INFO), l_routine_nm, l_line_num);
   END IF;
   
   IF (g_to_file) THEN
      to_file(l_msg, NVL(i_msg_cd, msgs.DEFAULT_MSG_CD), NVL(i_sev_cd, cnst.INFO), l_routine_nm, l_line_num);
   END IF;
   
   -- raise exception if caller wants it
   IF (i_reraise) THEN
      IF (num.IaNb(i_msg_cd)) THEN
         excp.throw(TO_NUMBER(i_msg_cd), i_msg);
      ELSE
         excp.throw( NVL(i_msg_cd, msgs.DEFAULT_MSG_CD), i_msg);
      END IF;
   END IF;
END msg;

--------------------------------------------------------------------------------
PROCEDURE msg
(
   i_msg_id     IN app_msg.msg_id%TYPE,
   i_sev_cd     IN VARCHAR2,
   i_msg        IN VARCHAR2 DEFAULT NULL,
   i_reraise    IN BOOLEAN DEFAULT FALSE,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
   l_msg typ.t_maxvc2;
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   IF (i_routine_nm IS NULL) THEN
      l_routine_nm := env.get_caller_nm;
   END IF;

   IF (i_line_num IS NULL) THEN
      l_line_num := env.get_caller_line;
   END IF;
   
   l_msg := i_msg;
   
   -- don't try to look up msg code if ID is an Oracle built-in error or
   -- in the raise_application_error range
   IF (i_msg_id = 100 OR i_msg_id < 0) THEN
      IF (l_msg IS NULL) THEN
         l_msg := SQLERRM(i_msg_id);
      END IF;
      
      -- pass error ID and message on as is
      msg(TO_CHAR(i_msg_id), i_sev_cd, l_msg, i_reraise, l_routine_nm, l_line_num);
   ELSE
      -- try and get msg code from app_msg
      msg(msgs.get_msg_cd(i_msg_id), i_sev_cd, i_msg, i_reraise, l_routine_nm, l_line_num);
   END IF;
END msg;

--------------------------------------------------------------------------------
PROCEDURE msg(i_msg IN VARCHAR2)
IS
BEGIN
   msg(msgs.DEFAULT_MSG_CD, cnst.INFO, i_msg, FALSE);
END msg;

--------------------------------------------------------------------------------
PROCEDURE err
(
   i_reraise    IN BOOLEAN DEFAULT TRUE,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   IF (i_routine_nm IS NULL) THEN
      l_routine_nm := env.get_caller_nm;
   END IF;

   IF (i_line_num IS NULL) THEN
      l_line_num := env.get_caller_line;
   END IF;
   
   msg('Error Msg', cnst.ERROR, SQLERRM, i_reraise, l_routine_nm, l_line_num);
END err;

--------------------------------------------------------------------------------
PROCEDURE err
(
   i_msg        IN VARCHAR2,
   i_reraise    IN BOOLEAN DEFAULT TRUE,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   IF (i_routine_nm IS NULL) THEN
      l_routine_nm := env.get_caller_nm;
   END IF;

   IF (i_line_num IS NULL) THEN
      l_line_num := env.get_caller_line;
   END IF;
   
   msg('Error Msg', cnst.ERROR, i_msg, i_reraise, l_routine_nm, l_line_num);
END err;

--------------------------------------------------------------------------------
PROCEDURE warn
(
   i_msg        IN VARCHAR2,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   IF (i_routine_nm IS NULL) THEN
      l_routine_nm := env.get_caller_nm;
   END IF;

   IF (i_line_num IS NULL) THEN
      l_line_num := env.get_caller_line;
   END IF;
   
   msg('Warning Msg', cnst.WARN, i_msg, FALSE, l_routine_nm, l_line_num);
END warn;

--------------------------------------------------------------------------------
PROCEDURE info
(
   i_msg        IN VARCHAR2,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   IF (i_routine_nm IS NULL) THEN
      l_routine_nm := env.get_caller_nm;
   END IF;

   IF (i_line_num IS NULL) THEN
      l_line_num := env.get_caller_line;
   END IF;
   
   msg('Info Msg', cnst.INFO, i_msg, FALSE, l_routine_nm, l_line_num);
END info;

--------------------------------------------------------------------------------
PROCEDURE dbg
(
   i_msg        IN app_log.log_txt%TYPE,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
)
IS
   l_unit_nm     user_objects.object_name%TYPE;
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   IF (NOT gr_debug.session_override -- don't check if overriden
       AND
       (
        gr_debug.last_checked_dtm IS NULL -- check if never checked before
        OR
        -- check if minutes interval has been passed
        ((dt.get_sysdtm - gr_debug.last_checked_dtm) > g_debug_check_interval/dt.MINUTES_PER_DAY)
       ) 
      ) THEN
      -- time to requery the parm table to see if someone wants us to
      -- start logging debug messages
      check_debug_toggle();
   END IF;
   
   IF (gr_debug.debugging_on OR gr_debug.session_override) THEN
   
      -- Get caller metadata if not given. I'm assuming the caller would either
      -- pass in both, or neither, or just the routine name, but never just the
      -- line number.
      IF (l_routine_nm IS NULL) THEN
         l_routine_nm := env.get_caller_nm;
      END IF;

      IF (i_line_num IS NULL) THEN
         l_line_num := env.get_caller_line;
      END IF;
      
      -- Caller passed in routine name; use it.
      IF (INSTR(l_routine_nm,'.') > 0) THEN
         -- assume it is a package and parse package name out for later comparison
         l_unit_nm := UPPER(SUBSTR(l_routine_nm,1,INSTR(l_routine_nm,'.')-1));
      ELSE
         -- transfer name of standalone unit to l_unit_nm
         l_unit_nm := UPPER(l_routine_nm);
      END IF;
      
      -- Examine debug mode filter/trigger against values from the current 
      -- session to see if logging the debug message is required.
      IF ( (gr_debug.debug_type = 'all') OR -- this one will be used 99% of the time,
                                            -- short-circuiting the next 3 checks
           (gr_debug.debug_type = 'session' AND gr_debug.debug_trig = env.get_session_id) OR
           (gr_debug.debug_type = 'user' AND INSTR(env.get_client_id, gr_debug.debug_trig) > 0) OR 
           (gr_debug.debug_type = 'unit' AND INSTR(gr_debug.debug_trig, l_unit_nm) > 0) ) THEN

         -- goes to APP_LOG table by default, currently no way to turn that off
         to_table(i_msg, msgs.DEBUG_MSG_CD, cnst.DEBUG, l_routine_nm, l_line_num);
         
         -- also goes to stdout if it is a desired target
         IF (g_to_screen) THEN
            io.p(format_log_txt(i_msg, msgs.DEBUG_MSG_CD, cnst.DEBUG, l_routine_nm, l_line_num));
         END IF;
         
         -- also goes to file if it is a desired target
         IF (g_to_file) THEN
            to_file(i_msg, msgs.DEBUG_MSG_CD, cnst.DEBUG, l_routine_nm, l_line_num);
         END IF;
      ELSE
         NULL; -- do not bother writing debug message
      END IF; -- if filters will allow the debug log to be written out
      
   END IF; -- if debug mode is turned on by parameter or override
   
END dbg;

--------------------------------------------------------------------------------
--                  PACKAGE INITIALIZATIOINS (RARELY USED)
--------------------------------------------------------------------------------
BEGIN
   get_targets_for_env(g_to_screen, g_to_table, g_to_file);
   
   g_file_dir := parm.get_val('Default Log File Directory');
   g_file_nm := env.get_app_cd||'_'||parm.get_val('Default IO File Name');
   g_debug_check_interval := parm.get_val('Debug Toggle Check Interval');
   
   gr_debug.debugging_on := FALSE;
   gr_debug.last_checked_dtm := NULL;
   gr_debug.session_override := FALSE;

END logs;
/
