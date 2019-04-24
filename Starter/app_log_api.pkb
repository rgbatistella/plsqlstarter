CREATE OR REPLACE PACKAGE BODY app_log_api
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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'app_log_api';

g_log_archive_dir typ.t_maxobjnm; 

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
   i_log_txt    IN app_log.log_txt%TYPE,
   i_sev_cd     IN app_log.sev_cd%TYPE DEFAULT cnst.info,
   i_msg_cd     IN app_log.msg_cd%TYPE DEFAULT NULL,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
) IS
   lr_app_log app_log%ROWTYPE;
BEGIN
   SELECT app_log_seq.NEXTVAL
     INTO lr_app_log.log_id
     FROM dual;
     
   lr_app_log.app_id      := env.get_app_id;
   lr_app_log.log_ts      := dt.get_systs;
   lr_app_log.sev_cd      := NVL(i_sev_cd, cnst.info);
   lr_app_log.msg_cd      := NVL(i_msg_cd, msgs.DEFAULT_MSG_CD);
   lr_app_log.routine_nm  := NVL(i_routine_nm, cnst.unknown_str);
   lr_app_log.line_num    := i_line_num;
   lr_app_log.log_txt     := i_log_txt;
   lr_app_log.client_id   := env.get_client_id;
   lr_app_log.client_ip   := env.get_client_ip;
   lr_app_log.client_host := env.get_client_host;
   lr_app_log.client_os_user := env.get_client_os_user;
   
   ins(lr_app_log);

END ins;

------------------------------------------------------------------------------
PROCEDURE trim_table
(
 o_rows_deleted         OUT NUMBER,
 i_keep_amt             IN NUMBER DEFAULT 2,
 i_keep_amt_uom         IN VARCHAR2 DEFAULT 'week',
 i_archive_to_file_flg  IN VARCHAR2 DEFAULT 'N',
 i_archive_file_nm      IN VARCHAR2 DEFAULT NULL
)
IS
   l_lower_bound DATE;
   l_keep_amt NUMBER := ABS(i_keep_amt);
   l_keep_amt_uom VARCHAR2(10) := LOWER(i_keep_amt_uom);
   l_file_nm VARCHAR2(100);
   
   FUNCTION format_log_txt(ir_app_log IN app_log%ROWTYPE) RETURN VARCHAR2
   IS
   BEGIN
      RETURN SUBSTR(TO_CHAR(ir_app_log.log_ts, 'YYYY/MM/DD') || cnst.pipechar ||
                    TO_CHAR(ir_app_log.log_ts, 'HH24:MI:SSxFF') || cnst.pipechar ||
                    env.get_app_cd(ir_app_log.app_id) || cnst.pipechar ||
                    ir_app_log.client_id || cnst.pipechar ||
                    -- skipped client_ip, client_host and client_os_user
                    NVL(ir_app_log.routine_nm, cnst.unknown_str) || cnst.pipechar || 
                    NVL(TO_CHAR(ir_app_log.line_num), '-') || cnst.pipechar || 
                    ir_app_log.sev_cd || cnst.pipechar ||
                    ir_app_log.msg_cd || cnst.pipechar ||
                    NVL(ir_app_log.log_txt, 'Message missing. Figure out why!'),
                    1,
                    cnst.max_vc2_len -- UTL_FILE limited to 32K
                    );
   END format_log_txt;
BEGIN

   IF (l_keep_amt_uom = 'year') THEN
      l_lower_bound := SYSDATE - (l_keep_amt * dt.DAYS_PER_YEAR);
   ELSIF (l_keep_amt_uom = 'month') THEN
      l_lower_bound := ADD_MONTHS(SYSDATE,-(l_keep_amt));
   ELSIF (l_keep_amt_uom = 'week') THEN
      l_lower_bound := SYSDATE - (l_keep_amt * dt.DAYS_PER_WEEK);
   ELSIF (l_keep_amt_uom = 'day') THEN
      l_lower_bound := SYSDATE - l_keep_amt;
   ELSIF (l_keep_amt_uom = 'hour') THEN
      l_lower_bound := SYSDATE - (l_keep_amt/dt.HOURS_PER_DAY);
   ELSE
      -- can't use the higher layer packages, so must do raw RAE
      raise_application_error(-20000,'A Keep Unit of Measure of ['||i_keep_amt_uom||
         '] is not supported. Use hour, day, week, month or year. Not case sensitive.');
   END IF;
   
   --dbms_output.put_line(TO_CHAR(l_lower_bound,'YYYYMonDD HH24:MI:SS')); 
   
   -- Handle copying to file if requested
   IF (i_archive_to_file_flg = 'Y') THEN
   
      l_file_nm := NVL(i_archive_file_nm,TO_CHAR(SYSDATE,'YYYYMMDD')||'_app_log_archive.log');
      
      FOR lr_app_log IN (SELECT * FROM app_log WHERE log_ts < l_lower_bound) LOOP
         io.write_line(
            format_log_txt(lr_app_log),
            l_file_nm,
            g_log_archive_dir
            );
      END LOOP;
   END IF;
   
   DELETE FROM app_log WHERE log_ts < l_lower_bound;
   o_rows_deleted := SQL%ROWCOUNT;
    
   COMMIT;
      
END trim_table;

--------------------------------------------------------------------------------
--                  PACKAGE INITIALIZATIOINS (RARELY USED)
--------------------------------------------------------------------------------
BEGIN
   g_log_archive_dir := parm.get_val('Log Archive Directory');
   
END app_log_api;
/
