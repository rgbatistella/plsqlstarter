CREATE OR REPLACE PACKAGE app_log_api
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Governs DML operations against the APP_LOG table.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2012Jan24 Moved trim_table to LOGS package.

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

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
ins:
 Using autonomous transaction, will insert the given message, and its context, 
 into the APP_LOG table. This is a key component for any application's
 debugging, error handling and audit-trail schemes.
 
%param i_log_txt Free-form text field. Place your error or debug message in here
                 along with any context that is available at the point of the
                 error.

%param i_sev_cd Valid values are 4 constants found in the public spec of the "C" package:
                {*} ERROR - Critical error that was unexpected or serious enough to warrant immediate attention and processing cessation.
                {*} WARN - Possibly an error, or assertion violation, but processing may generally continue.
                {*} INFO - Used in verbose output to indicate processing context, loop iterations, trapped but ignored errors, etc.
                {*} DEBUG - Used only when debugging.

%param i_routine_nm Will be filled in by the calling framework routine. If calling
                    this proc manually, fill this parameter with the name of the 
                    procedure, function, trigger, object or package.routine from 
                    which the message was sent. This field is great for filtering queries.
%param i_line_num Will be filled in by the calling framework routine. If calling
                  this proc manually, fill this parameter with the line number
                  in the source code where this log message originated.
%param i_call_stack Only useful for error logging. Meant to hold the full call stack (<=9i)
                    or error backtrace (>=10g). You may pass in anything you wish 
                    to be recorded in the call_stack column, but we highly recommend 
                    dbms_utility.format_error_backtrace if you have access to it.                  
------------------------------------------------------------------------------*/
PROCEDURE ins
(
   i_log_txt     IN app_log.log_txt%TYPE,
   i_sev_cd      IN app_log.sev_cd%TYPE DEFAULT cnst.INFO,
   i_routine_nm  IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num    IN app_log.line_num%TYPE DEFAULT NULL,
   i_error_stack IN app_log.error_stack%TYPE DEFAULT NULL,
   i_call_stack  IN app_log.call_stack%TYPE DEFAULT NULL
);

END app_log_api;
/
