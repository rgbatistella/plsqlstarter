CREATE OR REPLACE PACKAGE BODY io
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

<pre>
Artisan      Date      Comments
============ ========= =========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008Feb05 Added a few functions and simplified others.

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
gc_pkg_nm CONSTANT user_source.name%TYPE := 'io';

g_default_dir typ.t_maxobjnm;
g_default_filename VARCHAR2(1024);
g_max_linesize INTEGER := cnst.MAX_VC2_LEN;

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
log_and_cleanup:
 Used by exception handler to ensure that file handles are released

%param i_handle Handle to file.
%param i_marker Optional numeric or string "tag" to indicate where in the routine
                a UTL_FILE exception occurred that cause a cleanup to be necessary.
%param i_msg Helpful message to indicate what happened that caused a cleanup.
------------------------------------------------------------------------------*/
PROCEDURE log_and_cleanup
(
   io_handle IN OUT utl_file.file_type,
   i_marker IN VARCHAR2,
   i_msg    IN VARCHAR2
) IS
BEGIN
   -- IO package is meant to be at lowest level, dependent on no other packages
   -- other than CNST & PARM. This is why we only sent output to screen instead of
   -- tables or logs, especially since it was probably the logging that created
   -- the error right before this log_and_cleanup routine was called.
   p(i_marker, i_msg);
   utl_file.fclose(io_handle);
   utl_file.fclose_all;
END log_and_cleanup;

/**-----------------------------------------------------------------------------
bool_to_str:
 Converts a PL/SQL Boolean value to TRUE, FALSE or NULL. There is another copy
 of this routine in UTIL, but IO is supposed to be the lowest level, independent
 of other packages except CNST, TYP and PARM.
------------------------------------------------------------------------------*/
FUNCTION bool_to_str(i_bool_val IN BOOLEAN) RETURN VARCHAR2
IS
BEGIN
   IF (i_bool_val) THEN
      RETURN 'TRUE';
   ELSIF (i_bool_val IS NULL) THEN
      RETURN 'NULL';
   ELSE
      RETURN 'FALSE';
   END IF;
END bool_to_str;

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_default_dir RETURN VARCHAR2
IS 
BEGIN
   RETURN g_default_dir; 
END get_default_dir;

--------------------------------------------------------------------------------
PROCEDURE set_default_dir (i_default_dir IN VARCHAR2)
IS
BEGIN
   g_default_dir := i_default_dir;
END set_default_dir;

--------------------------------------------------------------------------------
FUNCTION get_default_filename RETURN VARCHAR2
IS
BEGIN

   IF (g_default_filename IS NULL) THEN
      DECLARE
         l_app_cd app.app_cd%TYPE;
      BEGIN
         l_app_cd := env.get_app_cd;
         g_default_filename := TO_CHAR(dt.get_sysdt,'YYYYMMDD')||'_'||
                                  NVL(l_app_cd,cnst.UNKNOWN_STR)||'.log';
      END;
   END IF;
   
   RETURN g_default_filename;
END get_default_filename;

--------------------------------------------------------------------------------
PROCEDURE set_default_filename (i_default_filename IN VARCHAR2)
IS
BEGIN
   g_default_filename := i_default_filename;
END set_default_filename;

--------------------------------------------------------------------------------
FUNCTION file_exists
(
   i_file_nm  IN VARCHAR,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN BOOLEAN IS
   lb_exists BOOLEAN := FALSE;
   ln_len    NUMBER := 0;
BEGIN
   get_file_props(i_file_nm, i_file_dir, lb_exists, ln_len);
   RETURN lb_exists;
END file_exists;

--------------------------------------------------------------------------------
FUNCTION file_length_lines
(
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN INTEGER IS
   l_proc_nm      app_log.routine_nm%TYPE := gc_pkg_nm||'.file_length_lines';
   lr_file_handle utl_file.file_type;
   l_line         typ.t_maxvc2;
   l_marker       VARCHAR2(40); -- for debugging only
   l_total        INTEGER := 0;
BEGIN
   l_marker       := 'fopen';
   lr_file_handle := utl_file.fopen(i_file_dir,
                                    i_file_nm,
                                    'R',
                                    g_max_linesize);
   -- check to ensure file is open and handle is valid
   l_marker := 'is_open';
   IF (utl_file.is_open(lr_file_handle)) THEN
   
      -- Read through the file until we reach the last line.
      l_marker := 'get_line in loop';
      BEGIN
         LOOP
            -- only need to read 1st character of each since we just need a count
            utl_file.get_line(lr_file_handle, l_line, g_max_linesize);
            l_total := l_total + 1;
         END LOOP;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            -- UTL_FILE throws this when EOF reached
            NULL;
      END;
   
      l_marker := 'fclose';
      utl_file.fclose(lr_file_handle);
   ELSE
      RAISE utl_file.invalid_filehandle;
   END IF;
   
   RETURN l_total;
   
EXCEPTION
   -- fopen exceptions
   WHEN utl_file.invalid_path THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Path. Check init.ora for utl_file_dir parm ' ||
                      'and 9i directories. Check spelling, file delimiter and permissions');
      RAISE;
   WHEN utl_file.invalid_filehandle THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Filehandle. File might be closed.');
      RAISE;
   WHEN utl_file.invalid_operation THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Operation. If mode is R, file must exist. ' ||
                      'The requested peration must be compatible with file mode.');
      RAISE;
      -- get_line exceptions
   WHEN utl_file.read_error THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Read Error. Check ' || i_file_dir || ' and ' ||
                      i_file_nm ||
                      'for proper OS permissions and user/group ownership. Also double-check' ||
                      'spealling, extension, and extension delimiter.');
      RAISE;
   WHEN NO_DATA_FOUND THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'No Data Found. The end of the file was reached.');
      RAISE;
   WHEN VALUE_ERROR THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Value Error. The line read does not fit in the buffer.');
      RAISE;
   WHEN OTHERS THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      SQLERRM);
      RAISE;
END file_length_lines;

--------------------------------------------------------------------------------
FUNCTION read_line
(
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_line_num IN INTEGER DEFAULT 1,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN VARCHAR2 IS
   l_proc_nm      app_log.routine_nm%TYPE := gc_pkg_nm||'.read_line';
   lr_file_handle utl_file.file_type;
   l_line         typ.t_maxvc2;
   lx_eof EXCEPTION;
   l_marker    VARCHAR2(40); -- for debugging only
   l_curr_line INTEGER := 0;

BEGIN
   -- open file for IO operations

   -- 8i: The first parameter to fopen is a directory specified in init.ora file. 
   -- It must include the directory delimiter '/' (Unix) or '\' (NT) at the end of
   -- the directory name (unlike the way it looks in the init.ora file)
   -- 9i: Don't use init.ora to establish directories anymore. Instead, as sys or
   -- system, set up directories using CREATE DIRECTORY. Grant WRITE access to
   -- schemas that need to use them.
   l_marker       := 'fopen';
   lr_file_handle := utl_file.fopen(i_file_dir, i_file_nm, 'R', g_max_linesize);

   -- check to ensure file is open and handle is valid
   l_marker := 'is_open';
   IF (utl_file.is_open(lr_file_handle)) THEN
   
      -- Read through the file until we reach the last line.
      l_marker := 'get_line in loop';
      BEGIN
         LOOP
            -- only need to read 1st character of each since we just need a count
            utl_file.get_line(lr_file_handle, l_line, g_max_linesize);
            l_curr_line := l_curr_line + 1;
            EXIT WHEN(l_curr_line = i_line_num);
         END LOOP;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            -- UTL_FILE throws this when EOF reached
            RAISE lx_eof;
      END;
   
      l_marker := 'fclose';
      utl_file.fclose(lr_file_handle);
   ELSE
      RAISE utl_file.invalid_filehandle;
   END IF;
   
   RETURN l_line;

EXCEPTION
   -- fopen exceptions
   WHEN utl_file.invalid_path THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Path. Check init.ora for utl_file_dir parm ' ||
                      'and 9i directories. Check spelling, file delimiter and permissions');
      RAISE;
   WHEN utl_file.invalid_filehandle THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Filehandle. File might be closed.');
      RAISE;
   WHEN utl_file.invalid_operation THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Operation. If mode is R, file must exist. ' ||
                      'The requested peration must be compatible with file mode.');
      RAISE;
      -- get_line exceptions
   WHEN utl_file.read_error THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Read Error. Check ' || i_file_dir || ' and ' ||
                      i_file_nm ||
                      'for proper OS permissions and user/group ownership. Also double-check' ||
                      'spealling, extension, and extension delimiter.');
      RAISE;
   WHEN NO_DATA_FOUND THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'No Data Found. The end of the file was reached.');
      RAISE;
   WHEN VALUE_ERROR THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Value Error. The line read does not fit in the buffer.');
      RAISE;
   WHEN lx_eof THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'End of File. Reached the end of the file before finding line ' ||
                      i_line_num);
      raise_application_error(-20000,
                              'ERROR. Reached the end of the file before finding line ' ||
                              i_line_num);
   WHEN OTHERS THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || '[' || l_marker || ']',
                      SQLERRM);
      RAISE;
END read_line;

--------------------------------------------------------------------------------
FUNCTION file_length_bytes
(
   i_file_nm  IN VARCHAR DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN NUMBER IS
   lb_exists BOOLEAN := FALSE;
   ln_len    NUMBER := 0;
BEGIN
   get_file_props(i_file_nm, i_file_dir, lb_exists, ln_len);
   RETURN ln_len;
END file_length_bytes;

--------------------------------------------------------------------------------
FUNCTION convert_file_to_blob
(
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN BLOB IS
   l_bfile BFILE;
   l_data  BLOB;
BEGIN
   dbms_lob.createtemporary(lob_loc => l_data,
                            CACHE   => TRUE,
                            dur     => dbms_lob.CALL);
   l_bfile := BFILENAME(i_file_dir, i_file_nm);
   dbms_lob.fileopen(l_bfile, dbms_lob.file_readonly);
   dbms_lob.loadfromfile(l_data, l_bfile, dbms_lob.getlength(l_bfile));
   dbms_lob.fileclose(l_bfile);
   RETURN l_data;
END convert_file_to_blob;

--------------------------------------------------------------------------------
PROCEDURE write_line
(
   i_msg      IN VARCHAR2,
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir,
   i_mode     IN VARCHAR2 DEFAULT 'A'
) IS
   l_proc_nm      app_log.routine_nm%TYPE := gc_pkg_nm||'.write_line';
   lr_file_handle utl_file.file_type;
   l_marker       VARCHAR2(40); -- for debugging only

BEGIN
   -- open file for IO operations

   -- 8i: The first parameter to fopen is a directory specified in init.ora file. 
   -- It must include the directory delimiter '/' (Unix) or '\' (NT) at the end of
   -- the directory name (unlike the way it looks in the init.ora file)
   -- 9i: Don't use init.ora to establish directories anymore. Instead, as sys or
   -- system, set up directories using CREATE DIRECTORY. Grant WRITE access to
   -- schemas that need to use them.
   l_marker       := 'fopen';
   lr_file_handle := utl_file.fopen(i_file_dir,
                                    i_file_nm,
                                    i_mode,
                                    g_max_linesize);


   -- check to ensure file is open and handle is valid
   l_marker := 'is_open';
   IF (utl_file.is_open(lr_file_handle)) THEN
   
      -- write to file
      l_marker := 'put_line';
      utl_file.put_line(lr_file_handle, i_msg);
   
      -- flush buffer (so line can be read immediately) and close file
      l_marker := 'fflush';
      utl_file.fflush(lr_file_handle);
   
      l_marker := 'fclose';
      utl_file.fclose(lr_file_handle);
   ELSE
      RAISE utl_file.invalid_filehandle;
   END IF;

EXCEPTION
   -- fopen exceptions
   WHEN utl_file.invalid_path THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Path. Check init.ora for utl_file_dir parm ' ||
                      'and 9i directories. Check spelling, file delimiter and permissions');
      RAISE;
   WHEN utl_file.invalid_mode THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Mode. Only r/R, a/A and w/W are permitted for fopen.');
      RAISE;
   WHEN utl_file.invalid_operation THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Operation. If mode is R, file must exist. ' ||
                      'The requested peration must be compatible with file mode.');
      RAISE;
   WHEN utl_file.invalid_maxlinesize THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Specified maxlinesize in call to fopen must be between ' ||
                      '1 and g_max_linesize');
      RAISE;
   
   -- put_line, fflush and fclose exceptions
   WHEN utl_file.write_error THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Write Error. Disk full or bad. OS-based error.');
      RAISE;
   WHEN utl_file.invalid_filehandle THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Filehandle. File might be closed.');
      RAISE;
   WHEN utl_file.invalid_filename THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Filename. Check spelling and special characters.');
      RAISE;
   
   -- other UTL_FILE exceptions 
   WHEN utl_file.internal_error THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Internal Error. Undefined. No idea what''s wrong. Good luck!');
      RAISE;
   WHEN utl_file.access_denied THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Access denied on the file or directory. Check permissions.');
      RAISE;
   WHEN OTHERS THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      SQLERRM);
      RAISE;
END write_line;

--------------------------------------------------------------------------------
PROCEDURE write_lines
(
   i_msgs     IN typ.tas_maxvc2,
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir,
   i_mode     IN VARCHAR2 DEFAULT 'A'
)
IS
   l_proc_nm      app_log.routine_nm%TYPE := gc_pkg_nm||'.write_lines';
   lr_file_handle utl_file.file_type;
   l_marker       VARCHAR2(40); -- for debugging only

BEGIN
   -- open file for IO operations

   -- 8i: The first parameter to fopen is a directory specified in init.ora file. 
   -- It must include the directory delimiter '/' (Unix) or '\' (NT) at the end of
   -- the directory name (unlike the way it looks in the init.ora file)
   -- 9i: Don't use init.ora to establish directories anymore. Instead, as sys or
   -- system, set up directories using CREATE DIRECTORY. Grant WRITE access to
   -- schemas that need to use them.
   l_marker       := 'fopen';
   lr_file_handle := utl_file.fopen(i_file_dir,
                                    i_file_nm,
                                    i_mode,
                                    g_max_linesize);


   -- check to ensure file is open and handle is valid
   l_marker := 'is_open';
   IF (utl_file.is_open(lr_file_handle)) THEN
   
      -- write to file
      IF (i_msgs IS NOT NULL AND i_msgs.count > 0) THEN
         FOR i IN i_msgs.FIRST..i_msgs.LAST LOOP
            l_marker := 'put_line('||TO_CHAR(i)||')';
            utl_file.put_line(lr_file_handle, i_msgs(i));
         END LOOP;
      END IF;
      
      -- flush buffer (so line can be read immediately) and close file
      l_marker := 'fflush';
      utl_file.fflush(lr_file_handle);
   
      l_marker := 'fclose';
      utl_file.fclose(lr_file_handle);
   ELSE
      RAISE utl_file.invalid_filehandle;
   END IF;

EXCEPTION
   -- fopen exceptions
   WHEN utl_file.invalid_path THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Path. Check init.ora for utl_file_dir parm ' ||
                      'and 9i directories. Check spelling, file delimiter and permissions');
      RAISE;
   WHEN utl_file.invalid_mode THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Mode. Only r/R, a/A and w/W are permitted for fopen.');
      RAISE;
   WHEN utl_file.invalid_operation THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Operation. If mode is R, file must exist. ' ||
                      'The requested peration must be compatible with file mode.');
      RAISE;
   WHEN utl_file.invalid_maxlinesize THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Specified maxlinesize in call to fopen must be between ' ||
                      '1 and g_max_linesize');
      RAISE;
   
   -- put_line, fflush and fclose exceptions
   WHEN utl_file.write_error THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Write Error. Disk full or bad. OS-based error.');
      RAISE;
   WHEN utl_file.invalid_filehandle THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Filehandle. File might be closed.');
      RAISE;
   WHEN utl_file.invalid_filename THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Invalid Filename. Check spelling and special characters.');
      RAISE;
   
   -- other UTL_FILE exceptions 
   WHEN utl_file.internal_error THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Internal Error. Undefined. No idea what''s wrong. Good luck!');
      RAISE;
   WHEN utl_file.access_denied THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      'Access denied on the file or directory. Check permissions.');
      RAISE;
   WHEN OTHERS THEN
      log_and_cleanup(lr_file_handle,
                      l_proc_nm || ' [' || l_marker || ']',
                      SQLERRM);
      RAISE;
END write_lines;


--------------------------------------------------------------------------------
PROCEDURE rename_file
(
   i_old_file_nm  IN VARCHAR2,
   i_new_file_nm  IN VARCHAR2,
   i_old_file_dir IN VARCHAR2 DEFAULT get_default_dir,
   i_overwrite    IN VARCHAR2 DEFAULT 'N'
)
IS
   l_proc_nm  app_log.routine_nm%TYPE := gc_pkg_nm||'.rename_file';
   l_overwrite BOOLEAN;
BEGIN
   IF (i_overwrite IN ('y','Y','yes','YES','on','ON')) THEN
      l_overwrite := TRUE;
   ELSE
      l_overwrite := FALSE;
   END IF;
   
   IF (file_exists(i_old_file_nm, i_old_file_dir)) THEN
      -- Throws ORA-29292 when overwrite is false, so we will have to prevent
      -- overwrite ourselves.
   
      -- Test for new file first
      IF (file_exists(i_new_file_nm, i_old_file_dir)) THEN
         IF (l_overwrite = FALSE) THEN
            raise_application_error(-20000,
                                    'ERROR: Cannot rename file [' ||
                                    i_old_file_nm || '], as [' || i_new_file_nm ||
                                    '] already exists in directory [' ||
                                    i_old_file_dir || '].');
         ELSE
            utl_file.frename(i_old_file_dir,
                             i_old_file_nm,
                             i_old_file_dir,
                             i_new_file_nm,
                             l_overwrite);

            app_log_api.ins('File Rename Request. Location ['||i_old_file_dir||'] '||
               'OLD['||i_old_file_nm||'] '||
               'NEW['||i_new_file_nm||']',
               cnst.INFO, msgs.DEFAULT_MSG_CD,l_proc_nm);
         END IF;
      ELSE
         utl_file.frename(i_old_file_dir,
                          i_old_file_nm,
                          i_old_file_dir,
                          i_new_file_nm,
                          l_overwrite);
      END IF;
   
   ELSE
      -- Consider a raw call to send this line to the logs. For most applications
      -- I'm sure they won't care if the file is not there, kind of like the
      -- Oracle "error" that isn't an error when you try to pre-emptively drop
      -- a table that doesn't exist. 
      raise_application_error(-20000,
                              'ERROR: Cannot rename file [' || i_old_file_nm ||
                              '], as it does not exist in directory [' ||
                              i_old_file_dir || '].');
   END IF;
END rename_file;

--------------------------------------------------------------------------------
PROCEDURE delete_file
(
   i_file_nm       IN  VARCHAR2
,  i_file_dir      IN  VARCHAR2 DEFAULT get_default_dir
)
IS
   l_proc_nm  app_log.routine_nm%TYPE := gc_pkg_nm||'.delete_file';
BEGIN
   IF (file_exists(i_file_nm, i_file_dir)) THEN
      utl_file.fremove(i_file_dir, i_file_nm);
      app_log_api.ins('File Delete Request. Location ['||i_file_dir||'] '||
         'File['||i_file_nm||']',
         cnst.INFO, msgs.DEFAULT_MSG_CD,l_proc_nm);
   ELSE
      -- Consider a raw call to send this line to the logs. For most applications
      -- I'm sure they won't care if the file is not there, kind of like the
      -- Oracle "error" that isn't an error when you try to pre-emptively drop
      -- a table that doesn't exist. 
      raise_application_error(-20000,'ERROR: Cannot delete file ['||i_file_nm||
      '] does not exist in directory ['||i_file_dir||'].');   
   END IF;

END delete_file;

--------------------------------------------------------------------------------
PROCEDURE copy_file
(
   i_src_file       IN  VARCHAR2
,  i_dest_file      IN  VARCHAR2
,  i_src_dir        IN  VARCHAR2 DEFAULT get_default_dir
,  i_dest_dir       IN  VARCHAR2 DEFAULT get_default_dir
)
IS
   l_proc_nm  app_log.routine_nm%TYPE := gc_pkg_nm||'.copy_file';
BEGIN
   IF (file_exists(i_src_file, i_src_dir)) THEN
      utl_file.fcopy(i_src_dir, i_src_file, i_dest_dir, i_dest_file);
      app_log_api.ins('File Copy Request. Source Location ['||i_src_dir||'] '||
         'Source File['||i_src_file||'] '||
         'Target Location ['||i_dest_dir||'] '||
         'Target File['||i_dest_file||']',
         cnst.INFO, msgs.DEFAULT_MSG_CD,l_proc_nm);
   ELSE
      -- Consider a raw call to send this line to the logs. For most applications
      -- I'm sure they won't care if the file is not there, kind of like the
      -- Oracle "error" that isn't an error when you try to pre-emptively drop
      -- a table that doesn't exist. 
      raise_application_error(-20000,'ERROR: Cannot copy file ['||i_src_file||
      '] as it does not exist in directory ['||i_src_dir||'].');   
   END IF;
END copy_file;

--------------------------------------------------------------------------------
PROCEDURE move_file
(
   i_src_dir   IN VARCHAR2,
   i_src_file  IN VARCHAR2,
   i_dest_dir  IN VARCHAR2,
   i_dest_file IN VARCHAR2,
   i_overwrite IN VARCHAR2 DEFAULT 'N'
)
IS
   l_proc_nm  app_log.routine_nm%TYPE := gc_pkg_nm||'.move_file';
   l_overwrite BOOLEAN;
BEGIN
   IF (i_overwrite IN ('y','Y','yes','YES','on','ON')) THEN
      l_overwrite := TRUE;
   ELSE
      l_overwrite := FALSE;
   END IF;
   
   IF (file_exists(i_src_file, i_src_dir)) THEN
   
      -- Throws ORA-29292 when overwrite is false, so we will have to prevent
      -- overwrite ourselves.
   
      -- Test for new file first
      IF (file_exists(i_src_file, i_src_dir)) THEN
         IF (l_overwrite = FALSE) THEN
            raise_application_error(-20000,
                                    'ERROR: Cannot rename file [' ||
                                    i_src_file || '], as [' || i_dest_file ||
                                    '] already exists in directory [' ||
                                    i_dest_dir || '].');
         ELSE
            utl_file.frename(i_src_dir,
                             i_src_file,
                             i_dest_dir,
                             i_dest_file,
                             l_overwrite);
            app_log_api.ins('File Move Request. Source Location ['||i_src_dir||'] '||
               'Source File['||i_src_file||'] '||
               'Target Location ['||i_dest_dir||'] '||
               'Target File['||i_dest_file||']',
               cnst.INFO, msgs.DEFAULT_MSG_CD,l_proc_nm);
         END IF;
      ELSE
         utl_file.frename(i_src_dir,
                          i_src_file,
                          i_dest_dir,
                          i_dest_file,
                          l_overwrite);
      END IF;
   
   ELSE
      raise_application_error(-20000,
                              'ERROR: Cannot move file [' || i_src_file ||
                              '], as it does not exist in directory [' ||
                              i_src_dir || '].');
   END IF;

END move_file;

--------------------------------------------------------------------------------
PROCEDURE get_file_props
(
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir,
   ob_exists  OUT BOOLEAN,
   on_length  OUT NUMBER
) IS
   ln_blocksize BINARY_INTEGER; -- will be discarded
   lb_exists BOOLEAN;
BEGIN
   utl_file.fgetattr(i_file_dir, i_file_nm, lb_exists, on_length, ln_blocksize);
   -- This check is necessary because fgetattrs acts differently on 9i and 10g, 
   -- and returns incorrect results if the caller doesn't have read permissions
   -- on the given directory.
   IF (lb_exists IS NULL) THEN
      lb_exists := FALSE;
   ELSIF (lb_exists = FALSE) THEN
      on_length := NULL;
   END IF;
   ob_exists := lb_exists;
END get_file_props;

--------------------------------------------------------------------------------
PROCEDURE p
(
   i_str  IN VARCHAR2, --  will be printed to stdout
   i_str2 IN VARCHAR2 DEFAULT NULL
)
IS
   start_text NUMBER;  -- starting pt of text to print
   end_text   NUMBER;  -- ending pt of text to print
   lentxt     NUMBER;  -- length from logical start to logical end of text
   break_pt   NUMBER;  -- break pt (found whitespace)
   start_next NUMBER;  -- next non-newline char

   TAB   CONSTANT VARCHAR2(1) := CHR(9); -- A single tab character
   CR    CONSTANT VARCHAR2(1) := CHR(13); -- A single carriage return character (^M)
   LF    CONSTANT VARCHAR2(1) := CHR(10); -- A single linefeed character
   SP    CONSTANT VARCHAR2(1) := CHR(32); -- A space
   
BEGIN
   IF (i_str2 IS NOT NULL) THEN
      p(i_str||cnst.SEPCHAR||i_str2);
   ELSE

      start_text := 1;
      LOOP
         end_text := start_text + cnst.PAGEWIDTH - 1;
         lentxt := NVL(LENGTH(SUBSTR(i_str, start_text, cnst.PAGEWIDTH)),0);
   
         IF (lentxt < cnst.PAGEWIDTH) THEN  -- last chunk of text in string
            DBMS_OUTPUT.put_line(SUBSTR(i_str, start_text, lentxt));
            EXIT;  -- and we're done!
         ELSE  -- not done yet so find good break pt
            break_pt := 0;  -- reset
            FOR i IN REVERSE start_text .. end_text LOOP
               IF (SUBSTR(i_str, i, 1) IN (CR, LF, SP, TAB)) THEN
                  break_pt := i;  -- found suitable break pt
                  EXIT;
               END IF;
            END LOOP;  -- find break pt
   
            IF (break_pt = 0) THEN  -- no suitable break pt found!
               DBMS_OUTPUT.put_line(SUBSTR(i_str, start_text, cnst.PAGEWIDTH));
               start_text := end_text + 1;  -- next start pt
            ELSE  -- print to just before break pt
               DBMS_OUTPUT.put_line(SUBSTR(i_str, start_text, break_pt-start_text));
               start_next := 0;  -- reset
   
               FOR i IN break_pt .. end_text LOOP  -- find next non-newline char
                  IF (SUBSTR(i_str, i, 1) NOT IN (CR, LF)) THEN
                    start_next := i;
                    EXIT;
                  END IF;
               END LOOP;  -- find next non-newline char
   
               IF (start_next = 0) THEN  -- no non-newline char found
                  start_text := end_text + 1;
               ELSE
                  start_text := start_next;  -- start at non-newline char found
               END IF;
            END IF;  -- break pt?
         END IF;  -- last chunk?
      END LOOP;  -- print long string
   END IF; -- print tag/value pair, or long string?
EXCEPTION
WHEN OTHERS THEN
   BEGIN
      DBMS_OUTPUT.put_line('io.p ERROR: ' || SQLERRM(SQLCODE));
   EXCEPTION
   WHEN OTHERS THEN
      NULL;  -- don't care
   END;
END p;

--------------------------------------------------------------------------------
PROCEDURE p
(
   i_date IN DATE, --  will be printed to stdout, using format
   i_fmt  IN VARCHAR2 DEFAULT dt.DTM_MASK
   
)
IS
BEGIN
   p(TO_CHAR(i_date,i_fmt));
END p;

--------------------------------------------------------------------------------
PROCEDURE p
(
   i_num  IN NUMBER, --  will be printed to stdout, using format
   i_fmt  IN VARCHAR2 DEFAULT num.FLOAT_MASK
)
IS
BEGIN
   p(TO_CHAR(i_num,i_fmt));
END p;

--------------------------------------------------------------------------------
PROCEDURE p
(
   i_bool  IN BOOLEAN --  will be converted to "TRUE", "FALSE" or NULL
)
IS
BEGIN
   p(bool_to_str(i_bool));
END p;

--------------------------------------------------------------------------------
PROCEDURE p
(
   i_str  IN VARCHAR2, --  used as label, preceding date value
   i_date IN DATE,
   i_fmt  IN VARCHAR2 DEFAULT dt.DTM_MASK
)
IS
BEGIN
   p(i_str||cnst.SEPCHAR||TO_CHAR(i_date,i_fmt));
END p;

--------------------------------------------------------------------------------
PROCEDURE p
(
   i_str  IN VARCHAR2, --  used as label, preceding numeric value
   i_num  IN NUMBER,  
   i_fmt  IN VARCHAR2 DEFAULT num.FLOAT_MASK
)
IS
BEGIN
   p(i_str||cnst.SEPCHAR||TO_CHAR(i_num,i_fmt));
END p;

--------------------------------------------------------------------------------
PROCEDURE p
(
   i_str  IN VARCHAR2, --  used as label, preceding boolean (string) value
   i_bool IN BOOLEAN --  will be converted to "TRUE", "FALSE" or NULL
)
IS
BEGIN
   p(i_str||cnst.SEPCHAR||bool_to_str(i_bool));
END p;

--------------------------------------------------------------------------------
--                  PACKAGE INITIALIZATIOINS (RARELY USED)
--------------------------------------------------------------------------------
BEGIN
   g_default_dir := parm.get_val('Default IO Directory');
   g_default_filename := parm.get_val('Default IO File Name');
   
END io;
/
