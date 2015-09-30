CREATE OR REPLACE PACKAGE excp
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Package of public exceptions and some common routines (assert and throw) to
 assist in error-handling code.

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
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

-- {%skip}
-- Exceptions for constraints
gx_parent_integrity_constraint EXCEPTION;
   PRAGMA EXCEPTION_INIT (gx_parent_integrity_constraint, -2291);
gx_unique_integrity_constraint EXCEPTION;
   PRAGMA EXCEPTION_INIT (gx_unique_integrity_constraint, -1);
gx_child_integrity_constraint EXCEPTION;
   PRAGMA EXCEPTION_INIT (gx_child_integrity_constraint, -2292);
gx_check_integrity_constraint EXCEPTION;
   PRAGMA EXCEPTION_INIT (gx_check_integrity_constraint, -2290);

-- {%skip}
-- Exceptions for date input masking
gx_date_format_mismatch EXCEPTION; 
   PRAGMA EXCEPTION_INIT (gx_date_format_mismatch, -1830);
gx_invalid_day_in_month EXCEPTION; 
   PRAGMA EXCEPTION_INIT (gx_invalid_day_in_month, -1829);
gx_date_mask_short EXCEPTION; 
   PRAGMA EXCEPTION_INIT (gx_date_mask_short, -1840);
gx_invalid_month EXCEPTION; 
   PRAGMA EXCEPTION_INIT (gx_invalid_month, -1843);
gx_invalid_week EXCEPTION; 
   PRAGMA EXCEPTION_INIT (gx_invalid_week, -1844);
gx_invalid_day EXCEPTION; 
   PRAGMA EXCEPTION_INIT (gx_invalid_day, -1847);

-- {%skip}
-- Other exceptions
gx_row_locked EXCEPTION;
   PRAGMA EXCEPTION_INIT(gx_row_locked , -00054);
gx_pkg_state_old EXCEPTION;
   PRAGMA EXCEPTION_INIT(gx_pkg_state_old, -04068);
   
--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
assert:
 Assertions allow you to verify assumptions before proceeding in a program.
 Pass an expression that has a boolean result. Assert will check it for true or
 false, and raise an exception if the assertion checked is false. If you wish 
 the program to continue, you will need to pass FALSE in for the third parameter.
 In this case, when i_raise_excp is FALSE, the assertion will be sent to the
 output buffer (to screen, which will not be seen by Java clients or batch
 programs) and to the APP_LOG table.
 
 In most cases, you will not need to fill the i_excp_nm parameter, it will default
 to VALUE_ERROR. However, if you have another bound or pre-defined exception, you
 may pass that in by name as well.

%usage
 Anything that can be turned into a Boolean expression can serve as the first 
 parameter to assert().
 
 Numbers:
   excp.assert(i_run_id > 0, 'Run ID must be a positive integer.');
   excp.assert(LENGTH(l_str) < 4000,'Message is too long');
   Note: Messages will be printed to the screen and (in case it is a batch 
         program) to the logging table.
 Dates:
   excp.assert(i_start_dtm >= dt.get_sysdt,
         'Time travel violation. Start date must be in the future');
 Strings:
   excp.assert(l_code IN ('U','X','Z'), 'Valid codes are U, X and Z.');
 Boolean:
   excp.assert(l_continue_flg = TRUE, 'Continue Flag is false.');
 NULL conditions:
   excp.assert(l_stmt IS NOT NULL, 'Provided statement can''t be empty.');
   excp.assert(l_var IS NULL, 'Variable l_var already had a value.');

 Optional named exception handling:
   excp.assert(l_state_busy, NULL, TRUE, 'excp.gx_row_locked');

 Optional log and continue:
   excp.assert(i_expr => l_var IS NULL,
          i_msg => 'Variable l_var already had a value.'
          i_raise_excp => FALSE);
 
%param i_expr Boolean expression, e.g. "1000 = i_num_recs", "i_rec_type IS NOT NULL",
              "l_control_num != l_counter", etc.
               
%param i_msg The message that will be fed to the error stack (if re-raising) or
             to the screen and APP_LOG table (if continuing).

%param i_raise_excp Whether to raise an exception or allow processing to continue.
                    {*} TRUE Default. Raises named exception (see i_excp_nm), 
                        or VALUE_ERROR if no name given.
                    {*} FALSE Pass FALSE if you wish to allow the program to 
                        continue after logging the assertion failure (not
                        recommended).

%param i_excp_nm Can be an Oracle pre-defined exception, or a user-defined 
                 exception. If user-defined, the exception must be publicly 
                 visible (declared in a package specification).

%param i_routine_nm The name of the procedure, function, trigger, object or
                    package.routine from which the assertion was tested. If not
                    given, this will be determined for you. This parameter is
                    only needed if i_raise_excp is FALSE.
                    
%param i_line_num The line number where the caller wishes to indicate the 
                  assertion failure occurred. If not given, this will be 
                  determined for you and will point to the line where 
                  excp.assert was called. This parameter is only needed if 
                  i_raise_excp is FALSE.
------------------------------------------------------------------------------*/
PROCEDURE assert
(
   i_expr       IN BOOLEAN,
   i_msg        IN VARCHAR2,
   i_raise_excp IN BOOLEAN DEFAULT TRUE,
   i_excp_nm    IN VARCHAR2 DEFAULT NULL,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
);

/**-----------------------------------------------------------------------------
throw:
 Throw is called mainly by the LOGS package for most exception handling, replacing 
 hard-coded and conflicting IDs frequently used with RAISE_APPLICATION_ERROR.

 Replacing direct calls to RAISE_APPLICATION_ERROR helps reduce hard-code, 
 enforcing consistent exception handling, and coordinates use and re-use of IDs 
 and messages (found in Oracle's base error library and in the APP_MSG table).
 
 In general, you will always call one of the LOGS routines and let it know
 whether to re-raise the trapped exception. If you have a need to bypass logging
 and immediately raise an error, then you can call throw().

%design
 I chose "throw" because "raise" is a reserved word in PL/SQL. Our Oracle 
 tools uppercase "raise" when typed. This meant that you'd have to go back and 
 change it back to lowercase to meet format standards. Not fun. So I went with "throw" 
 which matches Java terminology, the other half of most application tech stacks.

%note
 The message text is optional. If you provide text, it will be used. If you don't
 provide text, the message text will be looked up in APP_MSG.

%caveat
 Throw, by itself, does no logging. We want to log most errors we come across.
 Therefore, you should not be using throw directly, if at all. Usually if it is
 an error that warrants attention, but not immediate, you will call logs.msg or
 logs.warn. If it is or could be disastrous, you will call 
    logs.msg('Storage Error',cnst.ERROR,'Filesystem full.',TRUE);
    or
    logs.err('Nasty error.');
 both of which log and call excp.throw to re-raise the exception.

%usage
 Simple user-defined exception raising:
   throw; -- raises the last SQLCODE with its SQLERRM
   throw(9980); -- User defined error ID. Should have error text defined in APP_MSG.
                -- Literals are discouraged. Use logs.err or logs.msg instead.
   throw(msgs.get_msg_id('Heinous Error')); -- Message will be looked up in app_msg
   OR
   throw('Heinous Error','Detected awful error. Processing halted.'); -- Message in app_msg overwritten by this one
   
 Exception raising where an application exception is being replaced by throw:
   throw(-20050,'Cannot read APP_PARM. Check permissions.');

%param i_msg_id Positive or negative error number, either from APP_MSG or from
                list of Oracle error numbers (allowed user-defined range, or
                Oracle pre-defined).

%param i_msg_cd Named message, found in APP_MSG table. You can also invent one
                on the spot, like "My Awesome Message", or use the default Ad-Hoc
                Message code reference by msgs.DEFAULT_MSG_CD.

%param i_msg  Custom message to be raised along with the user-defined exception ID.
------------------------------------------------------------------------------*/
PROCEDURE throw
(
   i_msg_id IN app_msg.msg_id%TYPE DEFAULT SQLCODE,
   i_msg IN VARCHAR2 DEFAULT SQLERRM
);
PROCEDURE throw
(
   i_msg_cd IN app_msg.msg_cd%TYPE,
   i_msg IN VARCHAR2 DEFAULT NULL
);

END excp;
/
