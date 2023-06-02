CREATE OR REPLACE PACKAGE app_log_api
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Governs DML operations against the APP_LOG table.

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
g_event_id INTEGER;

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

%param i_msg_cd Derived from APP_MSG, or can be any identifier cobbled together
                hastily by the developer. The idea is when used consistently,
                historical messages and error logging can be queried, sorted
                and reported based on this field which allows categorizing or
                grouping of related messages.

%param i_routine_nm The name of the procedure, function, trigger, object or
                    package.routine from which the message was sent. This
                    field is great for filtering just your messages,
                    running reports on the most buggy packages, etc.

%param i_line_num The line number the caller wishes to record as being the
                  source of the logged message and option call/error stacks.
------------------------------------------------------------------------------*/
PROCEDURE ins
(
   i_log_txt    IN app_log.log_txt%TYPE,
   i_sev_cd     IN app_log.sev_cd%TYPE DEFAULT cnst.INFO,
   i_msg_cd     IN app_log.msg_cd%TYPE DEFAULT NULL,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL,
   i_event_id   IN app_log.event_id%TYPE DEFAULT NULL
);

/**-----------------------------------------------------------------------------
event_ins:
 Using autonomous transaction, will insert the given event, and its context,
 into the APP_EVENT table.

%param i_name    Free-form text field. Place the name of your event in here
                 along with any context that is available.

%param i_routine_nm The name of the procedure, function, trigger, object or
                    package.routine from which the message was sent. This
                    field is great for filtering just your messages,
                    running reports on the most buggy packages, etc.

%param i_line_num The line number the caller wishes to record as being the
                  source of the logged message and option call/error stacks.
------------------------------------------------------------------------------*/
PROCEDURE event_ins
(
   i_name    IN app_event.name%TYPE,
   i_routine_nm IN app_event.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_event.line_num%TYPE DEFAULT NULL
);

/**-----------------------------------------------------------------------------
event_upd:
 Using autonomous transaction, will insert the given event, and its context,
 into the APP_EVENT table.

%param i_name    Free-form text field. Place the name of your event in here
                 along with any context that is available.

%param i_routine_nm The name of the procedure, function, trigger, object or
                    package.routine from which the message was sent. This
                    field is great for filtering just your messages,
                    running reports on the most buggy packages, etc.

%param i_line_num The line number the caller wishes to record as being the
                  source of the logged message and option call/error stacks.
------------------------------------------------------------------------------*/
PROCEDURE event_upd
(
   i_name    IN app_event.name%TYPE,
   i_routine_nm IN app_event.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_event.line_num%TYPE DEFAULT NULL
);

/**-----------------------------------------------------------------------------
trim_table:
 This routine manages the periodic cleaning of logs from the app_log table. It
 uses simple DELETE DML. If you have large volumes of logs, rewrite APP_LOG as a
 partitioned table and use partition dropping and the reuse global index
 clause to maintain availability. There is the option to write the old rows to
 file before deleting them. You may also control the amount removed from the
 back end of app_log.

%usage
 You may call trim_logs manually when needed, or place in a scheduled job. The
 Core creation script creates a DBMS_JOB by default.

%param i_keep_amt The number of time units to keep in APP_LOG. For example, if
                  i_keep_amt = 3 and i_keep_amt_uom = month, then everything
                  older than 3 months from now will be deleted.

%param i_keep_amt_uom The unit of measure for the time units. Valid values are:
                      {*} year
                      {*} month
                      {*} week
                      {*} day
                      {*} hour

%param i_archive_to_file_flg If set to Y will write the log rows to a file
                             before deleting them from the table.

%param i_archive_file_nm The file name to use if copying APP_LOG rows to file
                         before deleting.
------------------------------------------------------------------------------*/
PROCEDURE trim_table
(
 o_rows_deleted         OUT NUMBER,
 i_keep_amt             IN NUMBER DEFAULT 2,
 i_keep_amt_uom         IN VARCHAR2 DEFAULT 'week',
 i_archive_to_file_flg  IN VARCHAR2 DEFAULT 'N',
 i_archive_file_nm      IN VARCHAR2 DEFAULT NULL
);

END app_log_api;
/
