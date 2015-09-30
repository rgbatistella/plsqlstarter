CREATE OR REPLACE PACKAGE io
   AUTHID CURRENT_USER
/*******************************************************************************
%author
 Bill Coulam (bcoulam@dbartisans.com)

 A collection of routines related to reading and writing files on the DB host
 operating system.
 
%design
 Meant to be the interface to the world outside Oracle. To begin with this
 package will only contain routines that read and write to files, and write to
 stdout. As things progress, there may be other needs, perhaps writing to
 C-based pipes, JMS-based message queues, UDP-speaking sockets, etc.
 Any interfaces out of Oracle to those devices should be placed in this package.

%prereq
 This package will not function at all, unless you have a "Default IO Directory"
 and "Default IO File Name" parameter defined for each application. See the {%link 
 parms} package and its documentation for how this is accomplished.

%future
 Routines to read and write BLOB columns from and to binary files.<br>
 Routines to read and write Unicode data.<br>
 Routine to receive an array of lines and write them before flush and close.<br>
 Routine to read all lines from a file and return an array.<br>
 Routine to read all lines within a given range. Optional parameter to exclude 
 certain lines.<br>

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008Jan13 Moved the default directory function from package "C" to 
                       here.
bcoulam      2008Feb05 Added a few functions and simplified others.
bcoulam      2008May07 Added convert_file_to_blob

</pre>

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
gx_file_already_exists EXCEPTION;

MAX_FILE_LINE_LEN CONSTANT INTEGER := 32767; -- as of 9i

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_default_dir:
 Returns default directory used for file operations on the DB host system.

%return
 The default directory name. This is a 9i-style Oracle DIRECTORY object.
------------------------------------------------------------------------------*/
FUNCTION get_default_dir RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
set_default_dir:
 Overrides the default directory used for file operations on the DB host system.
 This is useful if you will be a doing a lot of write operations to file and
 don't wish to pass the Directory name in on every call. Routine 
 logs.set_targets uses this procedure for this very reason.

%param i_default_dir The new default directory name. This must be a valid Oracle 
                     DIRECTORY object.
------------------------------------------------------------------------------*/
PROCEDURE set_default_dir (i_default_dir IN VARCHAR2);

/**-----------------------------------------------------------------------------
get_default_filename:
 Returns default filename used for file operations on the DB host system, when
 no other filename is presented by the caller for use.

%return
 The default filename. This is either set up in APP_ENV_PARM, or if not 
 configured, defaults to the calling Application Code (found in APP_VW) +
 the date.
------------------------------------------------------------------------------*/
FUNCTION get_default_filename RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
set_default_filename:
 Overrides default filename used for file operations on the DB host system, when
 no other filename is presented by the caller for use.

%param i_default_filename The new default filename. This must be a valid filename
                          plus extension, e.g. myapp.log
------------------------------------------------------------------------------*/
PROCEDURE set_default_filename (i_default_filename IN VARCHAR2);

/**-----------------------------------------------------------------------------
file_exists:
 Uses utl_file.fgetattr to determine if a file exists.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ privilege to the directory.<br>

%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                 use spaces and special characters (except underscore) unless 
                 necessary. If you do, be sure to test well.

%param i_file_dir If not provided, the file will be written to the default IO
                  directory. If you specify a directory, it must already exist 
                  and have proper permissions set up. Don't end this string in
                  a slash.

%return
 {*} TRUE If the file exists.
 {*} FALSE If the file cannot be found in the directory specified, and/or by the
       filename given. 
------------------------------------------------------------------------------*/
FUNCTION file_exists
(
   i_file_nm  IN VARCHAR DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN BOOLEAN;

/**-----------------------------------------------------------------------------
file_length_lines:
 Returns the number of lines in the given file.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ privilege to the directory.<br>

%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                 use spaces and special characters (except underscore) unless 
                 necessary. If you do, be sure to test well.

%param i_file_dir If not provided, the file will be written to the default IO
                  directory. If you specify a directory, it must already exist 
                  and have proper permissions set up. Don't end this string in
                  a slash.

%return
 {*} 0 If the file exists, but has no lines.
 {*} # Number of lines in the file.

%raises
 UTL_FILE.INVALID_FILENAME Invalid filename. Check spelling.<br>
 UTL_FILE.INVALID_PATH Invalid path. Checking spelling and existence of directory.<br>
 UTL_FILE.INVALID_OPERATION Invalid operation.<br>
 UTL_FILE.READ_ERROR Read error.<br>
 UTL_FILE.ACCESS_DENIED Access denied.<br>
------------------------------------------------------------------------------*/
FUNCTION file_length_lines
(
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN INTEGER;

/**-----------------------------------------------------------------------------
file_length_bytes:
 Uses utl_file.fgetattr to determine file length in terms of bytes. You may want
 to call io.file_exists before calling this function to ensure the named file 
 can be found.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ privilege to the directory.<br>

%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                 use spaces and special characters (except underscore) unless 
                 necessary. If you do, be sure to test well.

%param i_file_dir If not provided, the file will be written to the default IO
                  directory. If you specify a directory, it must already exist 
                  and have proper permissions set up. Don't end this string in
                  a slash.

%return
 Returns the length of the file in bytes.<br>
 Returns 0 if the file does not exist.<br>
------------------------------------------------------------------------------*/
FUNCTION file_length_bytes
(
   i_file_nm  IN VARCHAR DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN NUMBER;

/**-----------------------------------------------------------------------------
read_line:
 Reads a line from the given file. The most useful part of this function is the
 fact that it is a function, rather than a procedure with OUT parameters requiring
 further interpretation. If you know the exact line that you want, you just call 
 this function and the result is immediately useable through the VARCHAR2
 return value.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ privilege to the directory.<br>

%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                 use spaces and special characters (except underscore) unless 
                 necessary. If you do, be sure to test well.
                  
%param i_file_dir If not provided, the file will be written to the default IO
                  directory. If you specify a directory, it must already exist 
                  and have proper permissions set up. Don't end this string in
                  a slash.

%param i_line_num The line number desired. This will default to the first line
                  if not specified.
 
%usage
 read_line would generally be called after an initial call to get_num_lines().
 The caller could then read one line at a time in a FOR LOOP going from
 1..num_lines. This is rather inefficient, but provided by the IO API anyway.

%return
 Requested line from the named file.                   
------------------------------------------------------------------------------*/
FUNCTION read_line
(
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_line_num IN INTEGER DEFAULT 1,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
convert_file_to_blob:
 Reads a file from the filesystem and places the bytes into a BLOB that can
 then be manipulated like other LOBs.

%prereq
 The directory and file need to exist.<br>
 The user must have been granted READ and WRITE privilege to the directory.<br>

%usage
 <code>
   UPDATE app_email_doc
      SET doc_content = io.convert_file_to_blob('incoming_ids.xls')
    WHERE email_doc_id = 64;
 </code>
 
%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                  use spaces and special characters (except underscore) unless 
                  necessary. If you do, be sure to test well.
                  
%param i_file_dir If not provided, the file will be written to the default IO
                   directory. If you specify a directory, it must already exist 
                   and have proper permissions set up. Don't end this string in
                   a slash.
%return
 Content of the file, written within a BLOB.
------------------------------------------------------------------------------*/
FUNCTION convert_file_to_blob
(
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
) RETURN BLOB;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
write_line:
 Core routine for writing output to files. Defaults to Append mode, creating the
 given file if it doesn't already exist. Change mode to [W]rite mode if you wish
 to overwrite an existing file.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ and WRITE privilege to the directory.<br>

%usage
 <code>
   io.write_line(msgs.get_msg('Invalid Operation'),'myapp.log');

%warn
 This routine is kept dumb on purpose. It simply does what it is told. Any 
 intelligence or business logic around filenames, lengths, directories, log 
 formats, etc. must be handled earlier by higher layers.

 The innards of write_line is misbehaving. It adds an empty line at the end of 
 the file. I haven't had time to find out why yet.

%param i_msg Line or string to write to file. Must be less than 32K.
%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                  use spaces and special characters (except underscore) unless 
                  necessary. If you do, be sure to test well.
                  
%param i_file_dir If not provided, the file will be written to the default IO
                   directory. If you specify a directory, it must already exist 
                   and have proper permissions set up. Don't end this string in
                   a slash.
%param i_mode File write mode. Must be w, W, a or A.
------------------------------------------------------------------------------*/
PROCEDURE write_line
(
   i_msg      IN VARCHAR2,
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir,
   i_mode     IN VARCHAR2 DEFAULT 'A'
);

/**-----------------------------------------------------------------------------
write_lines:
 Secondary routine for writing output to files. Defaults to Append mode, creating
 the given file if it doesn't already exist. Change mode to [W]rite mode if you
 wish to overwrite an existing file. Use this routine when file writing needs to
 be optimized. The file is only opened once, and all lines in the i_msgs array 
 are written, then the file is closed (as opposed to opening and closing for 
 each call to write_line).

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ and WRITE privilege to the directory.<br>

%usage
 <code>
 DECLARE
    l_msg_array typ.tas_maxvc2;
 BEGIN
    l_msg_array(1) := 'This is the first line of text.';
    l_msg_array(2) := 'This is the second line of text.';
    l_msg_array(3) := msgs.get_msg('Invalid Operation');
    io.write_lines(l_msg_array,'myapp.log');
 END;

%warn
 This routine is kept dumb on purpose. It simply does what it is told. Any 
 intelligence or business logic around filenames, lengths, directories, log 
 formats, etc. must be handled earlier by higher layers.

%param i_msg Line or string to write to file. Must be less than 32K.
%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                  use spaces and special characters (except underscore) unless 
                  necessary. If you do, be sure to test well.
                  
%param i_file_dir If not provided, the file will be written to the default IO
                   directory. If you specify a directory, it must already exist 
                   and have proper permissions set up. Don't end this string in
                   a slash.
%param i_mode File write mode. Must be w, W, a or A.
------------------------------------------------------------------------------*/
PROCEDURE write_lines
(
   i_msgs     IN typ.tas_maxvc2,
   i_file_nm  IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir,
   i_mode     IN VARCHAR2 DEFAULT 'A'
);

/**-----------------------------------------------------------------------------
rename_file:
 Overlay for UTL_FILE.frename, just so this package is complete. This routine
 assumes that the rename operation is desired in the same directory as the source
 file. If you wish to both rename the file and move it to a different directory, use
 io.move_file() instead.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ and WRITE privilege to the directory.<br>

%note
 This routine will raise an error if there is already a file with the new file 
 name, or if the old file name cannot be found.

%usage
 <code>
   BEGIN
      io.rename_file('old_file.txt','new_file.txt');
   END;
   
%param i_old_file_nm Name of the file to rename.

%param i_new_file_nm Desired name for the renamed file.

%param i_old_file_dir Location of the file to be renamed.

%param i_overwrite Set to 'Y' if you wish the rename operation to overwrite
                   any existing file that has the new file name.
------------------------------------------------------------------------------*/
PROCEDURE rename_file
(
   i_old_file_nm  IN VARCHAR2,
   i_new_file_nm  IN VARCHAR2,
   i_old_file_dir IN VARCHAR2 DEFAULT get_default_dir,
   i_overwrite    IN VARCHAR2 DEFAULT 'N'
);

/**-----------------------------------------------------------------------------
delete_file:
Overlay for UTL_FILE.fremove. Deletes the given file from the underlying file
system.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ and WRITE privilege to the directory.<br>

%warn
 Will mute the error if the file does not exist in the given location, so be 
 sure to give valid values for both parameters.

%param i_file_nm The filename must be a valid filename for your DB OS. Don't 
                 use spaces and special characters (except underscore) unless 
                 necessary. If you do, be sure to test well.

%param i_file_dir If not provided, the file will be written to the default IO
                  directory. If you specify a directory, it must already exist 
                  and have proper permissions set up. Don't end this string in
                  a slash.

------------------------------------------------------------------------------*/
PROCEDURE delete_file
(
   i_file_nm  IN VARCHAR2,
   i_file_dir IN VARCHAR2 DEFAULT get_default_dir
);

/**-----------------------------------------------------------------------------
copy_file:
Copies a file. The source and destination directory can be the same, but the file
name would have to be different.

%prereq
 The directories needs to exist.<br>
 The user must have been granted READ and WRITE privilege to the directory.<br>

%note
 This wrapper of UTL_FILE ignores the capability of copying only a portion of the
 source file to a destination file. If that is desired, augment this routine
 with a few more parameters to specify the begin and end lines.

%usage
 <code>
   BEGIN
      --- source and destination directories are the same
      io.copy_file('load.log','2007-07-18_load.log');
      --- source and destination directories differ
      io.copy_file('error.log','2007-06-01_error.log','ERR_DIR','ERR_HIST');
   END;

%param i_src_file Name of the file to be copied.
%param i_dest_file The desired name of the copied file. 
%param i_src_dir The location of the file to be copied.
%param i_dest_dir The desired location of the copied file.
   
------------------------------------------------------------------------------*/
PROCEDURE copy_file
(
   i_src_file  IN VARCHAR2,
   i_dest_file IN VARCHAR2,
   i_src_dir   IN VARCHAR2 DEFAULT get_default_dir,
   i_dest_dir  IN VARCHAR2 DEFAULT get_default_dir
);

/**-----------------------------------------------------------------------------
move_file:
Moves the given file from one location to another. You may also rename the file
during the move operation. If all you need to do is rename a file in-place, use
rename_file() instead.

%prereq
 The directories needs to exist.<br>
 The user must have been granted READ and WRITE privilege to the directory.<br>

%raises
 IO.gx_file_already_exists If the destination file already exists and the 
                           overwrite parameter is FALSE.
 
%param i_src_dir The location of the file to move.
%param i_src_file The name of the file to move.
%param i_dest_dir The target location of the move operation.
%param i_dest_file The name the file should have in the target location after 
                   the move operation is complete.
%param i_overwrite Y allows a file in the destination with the same name to be
                   overwritten. N does not permit an overwrite.
------------------------------------------------------------------------------*/
PROCEDURE move_file
(
   i_src_dir   IN VARCHAR2,
   i_src_file  IN VARCHAR2,
   i_dest_dir  IN VARCHAR2,
   i_dest_file IN VARCHAR2,
   i_overwrite IN VARCHAR2 DEFAULT 'N'
);


/**-----------------------------------------------------------------------------
get_file_props:
 Determines whether a given file exists and how long it is.

%prereq
 The directory needs to exist.<br>
 The user must have been granted READ privilege to the directory.<br>

%param i_file_nm The name of the file whose properties are desired.
%param i_file_dir The location of the file.
%param ob_exists TRUE if file exists, FALSE if not.
%param on_length Length of the file (in bytes). If KB, MB or other such measure
                 is desired, convert using powers of 2. This value will be NULL
                 if the file does not exist.

------------------------------------------------------------------------------*/
PROCEDURE get_file_props
(
   i_file_nm IN VARCHAR2 DEFAULT get_default_filename,
   i_file_dir  IN VARCHAR2 DEFAULT get_default_dir,
   ob_exists OUT BOOLEAN,
   on_length OUT NUMBER -- null if file didn't exist
);


/**-----------------------------------------------------------------------------
p[rint]:
 Prints characters to stdout (SQL*Plus consolue, Unix console, stdout redirected
 to file, etc.)

 The first incarnation of the p() routine, which only takes one or (optional) 
 two strings, is the base version called by all the others. It was designed to 
 handle character strings longer than 255 chars by breaking it up, based on the 
 default pagewidth set in the C package.
  
 If this is being compiled on 10gR2, 255 is no longer a hard limit for 
 dbms_output, but lines longer than 80-100 characters wide are still difficult 
 to read. So we recommend sticking with the default of 80 as a width.

 Note: 10g and newer Oracle still restricts lines to less than 32K characters.

 The remaining versions of [p]rint were designed (1) for type-overridden name 
 consistency so a whole API didn't need to be learned, (2) to be a whole lot 
 shorter to type than "dbms_output.put_line" and (3) to simplify some common 
 uses for dbms_output.

%warn
 The tag versions of p() (those that are str/date, str/num and str/bool) were NOT
 designed to handle large VARCHAR2 values. The i_str parameter in those versions
 of p() are meant only for short tags to highlight, group and offset the message.

 This is very useful for manual debugging, showing the name of a variable, then 
 showing the variable's value. The p() routine eliminates a little extra typing 
 by taking care of the concatenations for you.

%usage
 <code> 
   io.p('i_my_date',i_my_date); 
               VS.
   dbms_output.put_line('i_my_date'||' : '||i_my_date);
------------------------------------------------------------------------------*/
PROCEDURE p
(
   i_str  IN VARCHAR2, -- will be printed to stdout
   i_str2 IN VARCHAR2 DEFAULT NULL
);
PROCEDURE p
(
   i_date IN DATE, -- will be printed to stdout, using given format
   i_fmt  IN VARCHAR2 DEFAULT dt.DTM_MASK
);
PROCEDURE p
(
   i_num IN NUMBER, -- will be printed to stdout, using format
   i_fmt IN VARCHAR2 DEFAULT num.FLOAT_MASK
);
PROCEDURE p
(
   i_bool IN BOOLEAN -- will be converted to "TRUE", "FALSE" or NULL for printout
);
PROCEDURE p
(
   i_str  IN VARCHAR2, -- used as label, preceding date value
   i_date IN DATE,
   i_fmt  IN VARCHAR2 DEFAULT dt.DTM_MASK
);
PROCEDURE p
(
   i_str IN VARCHAR2, -- used as label, preceding numeric value
   i_num IN NUMBER,
   i_fmt IN VARCHAR2 DEFAULT num.FLOAT_MASK
);
PROCEDURE p
(
   i_str  IN VARCHAR2, -- used as label, preceding boolean (string) value
   i_bool IN BOOLEAN -- will be converted to "TRUE", "FALSE" or NULL for printout
);


END io;
/
