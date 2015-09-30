CREATE OR REPLACE PACKAGE BODY app_log_api
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

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
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
PROCEDURE ins(ir_app_log IN app_log%ROWTYPE) IS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

   INSERT INTO app_log
   VALUES ir_app_log;

   COMMIT; -- must be here for autonomous to work
END ins;

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

------------------------------------------------------------------------------
PROCEDURE ins
(
   i_log_txt     IN app_log.log_txt%TYPE,
   i_sev_cd      IN app_log.sev_cd%TYPE DEFAULT cnst.INFO,
   i_routine_nm  IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num    IN app_log.line_num%TYPE DEFAULT NULL,
   i_error_stack IN app_log.error_stack%TYPE DEFAULT NULL,
   i_call_stack  IN app_log.call_stack%TYPE DEFAULT NULL
) IS
   lr_app_log app_log%ROWTYPE;
BEGIN
   SELECT app_log_seq.NEXTVAL
     INTO lr_app_log.log_id
     FROM dual;
     
   lr_app_log.log_ts      := dt.get_systs;
   lr_app_log.sev_cd      := NVL(i_sev_cd, cnst.INFO);
   lr_app_log.routine_nm  := NVL(i_routine_nm, cnst.UNKNOWN_STR);
   lr_app_log.line_num    := i_line_num;
   lr_app_log.log_txt     := i_log_txt;
   lr_app_log.error_stack := i_error_stack;
   lr_app_log.call_stack  := i_call_stack;
   lr_app_log.client_id   := env.get_client_id;
   lr_app_log.client_ip   := env.get_client_ip;
   lr_app_log.client_host := env.get_client_host;
   lr_app_log.client_os_user := env.get_client_os_user;
   
   ins(lr_app_log);

END ins;
   
END app_log_api;
/
