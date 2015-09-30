CREATE OR REPLACE PACKAGE codes
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 This package contains simple functions that retrieve further info on table-
 based codes within the system.
 
%design
 Most systems use various codes to classify, type and tag records and 
 attributes. These codes are grouped into related sets. Common examples would be 
 Status Codes, Priority IDs, Activity Codes, etc. An entire related set is often 
 needed to populate drop-down listboxes and other visual controls.

 In good data modeling, a given child table should be constrained to only those 
 codes within a certain set. This dictates a table-per-set approach, and is the 
 best for performance and data integrity reasons. These are referred to as 
 "type", "reference" or "lookup" tables. However, this can lead to several 
 hundred reference tables in complex systems, many of them with only a few rows. 
 Such a large number of moving parts is distasteful to some, especially less 
 sophisticated front-end developers who find themselves creating a new class for 
 each reference table. So in several shops, a single code table approach is 
 often begged-for or demanded, despite the best intentions of the data architect.
 For these folks, for more trivial systems, or systems where the users are 
 constrained on the front end (so that incorrect codes from unrelated systems 
 are impossible to select), it is somewhat OK to use a single table for all codes 
 and codesets within the application. This package, along with the APP_CODE and 
 APP_CODESET tables, implements just such an approach. Using the code_id PK, one 
 can at least constrain child tables to only allow valid values from APP_CODE, 
 but I know of no way to constrain the child tables to only certain codes within 
 a codeset, without sticking the codeset_id on every child table as well.
 
 So given that background, if you decide to use the single code table approach,
 when you come up with a new set of lookup codes, create a codeset row in 
 APP_CODESET, then define its codes in APP_CODE. If you ever have a need to
 group codes within a codeset, say civil and criminal case codes within a larger
 legal code codeset, use the hierarchical columns: APP_CODE.PARENT_CODE_ID or
 APP_CODESET.PARENT_CODESET_ID, depending on your needs. If you use hierarchical
 sets or codes, you will need to query APP_CODE_HIER_VW.

 
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

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_code_defn:
 Given a codeset (some refer to it as a code group or category or type) and the
 code itself, returns the code's full meaning/display string. Since a given code
 name could be found multiple times within the APP_CODE table, it must be
 accompanied by the codeset name in order to find its unique entry.

%warn
 The value returned could be either a number, date or string. The caller
 must be aware of what type it expects to get back and perform any necessary
 explicit conversions.

%note
 If the value is a date string, then the caller must also be aware of
 the format required to convert it. Look at the value in APP_CODE to determine 
 the format necessary. The format should be available in the DT package spec.
------------------------------------------------------------------------------*/
FUNCTION get_code_defn
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE
,  i_code_val IN app_code.code_val%TYPE
)  RETURN app_code.code_defn%TYPE;

/**-----------------------------------------------------------------------------
get_code_defn:
 Overloaded so we can look up the definition by code_id as well.
------------------------------------------------------------------------------*/
FUNCTION get_code_defn
(
   i_code_id IN app_code.code_id%TYPE
)  RETURN app_code.code_defn%TYPE;

/**-----------------------------------------------------------------------------
get_code_id:
 Given a codeset (some refer to it as a code group or category or type) and the
 code itself, returns the code's underlying ID.
------------------------------------------------------------------------------*/
FUNCTION get_code_id
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE
,  i_code_val IN app_code.code_val%TYPE
)  RETURN app_code.code_id%TYPE;

/**-----------------------------------------------------------------------------
get_code_val:
 Return the actual code given the surrogate code ID.
------------------------------------------------------------------------------*/
FUNCTION get_code_val
(
   i_code_id IN app_code.code_id%TYPE
)  RETURN app_code.code_val%TYPE;

/**-----------------------------------------------------------------------------
get_codeset_id:
 Return the surrogate codeset ID given the name of the codeset.
------------------------------------------------------------------------------*/
FUNCTION get_codeset_id
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE
) RETURN app_codeset.codeset_id%TYPE;

/**-----------------------------------------------------------------------------
get_codeset_nm:
 Return the codeset name given the ID of the codeset.
------------------------------------------------------------------------------*/
FUNCTION get_codeset_nm
(
   i_codeset_id IN app_codeset.codeset_id%TYPE
) RETURN app_codeset.codeset_nm%TYPE;

/**-----------------------------------------------------------------------------
get_parent_codeset_id:
 Return the parent codeset ID given the ID of the child codeset.
------------------------------------------------------------------------------*/
FUNCTION get_parent_codeset_id
(
   i_codeset_id IN app_codeset.codeset_id%TYPE
) RETURN app_codeset.parent_codeset_id%TYPE;

/**-----------------------------------------------------------------------------
get_codeset_cur:
 Return list of codes within a named codeset. This is useful for populating
 drop-down listboxes.

Currently the signature of the ref cursor returns rows with the columns:
  code_id
  code_val
  code_defn - will not show unless i_return_defn is set to TRUE
------------------------------------------------------------------------------*/
FUNCTION get_codeset_cur
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE,
   i_return_defn IN BOOLEAN DEFAULT FALSE
) RETURN SYS_REFCURSOR;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------


END codes;
/
