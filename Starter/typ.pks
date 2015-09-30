CREATE OR REPLACE PACKAGE typ
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Collection of application specific PL/SQL table types and user-defined
 types (subtypes, records and tables of records).

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2004Jul22 Updated and simplified

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
-- Subtypes
SUBTYPE t_maxobjnm IS VARCHAR2(30); -- maxlength for normal Oracle object name
SUBTYPE t_maxfqnm  IS VARCHAR2(61); -- fqnm = fully qualified name
SUBTYPE t_maxcol IS VARCHAR2(4000);
SUBTYPE t_maxvc2 IS VARCHAR2(32767);
SUBTYPE t_msg    IS t_maxcol;
SUBTYPE t_rc     IS PLS_INTEGER;

SUBTYPE t_mime_type IS VARCHAR2(100); -- used by MAIL and UTILS

-- used by ENV to avoid dependence on v$ performance views that might not be 
-- available to all framework champions.
SUBTYPE t_module IS VARCHAR2(48);
SUBTYPE t_action IS VARCHAR2(32);
SUBTYPE t_client_id IS VARCHAR2(64);
SUBTYPE t_instance_nm IS VARCHAR2(16);
SUBTYPE t_host_nm IS VARCHAR2(64);

--------------------------------------------------------------------------------
-- PL/SQL associative arrays
TYPE tab        IS TABLE OF BOOLEAN        INDEX BY BINARY_INTEGER;
TYPE tad        IS TABLE OF DATE           INDEX BY BINARY_INTEGER;
TYPE tan        IS TABLE OF NUMBER         INDEX BY BINARY_INTEGER;
TYPE tas_small  IS TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
TYPE tas_medium IS TABLE OF VARCHAR2(255)  INDEX BY BINARY_INTEGER;
TYPE tas_large  IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
TYPE tas_maxcol IS TABLE OF t_maxcol       INDEX BY BINARY_INTEGER;
TYPE tas_maxvc2 IS TABLE OF t_maxvc2       INDEX BY BINARY_INTEGER;

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
Empty instances of the generic associative array types defined above
These are to be used in 9iAS PL/SQL-web parameter lists as default values
------------------------------------------------------------------------------*/
gab        tab;
gad        tad;
gan        tan;
gas_small  tas_small;
gas_medium tas_medium;
gas_large  tas_large;
gas_maxcol tas_maxcol;
gas_maxvc2 tas_maxvc2;

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

END typ;
/
