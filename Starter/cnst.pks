CREATE OR REPLACE PACKAGE cnst
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Groups together very generic constants, and functions that act as constants. 

%warn
 Any constant specific to a domain, should be placed in the public specification
 of a package dedicated to that domain, thus reducing coupling and dependency 
 upon a central constants/literals package like this one.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2004Jul02 Revamped comments. Added numeric TRUE/FALSE for
                       use by binary functions in SQL statements.
bcoulam      2008Jan13 Moved message type constants to MSG pkg spec.                       
                             
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
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

-- Lengths
PAGEWIDTH   CONSTANT INTEGER := 80;
MAX_COL_LEN CONSTANT INTEGER := 4000;
MAX_VC2_LEN CONSTANT INTEGER := 32767;

-- Basic return codes, following the Unix convention of non-zero indicating failure
SUCCESS CONSTANT PLS_INTEGER := 0;
FAILURE CONSTANT PLS_INTEGER := 1;

-- Basic numeric represenation of boolean values, following the conventions found
-- in C and other languages, where true=1 and false=0.
TRUE CONSTANT PLS_INTEGER := 1; 
FALSE CONSTANT PLS_INTEGER := 0;

-- Basic values for flag columns. These are preferred over 1's and 0's because
-- their meaning is instantly clear. If 1's and 0's are needed for SQL against
-- a table with numeric flags, use DECODE to map Y/N to 1/0.
YES CONSTANT VARCHAR2(1) := 'Y'; -- used for *_flg columns
NO CONSTANT VARCHAR2(1) := 'N'; -- used for *_flg columns

-- Message/log severity codes
ERROR CONSTANT VARCHAR2(10) := 'ERROR';
WARN  CONSTANT VARCHAR2(10) := 'WARN';
INFO  CONSTANT VARCHAR2(10) := 'INFO';
AUDIT CONSTANT VARCHAR2(10) := 'AUDIT';
DEBUG  CONSTANT VARCHAR2(10) := 'DEBUG';

-- System-wide symbols, strings and tokens
SEPCHAR CONSTANT VARCHAR2(2) := ': ';
PIPECHAR CONSTANT VARCHAR2(1) := '|';
DELIMITER CONSTANT VARCHAR2(1) := ',';
DIR_SEPCHAR CONSTANT VARCHAR2(1) := '/'; -- change to "\" for Windows OS

-- Substitution character. Strings that requires substitution/replacement at
-- runtime will be wrapped in this character. This is used mainly by the MSGS
-- library in its operations upon standard messages with placeholders in APP_MSG.
SUBCHAR CONSTANT VARCHAR2(1) := '@';

-- Other generic strings
UNKNOWN CONSTANT VARCHAR2(1) := 'U';
UNKNOWN_USER CONSTANT VARCHAR2(10) := 'UNKNOWN';
UNKNOWN_STR CONSTANT VARCHAR2(10) := 'Unknown';

----------------------------------------------------------------------
-- Pragma needed for the whole package (not needed for >= 9i)
--PRAGMA RESTRICT_REFERENCES
--   (cnst, WNDS, WNPS, RNDS);
   
END cnst;
/
