CREATE OR REPLACE PACKAGE msgs
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 A collection of routines for utilizing the standard messages contained in 
 APP_MSG.

%design
 Build a GUI to administer the data in APP_MSG, so the development team can 
 collaborate, easily search for existing and add new standard messages.
 Getting standard messages into APP_MSG needs to be easy, or this feature will
 be ignored and bypassed by your developers.

%note
 I prefer to only use the singular in table and package names, but unfortunately
 the package name MSG conflicts with the msg() procedures inside the LOGS
 package, when LOGS tries to refer to constants and routines in the MSG package
 it can't resolve everything.
 
<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008Feb02 Moved all routines that didn't pertain to reading APP_MSG
                       to the LOGS and IO packages.

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
DEFAULT_MSG_CD CONSTANT app_msg.msg_cd%TYPE := 'Ad-Hoc Msg';
MISSING_MSG_CD CONSTANT app_msg.msg_cd%TYPE := 'Missing Msg';
ERROR_MSG_CD    CONSTANT app_msg.msg_cd%TYPE := 'Error Msg';
WARN_MSG_CD    CONSTANT app_msg.msg_cd%TYPE := 'Warning Msg';
INFO_MSG_CD    CONSTANT app_msg.msg_cd%TYPE := 'Info Msg';
DEBUG_MSG_CD   CONSTANT app_msg.msg_cd%TYPE := 'Debug Msg';

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_msg:
 This overloaded function retrieves the message text based on the message name 
 or the message number. This is the main routine I expect application PL/SQL to 
 use as they send messages to the screen (io.p) or the various log targets 
 (logs.msg, logs.dbg, logs.err, etc.)

%usage
 <code>
   logs.err('Daily Load status: '|| msgs.get_msg(l_return_code));
   logs.warn(msgs.get_msg('Date Missing'));

%param i_msg_cd This is the name of the desired message, found in APP_MSG.
%param i_msg_id This is the ID of the desired message, found in APP_MSG.
------------------------------------------------------------------------------*/
FUNCTION get_msg(i_msg_cd IN	app_msg.msg_cd%TYPE)  RETURN VARCHAR2;
FUNCTION get_msg(i_msg_id IN	app_msg.msg_id%TYPE)  RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_msg_id:
 Returns the message number based on the message name. It is mainly meant for 
 use by framework internals, not application code.

%usage
 (for Java client expecting a return code indicating status)
 <code>
   WHEN lx_useless_record THEN
      RETURN msgs.get_msg_id('Useless Record');
------------------------------------------------------------------------------*/
FUNCTION get_msg_id(i_msg_cd IN	app_msg.msg_cd%TYPE)  RETURN NUMBER;

/**-----------------------------------------------------------------------------
get_msg_cd:
 Returns the message code based on the message ID. It is mainly meant for use 
 by framework internals, not application code.

%usage
 <code>
   logs.msg(msgs.get_msg(msgs.get_msg_cd(l_return_cd)));
------------------------------------------------------------------------------*/
FUNCTION get_msg_cd(i_msg_id IN	app_msg.msg_id%TYPE)  RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
fill_msg:
 The three versions of this routine resemble printf used in cnst.
 
 Certain messages in APP_MSG will contain placeholders. The placeholders must
 follow a numerical sequence and be surrounded by some special character which
 indicates that the number is a placeholder, e.g. a fictitious message named
 "Column Update Failure", whose full error text might be defined in APP_MSG as

 "Update of column @1@ on table @2@ failed given the PK value @3@"

 Assuming you trapped the error and wanted to note it in the logs using the
 standard table-defined message text, you'd replace the placeholders with the
 error's contextual information like this:
 <code>
    las_context(1) := 'assigned_to'; -- column name placeholder
    las_context(2) := 'ORDERS'; -- table name placeholder
    las_context(3) := 'ord_id' -- PK placeholder;
    msgs.fill_msg('Column Update Failure',las_context); 
 </code>
 
 or you could use the non-array version like this:
 <code>
    msgs.fill_msg('Column Update Failure', 'assigned_to', 'ORDERS', 'ord_id');
 </code>
 
 The values placed in the array will then replace the placeholders in the message
 in the order in which they are placed in the array, i.e. value 1 in the array
 will look through the message for placeholder "@1@" and replace it, and so on.
 This enables the content and placeholders in the message to be flexible. If you
 needed to add a fourth value that happened to fall before the "@1@" placeholder,
 no problem. You do not need to renumber the placeholders or change any previous
 code using the same message. For example, if we wanted to make the message more
 dynamic instead of hardcoding it around the given PK value, you could alter it
 in APP_MSG to look like this:

 "Update of column @1@ on table @2@ failed given the @4@ value @3@"

 Then it's only a matter of adding a fourth element to the context array before
 calling fill_msg.

------------------------------------------------------------------------------*/
FUNCTION fill_msg
(
   i_msg_cd    IN app_msg.msg_cd%TYPE,
   ias_fill    IN typ.tas_medium,
   i_wrap_char IN VARCHAR2 DEFAULT cnst.subchar
) RETURN VARCHAR2;

FUNCTION fill_msg
(
   i_msg_id    IN app_msg.msg_id%TYPE,
   ias_fill    IN typ.tas_medium,
   i_wrap_char IN VARCHAR2 DEFAULT cnst.subchar
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
fill_msg:
 Some of my developers were annoyed by having to use an array every time they
 wanted to log some context to the error message. So I created this one that
 takes up to five plain old strings as parameters. If you are passing in a date
 or formatted number, you should wrap the parameter with TO_CHAR() and its
 format mask before passing it in.
------------------------------------------------------------------------------*/
FUNCTION fill_msg
(
   i_msg_cd    IN app_msg.msg_cd%TYPE,
   i_field1    IN VARCHAR2 DEFAULT NULL,
   i_field2    IN VARCHAR2 DEFAULT NULL,
   i_field3    IN VARCHAR2 DEFAULT NULL,
   i_field4    IN VARCHAR2 DEFAULT NULL,
   i_field5    IN VARCHAR2 DEFAULT NULL,
   i_wrap_char IN VARCHAR2 DEFAULT cnst.subchar
) RETURN VARCHAR2;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------


END msgs;
/
