CREATE OR REPLACE PACKAGE util                           
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Container for generic utility routines that don't fit anywhere else. These
 should be very low level routines. Any utility with higher level business
 logic or purpose should go in its own package. This package should be pinned
 into the SGA.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2008May02 Added get_mime_type.

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
-- {%skip}
-- Top-level Oracle object types
gc_table      CONSTANT user_objects.object_type%TYPE := 'TABLE';
gc_index      CONSTANT user_objects.object_type%TYPE := 'INDEX';
gc_package    CONSTANT user_objects.object_type%TYPE := 'PACKAGE';
gc_sequence   CONSTANT user_objects.object_type%TYPE := 'SEQUENCE';
gc_synonym    CONSTANT user_objects.object_type%TYPE := 'SYNONYM';
gc_trigger    CONSTANT user_objects.object_type%TYPE := 'TRIGGER';
gc_view       CONSTANT user_objects.object_type%TYPE := 'VIEW';
gc_type       CONSTANT user_objects.object_type%TYPE := 'TYPE';

-- {%skip}
-- Should be a top-level type since they play in the same namespace as tables
-- and such, but they are not found in user_objects.
gc_constraint CONSTANT user_objects.object_type%TYPE := 'CONSTRAINT';


-- {%skip}
-- Low-level "attributes" contained inside top-level objects. There can be more
-- than one of each named attribute across the top-level objects.
gc_column     CONSTANT VARCHAR2(20) := 'COLUMN';
gc_attribute  CONSTANT VARCHAR2(20) := 'ATTRIBUTE';
gc_method     CONSTANT VARCHAR2(20) := 'METHOD';
gc_routine    CONSTANT VARCHAR2(20) := 'ROUTINE';
gc_part       CONSTANT VARCHAR2(20) := 'PARTITION';
gc_subpart    CONSTANT VARCHAR2(20) := 'SUBPARTITION';

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
bool_to_str:
 Converts a PL/SQL Boolean value to "TRUE", "FALSE" or "NULL".
------------------------------------------------------------------------------*/
FUNCTION bool_to_str(i_bool_val IN BOOLEAN) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
bool_to_num:
 Converts a PL/SQL Boolean value to 1, 0 or NULL.
------------------------------------------------------------------------------*/
FUNCTION bool_to_num(i_bool_val IN BOOLEAN) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
str_to_bool:
 Converts a string value to PL/SQL Boolean TRUE or FALSE.
 
%param i_str A character or string that represents true or false. Valid values are:
             {*} TRUE: true, TRUE, t, T, y, Y, yes, YES, 1
             {*} FALSE: false, FALSE, f, F, n, N, no, NO, 0
             {*} NULL: empty string or NULL
------------------------------------------------------------------------------*/
FUNCTION str_to_bool(i_str IN VARCHAR2) RETURN BOOLEAN;

/**-----------------------------------------------------------------------------
num_to_bool:
 Converts a numeric value to PL/SQL boolean TRUE or FALSE.
 
%param i_str A number that represents true or false. Valid values are:
             {*} 1 and non-zero (will return TRUE)
             {*} 0 or NULL (will return FALSE)
------------------------------------------------------------------------------*/
FUNCTION num_to_bool(i_num IN NUMBER) RETURN BOOLEAN;

/**-----------------------------------------------------------------------------
ifnn:
 Function to perform inline if not null/then/else, giving more flexibility and enabling
 more elegant code. Overloaded to accommodate strings, dates and numbers.

%param   i_if   Data to check if it is not null
%param   i_then Data to return if first parameter is not null
%param   i_else Data to return if first parameter is null. If left NULL, NULL
                will be returned if the i_if parameter is NULL.
------------------------------------------------------------------------------*/
FUNCTION ifnn (
 i_if   IN VARCHAR2
,i_then IN VARCHAR2
,i_else IN VARCHAR2 DEFAULT NULL
) RETURN VARCHAR2;

--PRAGMA RESTRICT_REFERENCES(ifnn, WNDS, WNPS, RNDS, RNPS);

FUNCTION ifnn (
 i_if   IN DATE
,i_then IN DATE
,i_else IN DATE DEFAULT NULL
) RETURN DATE;

--PRAGMA RESTRICT_REFERENCES(ifnn, WNDS, WNPS, RNDS, RNPS);

FUNCTION ifnn (
 i_if   IN NUMBER
,i_then IN NUMBER
,i_else IN NUMBER DEFAULT NULL
) RETURN NUMBER;

--PRAGMA RESTRICT_REFERENCES(ifnn, WNDS, WNPS, RNDS, RNPS);

/**-----------------------------------------------------------------------------
ifnull:
 Function to perform inline if null/then/else, giving more flexibility than NVL
 and enabling more elegant code. Overloaded to accommodate strings, dates and numbers.

%param   i_if   Data to check if it is null
%param   i_then Data to return if first parameter is null
%param   i_else Data to return if first parameter is not null. If left NULL,
                NULL will be returned if i_if is NULL. But that behavior makes
                this function equivalent to NVL. So be sure to provide the i_else
                parameter. If you don't need to, use NVL instead. It's probably
                optimized and faster.
------------------------------------------------------------------------------*/
FUNCTION ifnull (
 i_if   IN VARCHAR2
,i_then IN VARCHAR2
,i_else IN VARCHAR2 DEFAULT NULL
) RETURN VARCHAR2;

--PRAGMA RESTRICT_REFERENCES(ifnull, WNDS, WNPS, RNDS, RNPS);

FUNCTION ifnull (
 i_if   IN DATE
,i_then IN DATE
,i_else IN DATE DEFAULT NULL
) RETURN DATE;

--PRAGMA RESTRICT_REFERENCES(ifnull, WNDS, WNPS, RNDS, RNPS);

FUNCTION ifnull (
 i_if   IN NUMBER
,i_then IN NUMBER
,i_else IN NUMBER DEFAULT NULL
) RETURN NUMBER;

--PRAGMA RESTRICT_REFERENCES(ifnull, WNDS, WNPS, RNDS, RNPS);

/**-----------------------------------------------------------------------------
ite:
 Function to perform inline if/then/else, giving more flexibilty and enabling
 more elegant code. Overloaded to accommodate strings, dates and numbers.

%param  i_if   Boolean to test
%param  i_then Data to return if i_if is true
%param  i_else Data to return if i_if is false
------------------------------------------------------------------------------*/
FUNCTION ite (
 i_if   IN BOOLEAN
,i_then IN VARCHAR2
,i_else IN VARCHAR2 DEFAULT NULL
) RETURN VARCHAR2;

--PRAGMA RESTRICT_REFERENCES(ite, WNDS, WNPS, RNDS, RNPS);

FUNCTION ite (
 i_if   IN BOOLEAN
,i_then IN DATE
,i_else IN DATE DEFAULT NULL
) RETURN DATE;

--PRAGMA RESTRICT_REFERENCES(ite, WNDS, WNPS, RNDS, RNPS);

FUNCTION ite (
 i_if   IN BOOLEAN
,i_then IN NUMBER
,i_else IN NUMBER DEFAULT NULL
) RETURN NUMBER;

--PRAGMA RESTRICT_REFERENCES(ite, WNDS, WNPS, RNDS, RNPS);

/**-----------------------------------------------------------------------------
get_mime_type:
 A simple algorithm to determine the MIME type of a file based on the file
 extension. If it cannot be determined, "application/octet-stream" will be returned.

%param i_file_nm A full filename, including extension.
------------------------------------------------------------------------------*/
FUNCTION get_mime_type(i_file_nm IN VARCHAR2) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_otx_doc_type:
 A simple algorithm to determine the Oracle Text document type. Valid values are
 {*} TEXT plain, html, txt, log files, etc.
 {*} BINARY binary documents with text, like Word, PDF, Excel, etc.
 {*} IGNORE binary files with no text, like images
 This determination is based on the MIME type passed in by the caller (which is
 usually determined by called %see util.get_mime_type.
 
%param i_mime_type a valid media MIME type. Pass your file name to util.get_mime_type
                    to have the MIME type determined for you. If the MIME type
                    is not recognized, IGNORE will be returned.
------------------------------------------------------------------------------*/
FUNCTION get_otx_doc_type(i_mime_type IN typ.t_mime_type) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
convert_clob_to_blob:
 Converts data within a CLOB to a BLOB.
 
%param i_clob A valid CLOB locator.
------------------------------------------------------------------------------*/
FUNCTION convert_clob_to_blob(i_clob IN CLOB) RETURN BLOB;

/**-----------------------------------------------------------------------------
convert_blob_to_clob:
 Converts data within a BLOB to a CLOB. The data should be textual or the
 resulting output will be unuseable.
 
%param i_blob A valid BLOB locator.
------------------------------------------------------------------------------*/
FUNCTION convert_blob_to_clob(i_blob IN BLOB) RETURN CLOB;

/**-----------------------------------------------------------------------------
obj_exists:
 Tells you whether a given object exists or not.  The object can be any top-level
 object found in user_objects or user_constraints, and tablespaces.
 
%note
 Since this function looks at user_objects, it will not find "contained" things
 like functions/procedures inside packages, columns in tables, attributes in 
 type specs, etc. To do that, use attr_exists() found further below.
 
%param i_obj_nm   Name of the table, index, etc.

%param i_obj_type Optional parameter to narrow the search and force it to look
                  only for matches of that type.
                  Valid values are:
                  gc_table, gc_index, gc_package, gc_sequence, gc_synonym, gc_trigger
                  gc_view, gc_type, gc_constraint

%return {*}TRUE Object exists in current schema.
        {*}FALSE Object was not found.
------------------------------------------------------------------------------*/
FUNCTION obj_exists
(
   i_obj_nm   IN VARCHAR2,
   i_obj_type IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN;

/**-----------------------------------------------------------------------------
attr_exists:
 Determines whether a contained item, like a column, type attribute or type method,
 is found in the containing object. Defaults to columns since most callers will
 simply want to know if a given column already exists on a table.
 
%return {*}TRUE Attribute exists within the given object.
        {*}FALSE Attribute was not found.
 
%usage
 <code>
 DECLARE
 BEGIN
   IF (NOT util.attr_exists('contracts','active_yn')) THEN
      EXECUTE IMMEDIATE '
         ALTER TABLE contracts
           ADD active_yn VARCHAR2(1)
      ';
   ELSE
      dbms_output.put_line('ACTIVE_YN already exists on CONTRACTS.');
   END IF;
 END;
  
 </code>
                    
%param i_obj_nm  Name of the containing table, package or user-defined type
%param i_attr_nm Name of the attribute whose existence is questioned.
%param i_attr_type The type of the attribute. Defaults to COLUMN if not given.
                   Valid values are:
                   {*} gc_column     For table column
                   {*} gc_attribute  For type attribute
                   {*} gc_method     For type method
                   {*} gc_routine    For packaged functions or procedures
                   {*} gc_part       For table partitions
                   {*} gc_subpart    For table subpartitions
------------------------------------------------------------------------------*/
FUNCTION attr_exists
(
   i_obj_nm    IN VARCHAR2,
   i_attr_nm   IN VARCHAR2,
   i_attr_type IN VARCHAR2 DEFAULT gc_column
) RETURN BOOLEAN;

/**-----------------------------------------------------------------------------
get_max_pk_val:
 Given a table name, retrieves the name of the PK column, and with that queries
 the table for the MAX(pk column) value in the table. This is used by the numerous
 Core triggers to ensure that the next inserted row won't clash with existing
 PK values in the table in case humans have manually inserted values without aid
 of the sequence.
------------------------------------------------------------------------------*/
FUNCTION get_max_pk_val(i_table_nm IN VARCHAR2) RETURN INTEGER;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
reset_seq:
 Attempts to bring a sequence up to where it should be after a data import/
 refresh/migration/conversion.

%design
 This is only designed to work for sequences that support the surrogate PK
 for a single table. Also if the table name isn't provided, the routine
 attempts to derive the table name from the sequence name. It assumes you have
 used one of four conventions to name your sequence: SEQ_TABLE_NAME,
 TABLE_NAME_SEQ, TABLE_NAME_ID_SEQ, SEQ_TABLE_NAME_ID.
 
%param i_seq_nm Name of the sequence to check
%param i_tbl_nm Name of the table for which the sequence provides surrogate
                key values. Required if the table name cannot be derived
                from the sequence name.
------------------------------------------------------------------------------*/
PROCEDURE reset_seq (
   i_seq_nm   IN VARCHAR2,
   i_tbl_nm   IN VARCHAR2 DEFAULT NULL
);

END util;
/
