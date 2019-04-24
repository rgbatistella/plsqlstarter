CREATE OR REPLACE PACKAGE ddl_utils
  AUTHID CURRENT_USER
/**-----------------------------------------------------------------------------
%author Bill Coulam (bcoulam@dbartisans.com)

A collection of routines designed to encapsulate certain queries and operations
frequently repeated in DDL scripts.

%design
Requirements
Self-sufficient.
   It is anticipated that this package will be used in new
   or existing installations where there are no supporting packages, or all
   packages have been dropped or invalidated. This package must be able to 
   compile and run on its own, hence the inclusion of so many private, low-level
   supporting functions.
      
Forgiving.
   The primary reason for writing this package was to allow our
   frequent DDL modification scripts to be re-runnable, where DROP and RENAME
   statements don't spew Oracle errors just because something doesn't exist
   or has already been renamed. In these cases, we want information that the
   item wasn't found, but no error message. This eliminates 1) having to wrap
   DDL in dynamic SQL to avoid the errors (the dynamic SQL is now centralized
   here), and 2) the issues with using SET TERMOUT OFF/ON, which does not work
   when SQL*Plus scripts are nested.
      
Pilot assertions.
   Demonstrate to developers how assertions elegantly enforce
   interface "contracts" and verify assumptions, without having to go
   overboard with exceptions and customized error handling.

%note
 Unless noted otherwise, all parameters that accept Oracle object names are
 case-insensitive.

%prereq
 This package relies heavily on communicating to the end user with 
 dbms_output.put_line. If the caller does not call SET SERVEROUTPUT ON [SIZE 1000000]
 before calling routines in this package (ideally at the top of the master
 script), all the messages will be lost since they are not received from the
 buffer and spooled to stdout. If it doesn't show on stdout, it also won't
 show in any SPOOL log either.

<pre> 
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2007Jan09 Modified to include routines for turning off
                       PARALLEL, turning on LOGGING, and creating private
                       synonyms.
bcoulam      2007Jan16 Modified remove_parallel_all to include exception.
                       Modified output of recompile and turned off verbose
                       output by default.
bcoulam      2008Mar20 Refactored refresh_grants to only grant on objects
                       not already granted.
bcoulam      2008Mar27 Added rename_seq.

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
    
------------------------------------------------------------------------------*/
AS

--------------------------------------------------------------------------------
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

--CURSOR cur_grp_rowids(i_table_name IN VARCHAR2) IS
--   SELECT grp,
--       DBMS_ROWID.rowid_create(1, data_object_id, lo_fno, lo_block, 0) min_rid,
--       DBMS_ROWID.rowid_create(1, data_object_id, hi_fno, hi_block, 10000) max_rid
--   FROM (SELECT DISTINCT grp,
--                        first_value(relative_fno) OVER(PARTITION BY grp ORDER BY relative_fno, block_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) lo_fno,
--                        first_value(block_id) OVER(PARTITION BY grp ORDER BY relative_fno, block_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) lo_block,
--                        last_value(relative_fno) OVER(PARTITION BY grp ORDER BY relative_fno, block_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) hi_fno,
--                        last_value(block_id + blocks - 1) OVER(PARTITION BY grp ORDER BY relative_fno, block_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) hi_block,
--                        SUM(blocks) OVER(PARTITION BY grp) sum_blocks
--          FROM (SELECT relative_fno,
--                       block_id,
--                       blocks,
--                       TRUNC((SUM(blocks)
--                              OVER(ORDER BY relative_fno, block_id) - 0.01) /
--                             (SUM(blocks) OVER() / 12)) grp
--                  FROM dba_extents
--                 WHERE segment_name = UPPER(i_table_name)
--                   AND owner = USER
--                 ORDER BY block_id)),
--       (SELECT data_object_id
--          FROM user_objects
--         WHERE object_name = UPPER(i_table_name)
--       )
--   ORDER BY grp;


--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------

-- collection of rowids for breaking up large DML ops
--TYPE type_grp_rowids_recarr IS TABLE OF cur_grp_rowids%ROWTYPE INDEX BY PLS_INTEGER;

-- associative array of object names
TYPE type_obj_nm_arr IS TABLE OF CHAR(1) INDEX BY user_objects.object_name%TYPE;

-- basic record for some constraint operations
TYPE type_constraint_rec IS RECORD(
   table_name             user_tables.table_name%TYPE,
   old_constraint_name    user_constraints.constraint_name%TYPE,
   constraint_name        user_constraints.constraint_name%TYPE,
   constraint_type        user_constraints.constraint_type%TYPE,
   constraint_columns     VARCHAR2(1000) DEFAULT NULL,
   index_name             user_constraints.index_name%TYPE DEFAULT NULL,
   tablespace_name        user_indexes.tablespace_name%TYPE DEFAULT NULL,
   ref_table_name         user_tables.table_name%TYPE DEFAULT NULL,
   ref_constraint_columns VARCHAR2(1000) DEFAULT NULL,
   status                 user_constraints.status%TYPE DEFAULT 'ENABLE',
   validated              VARCHAR2(20) DEFAULT 'VALIDATE',
   delete_rule            VARCHAR2(40) DEFAULT NULL,
   check_condition        VARCHAR2(2000) DEFAULT NULL);
   
-- associative array of constraint records
TYPE type_constraint_recarr IS TABLE OF type_constraint_rec INDEX BY PLS_INTEGER;


--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

-- stands for public "global array of dependent FK records"
g_dep_fks     type_constraint_recarr;
-- used only to empty out the global structure above
empty_dep_fks type_constraint_recarr;
-- used as default for certain routine parameters
empty_obj_nm_arr type_obj_nm_arr;

-- {%skip}
-- Top-level Oracle object types
gc_table      CONSTANT user_objects.object_type%TYPE := 'TABLE';
gc_index      CONSTANT user_objects.object_type%TYPE := 'INDEX';
gc_package    CONSTANT user_objects.object_type%TYPE := 'PACKAGE';
gc_package_body CONSTANT user_objects.object_type%TYPE := 'PACKAGE BODY';
gc_procedure  CONSTANT user_objects.object_type%TYPE := 'PROCEDURE';
gc_function   CONSTANT user_objects.object_type%TYPE := 'FUNCTION';
gc_sequence   CONSTANT user_objects.object_type%TYPE := 'SEQUENCE';
gc_synonym    CONSTANT user_objects.object_type%TYPE := 'SYNONYM';
gc_trigger    CONSTANT user_objects.object_type%TYPE := 'TRIGGER';
gc_view       CONSTANT user_objects.object_type%TYPE := 'VIEW';
gc_type       CONSTANT user_objects.object_type%TYPE := 'TYPE';
gc_type_body  CONSTANT user_objects.object_type%TYPE := 'TYPE BODY';
gc_mv         CONSTANT user_objects.object_type%TYPE := 'MATERIALIZED VIEW';
gc_q_table    CONSTANT user_objects.object_type%TYPE := 'QUEUE TABLE';
gc_q          CONSTANT user_objects.object_type%TYPE := 'QUEUE';
gc_dbms_job   CONSTANT user_objects.object_type%TYPE := 'DBMS JOB';
gc_job        CONSTANT user_objects.object_type%TYPE := 'JOB';
gc_schedule   CONSTANT user_objects.object_type%TYPE := 'SCHEDULE';
gc_chain      CONSTANT user_objects.object_type%TYPE := 'CHAIN';
gc_chain_rule CONSTANT user_objects.object_type%TYPE := 'CHAIN RULE';
gc_chain_step CONSTANT user_objects.object_type%TYPE := 'CHAIN STEP';
gc_program    CONSTANT user_objects.object_type%TYPE := 'PROGRAM';
gc_job_class  CONSTANT user_objects.object_type%TYPE := 'JOB CLASS';
gc_window     CONSTANT user_objects.object_type%TYPE := 'WINDOW';
gc_window_grp CONSTANT user_objects.object_type%TYPE := 'WINDOW GROUP';

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

--------------------------------------------------------------------------------
-- get_db_version:
-- Replacement for DBMS_DB_VERSION, since not all 9i instances can be counted
-- upon to have that package compiled.
--------------------------------------------------------------------------------
FUNCTION get_db_version RETURN NUMBER;

--------------------------------------------------------------------------------
-- data_is_found:
-- Tells you whether a given table (or an optional partition) has data in it or not.
-- 
-- %algorithm
-- Does not rely on statistics. Will do a hard COUNT(*), but using ROWNUM <= 1 to
-- return the second it finds even one row.
--  
-- %param i_tbl_nm The table you would like to check for emptiness
-- %param i_part_nm The name of the partition you would like to check (instead of
--          the entire table).
-- %return {*}TRUE Table has data in it.
--         {*}FALSE Table is empty
--------------------------------------------------------------------------------
FUNCTION data_is_found
(
   i_tbl_nm   IN VARCHAR2,
   i_part_nm  IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- obj_exists:
-- Tells you whether a given object exists or not.  The object can be any top-level
-- object found in user_objects or user_constraints, and tablespaces.
-- 
-- %note
-- Since this function looks at user_objects, it will not find "contained" things
-- like functions/procedures inside packages, columns in tables, attributes in 
-- type specs, etc. To do that, use attr_exists() found further below.
-- 
-- %param i_obj_nm   Name of the table, index, etc.
-- %param i_obj_type Optional parameter to narrow the search and force it to look
--          only for matches object names of that type.
--          Valid values are:
--          gc_table, gc_index, gc_package, gc_sequence, gc_synonym, gc_trigger
--          gc_view, gc_type, gc_constraint
-- %return {*}TRUE Object exists in current schema.
--         {*}FALSE Object was not found.
--------------------------------------------------------------------------------
FUNCTION obj_exists
(
   i_obj_nm   IN VARCHAR2,
   i_obj_type IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- attr_exists:
-- Determines whether a contained item, like a column, type attribute or type method,
-- is found in the containing object. Defaults to columns since most callers will
-- simply want to know if a given column already exists on a table.
-- 
-- %param i_obj_nm  Name of the containing table, package or user-defined type
-- %param i_attr_nm Name of the attribute whose existence is questioned.
-- %param i_attr_type The type of the attribute. Defaults to COLUMN if not given.
--          Valid values are:
--          {*} gc_column     For table column
--          {*} gc_attribute  For type attribute
--          {*} gc_method     For type method
--          {*} gc_routine    For packaged functions or procedures
--          {*} gc_part       For table partitions
--          {*} gc_subpart    For table subpartitions
-- %return {*}TRUE Attribute exists within the given object.
--         {*}FALSE Attribute was not found.
-- 
-- %usage
-- <code>
-- DECLARE
-- BEGIN
--   IF (NOT ddl_utils.attr_exists('nm_schedule','my_new_column')) THEN
--      EXECUTE IMMEDIATE '
--         ALTER TABLE nm_schedule
--           ADD my_new_column VARCHAR2(500)
--      ';
--   ELSE
--      dbms_output.put_line('MY_NEW_COLUMN already exists on NM_SCHEDULE.');
--   END IF;
-- END;
--  
-- REM It's OK if comments are overwritten, so no need to embed in dynamic SQL as above
-- COMMENT ON COLUMN nm_schedule.my_new_column IS 'My New Column: Blah, blah, blah.';
-- </code>
--                    
--------------------------------------------------------------------------------
FUNCTION attr_exists
(
   i_obj_nm    IN VARCHAR2,
   i_attr_nm   IN VARCHAR2,
   i_attr_type IN VARCHAR2 DEFAULT gc_column
) RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- get_num_rows:
-- Returns the number of rows currently in the given table. Will return 0 for all 
-- temporary tables.
-- 
-- %algorithm
-- First attempts to get the count from the statistics contained in user_tables.
-- If there are no statistics, or the last analyzed date was more than 
-- N days in the past, then it will full scan the table for a count.
-- 
-- %design
-- This package is meant to be used only during upgrades and new installs.  That is
-- why we expect temp tables to be empty. If some DML script has populated a temp
-- table during an upgrade, and an attempt is made to replace the temp table, or
-- create an index on it, an Oracle error will be raised. If you encounter this,
-- truncate the temp table and try to re-run the DDL that failed.
-- 
-- %param i_tbl_nm Name of the table for which you desire a count.
-- %param i_stale_count_limit The number of days old statistics can be before the
--           num_rows value in user_tables is considered too stale. Defaults to 5 days.
-- %return The number of rows in the table.
--------------------------------------------------------------------------------
FUNCTION get_num_rows
(
   i_tbl_nm            IN VARCHAR2,
   i_stale_count_limit IN NUMBER DEFAULT 5
) RETURN user_tables.num_rows%TYPE;

--------------------------------------------------------------------------------
-- get_cons_columns:
-- Returns a comma-delimited list of the columns that make up a constraint, e.g.
-- "(xp_id)" for a PK or "(tspa_id, element_cd, code_set_value_cd)" for a UK.
-- 
-- %param i_cons_nm Name of the constraint for which you wish to know the column
--          composition.
-- %return Parentheses-enclosed, comma-delimited list of columns in the constraint.
--------------------------------------------------------------------------------
FUNCTION get_cons_columns(i_cons_nm IN VARCHAR2) RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- get_tbl_by_cons:
-- Find the table for a given constraint.
-- 
-- %param i_cons_nm The constraint whose owning table is not known.
-- %return The table name.
--------------------------------------------------------------------------------
FUNCTION get_tbl_by_cons(i_cons_nm IN VARCHAR2) RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- get_tbl_by_idx:
-- Find the table for a given index.
-- 
-- %param i_idx_nm The index whose owning table is not known.
-- %return The table name.
--------------------------------------------------------------------------------
FUNCTION get_tbl_by_idx(i_idx_nm IN VARCHAR2) RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- get_search_condition:
-- Returns a VARCHAR2 version of the LONG check constraint condition.
-- 
-- %param i_check_nm Name of the check constraint whose search condition is desired.
-- %return The check constraint condition.
--------------------------------------------------------------------------------
FUNCTION get_search_condition(i_check_nm IN VARCHAR2) RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- get_default_value:
-- Returns a VARCHAR2 version of the LONG default value for the given column. This 
-- is really only meant to be called by DDL_UTILS, but it has to be public in order 
-- to be useable in SQL statements internal to the body.
-- 
-- %param i_tbl_nm Name of the table containing the column to be queried.
-- %param i_col_nm Name of the column to be queried.
-- %return The column default value. NULL if none found.
--------------------------------------------------------------------------------
FUNCTION get_default_value
(
   i_tbl_nm IN VARCHAR2,
   i_col_nm IN VARCHAR2
) RETURN VARCHAR2;


--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- drop_tbl:
-- Drops a single named table. If the table does not exist, no error is raised.
-- 
-- %note
-- If there are dependent tables on the table being dropped, the referencing FKs
-- will be dropped. The caller must be aware of this and call recreate_dep_fks to 
-- recreate the FKs at the end of the DDL script, after the new parent table
-- has been recreated or replaced.
-- 
-- %param i_tbl_nm Name of the table to be dropped
-- %param i_drop_with_data Defaults to FALSE. Set to TRUE if you don't care about
--          any existing data in the table. If left FALSE, an error
--          will be raised if the table still has data.
--                          
--------------------------------------------------------------------------------
PROCEDURE drop_tbl
(
   i_tbl_nm         IN VARCHAR2,
   i_drop_with_data IN BOOLEAN DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- drop_col:
-- Drops a single column from a named table.  If the column does not currently exist
-- on the table, an informational message will be displayed. If the table is deemed
-- extremely large (over 50M rows), the companion set_unused() routine will be 
-- called instead.
-- 
-- %design
-- We designed it to not raise errors if the columns aren't there because we 
-- anticipate drop_col and drop_tbl being the most frequently called routines
-- from most DDL scripts, used as a way of preventing Oracle errors when migrating
-- a DDL script to an internal environment multiple times (otherwise migrators have
-- to manually drop tables and columns to prepare for the re-run).
-- 
-- %warn 
-- Does not handle "ORA-12992: cannot drop parent key column". If foolishly 
-- dropping a PK column without handling the prelimary tear-down, this routine
-- will raise a highly deserved error.
--       
-- %param i_tbl_nm Name of the table containing the column to be dropped.
-- %param i_col_nm Name of the column to be dropped.
--------------------------------------------------------------------------------
PROCEDURE drop_col
(
   i_tbl_nm IN VARCHAR2,
   i_col_nm IN VARCHAR2
);

--------------------------------------------------------------------------------
-- set_unused:
-- Sets the given column on the table to UNUSED.
-- 
-- %algorithm
-- For set_unused, if the column does not currently exist, it will check the data
-- dictionary to see if the table has any unused columns. It will then sport a
-- warning message if the column doesn't exist, or an informational message if it
-- likely the column was already set to unused.
-- 
-- %param i_tbl_nm Name of the table containing the column to be dropped.
-- %param i_col_nm Name of the column to be dropped.
--------------------------------------------------------------------------------
PROCEDURE set_unused
(
   i_tbl_nm IN VARCHAR2,
   i_col_nm IN VARCHAR2
);

--------------------------------------------------------------------------------
-- drop_col_list:
-- Drops a set of columns from a named table. If any of the columns in the list is
-- not found on the table, then a message will be displayed.
-- 
-- %note
-- Other than ensuring the given table exists, this routine performs no error
-- handling of any kind. So if you accidentally end the column list in a comma,
-- or have two commas next to each other, etc., it will bomb with an Oracle error.
-- 
-- %param i_tbl_nm Name of the table containing the columns to be dropped.
-- %param i_col_list A comma-separate list of columns, e.g. 'col1, col2, col3'
--------------------------------------------------------------------------------
PROCEDURE drop_col_list
(
   i_tbl_nm   IN VARCHAR2,
   i_col_list IN VARCHAR2
);

--------------------------------------------------------------------------------
-- drop_idx:
-- Drops a single named index. If the index does not exist, no error is raised.
-- 
-- %algorithm
-- Assumes that the given index is a normal index with no ties to constraints. If
-- it turns out the index supports a PK or UK, it will call drop_pk, which will
-- automatically remove the constraint first, and finally the requested index.
-- However, if the PK or UK constraints supports dependent child FKs, the FKs will
-- be saved to g_dep_fks and messages will be displayed to remind the caller to
-- call recreate_dep_fks after the PK/UK has been recreated.
-- 
-- %param i_idx_nm Name of the index to be dropped.
--------------------------------------------------------------------------------
PROCEDURE drop_idx(i_idx_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- drop_pk:
-- Drops the named PK from the given table. Will also drop the underlying index, 
-- unless i_keep_index is TRUE.
-- 
-- %param i_pk_nm Name of the primary key to drop.
-- %param i_tbl_nm Name of the table to which the PK belongs. Optional. Will be 
--          looked up if not given.
-- %param i_keep_index Default is FALSE and index will be dropped. Set to TRUE if
--          you desire to keep the index around after the constraint is gone.
--------------------------------------------------------------------------------
PROCEDURE drop_pk
(
   i_pk_nm      IN VARCHAR2,
   i_tbl_nm     IN VARCHAR2 DEFAULT NULL,
   i_keep_index IN BOOLEAN DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- drop_uk:
-- Drops the named UK from the given table. Will also drop the underlying index, 
-- unless i_keep_index is TRUE.
-- 
-- %param i_pk_nm Name of the unique key to drop.
-- %param i_tbl_nm Name of the table to which the UK belongs. Optional. Will be 
--          looked up if not given.
-- %param i_keep_index Default is FALSE and index will be dropped. Set to TRUE if
--          you desire to keep the index around after the constraint is gone.
--------------------------------------------------------------------------------
PROCEDURE drop_uk
(
   i_uk_nm      IN VARCHAR2,
   i_tbl_nm     IN VARCHAR2 DEFAULT NULL,
   i_keep_index IN BOOLEAN DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- drop_fk:
-- Drops the named FK from the given table.
-- 
-- %param i_fk_nm Name of the foreign key to drop.
-- %param i_tbl_nm Name of the table to which the FK belongs. Optional. Table will
--          be looked up if not given.
--------------------------------------------------------------------------------
PROCEDURE drop_fk
(
   i_fk_nm  IN VARCHAR2,
   i_tbl_nm IN VARCHAR2 DEFAULT NULL
);

--------------------------------------------------------------------------------
-- drop_chk:
-- Drops the named check constraint from the given table.
-- 
-- %param i_chk_nm Name of the check constraint to drop.
-- %param i_tbl_nm Name of the table to which the check belongs. Optional. Table 
--          will be looked up if not given.
--------------------------------------------------------------------------------
PROCEDURE drop_chk
(
   i_chk_nm IN VARCHAR2,
   i_tbl_nm IN VARCHAR2 DEFAULT NULL
);

--------------------------------------------------------------------------------
-- drop_syn:
-- Drops a single named synonym.
-- 
-- %param i_syn_nm Name of the synonym to drop. Not case-sensitive.
--------------------------------------------------------------------------------
PROCEDURE drop_syn(i_syn_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- drop_trig:
-- Drops a single named trigger.
-- 
-- %param i_syn_nm Name of the trigger to drop. Not case-sensitive.
--------------------------------------------------------------------------------
PROCEDURE drop_trig(i_trig_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- drop_view:
-- Drops a single named view.
-- 
-- %param i_syn_nm Name of the view to drop. Not case-sensitive.
--------------------------------------------------------------------------------
PROCEDURE drop_view(i_view_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- drop_mv:
-- Drops a single named materialized view.
-- 
-- %param i_syn_nm Name of the materialized view to drop. Not case-sensitive.
--------------------------------------------------------------------------------
PROCEDURE drop_mv(i_mv_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- drop_pub_syn:
-- Drops a single named public synonym.
-- 
-- %param i_syn_nm Name of the public synonym to drop. Not case-sensitive.
--------------------------------------------------------------------------------
PROCEDURE drop_pub_syn(i_syn_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- drop_all_pub_syn:
-- Drops all public synonyms owned by the calling schema.
--------------------------------------------------------------------------------
PROCEDURE drop_all_pub_syn;

--------------------------------------------------------------------------------
-- drop_all_priv_syn:
-- Drops all private synonyms owned by the calling schema.
--
-- %design
-- If the calling schema has private synonyms pointing to objects in multiple
-- base schemas, call this routine with the name of the schema who owns
-- the underlying objects to the synonyms you want to drop. If you want all 
-- private synonyms to drop, call the routine with no parameters.
--
-- %param i_ref_owner Name of the schema which owns the objects to which the
--          calling schema is pointing.
--------------------------------------------------------------------------------
PROCEDURE drop_all_priv_syn(i_ref_owner IN VARCHAR2 DEFAULT NULL);

--------------------------------------------------------------------------------
-- drop_all_obj:
-- Drops all database objects from the current schema.
-- 
-- %note
-- Only application-owning schemas are allowed to use this routine.
-- 
-- <pre>
-- User Date      CR     Comments
-- ---- --------- ------ -------------------------------------------------------
-- WAC  2006Sep11        Added check for additional application schemas.
-- </pre>
--------------------------------------------------------------------------------
PROCEDURE drop_all_obj;

--------------------------------------------------------------------------------
-- drop_seq:
-- Drops a single named sequence.
-- 
-- %param i_seq_nm Name of the sequence to drop. Not case-sensitive.
--------------------------------------------------------------------------------
PROCEDURE drop_seq(i_seq_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- drop_obj:
-- Drops the given PL/SQL object.  If the object does not exist, a simple INFO
-- message will be displayed announcing that fact. Valid PL/SQL objects are
-- packages, functions, procedures, views, types, and triggers.
-- 
-- %warn
-- No special processing is attempted for TYPE objects. If there is code or subtypes
-- dependent on the TYPE, Oracle errors will be raised. You must undertake the
-- appropriate tear-down yourself.
-- 
-- %param i_obj_nm Name of the PL/SQL stored object to drop. Not case-sensitive.
-- %param i_obj_type Optional parameter to narrow the search and force it to look
--          only for matches on object names of that type.
--          Valid values are:
--          gc_table, gc_index, gc_package, gc_sequence, gc_synonym, gc_trigger
--          gc_view, gc_type, gc_constraint
--------------------------------------------------------------------------------
PROCEDURE drop_obj(i_obj_nm IN VARCHAR2, i_obj_type IN VARCHAR2 DEFAULT NULL);


--------------------------------------------------------------------------------
-- rename_tbl:
-- Renames a table. Will output an INFO message if the table has already been 
-- renamed.
-- 
-- %param i_tbl_nm Name of the table being renamed.
-- %param i_new_tbl_nm New name of the table.
--------------------------------------------------------------------------------
PROCEDURE rename_tbl
(
   i_tbl_nm     IN VARCHAR2,
   i_new_tbl_nm IN VARCHAR2
);

--------------------------------------------------------------------------------
-- rename_col:
-- Renames a column. Will output an INFO message if the column has already been 
-- renamed.
-- 
-- %param i_tbl_nm Name of the table containing the column.
-- %param i_col_nm Name of the column being renamed.
-- %param i_new_col_nm New name of the column.
--------------------------------------------------------------------------------
PROCEDURE rename_col
(
   i_tbl_nm     IN VARCHAR2,
   i_col_nm     IN VARCHAR2,
   i_new_col_nm IN VARCHAR2
);

--------------------------------------------------------------------------------
-- rename_idx:
-- Renames an index. Will output an INFO message if the index has already been 
-- renamed.
-- 
-- %param i_idx_nm Name of the index being renamed.
-- %param i_new_idx_nm New name of the index.
--------------------------------------------------------------------------------
PROCEDURE rename_idx
(
   i_idx_nm     IN VARCHAR2,
   i_new_idx_nm IN VARCHAR2
);

--------------------------------------------------------------------------------
-- rename_cons:
-- Renames a constraint. For PK and UK constraints, also ensures that the underlying
-- index is in-sync with the constraint name. Will output an INFO message if the 
-- constraint has already been renamed.
-- 
-- %param i_cons_nm Name of the constraint being renamed.
-- %param i_new_cons_nm New name of the constraint.
--------------------------------------------------------------------------------
PROCEDURE rename_cons
(
   i_cons_nm     IN VARCHAR2,
   i_new_cons_nm IN VARCHAR2
);

--------------------------------------------------------------------------------
-- rename_seq:
-- Renames a sequence. Will output an INFO message if the sequence has already 
-- been renamed.
-- 
-- %param i_seq_nm Name of the sequence being renamed.
-- %param i_new_seq_nm New name of the sequence.
--------------------------------------------------------------------------------
PROCEDURE rename_seq
(
   i_seq_nm     IN VARCHAR2,
   i_new_seq_nm IN VARCHAR2
);



--------------------------------------------------------------------------------
-- move_tbl:
-- Moves a table from one tablespace to another. Before moving, it will check to 
-- see if the given table already exists in the given tablespace. If it already 
-- exists in the correct tablespace, it will do nothing except report that fact.
-- 
-- %warn
-- Partitioned tables ARE NOT supported. Such moves of parititioned objects 
-- should be carefully evaluated and designed.
-- 
-- %note
-- If this is a huge table that will take more than a few minutes, be sure to "tag"
-- the session in v$session using tag_session() below. Also be sure to use 
-- untag_session() when the operation is complete so that v$session doesn't report
-- information that is no longer relevant.
-- 
-- %param i_tbl_nm Name of the table to move.
-- %param i_new_tablespace Name of the destination tablespace.
--------------------------------------------------------------------------------
PROCEDURE move_tbl
(
   i_tbl_nm         IN VARCHAR2,
   i_new_tablespace IN VARCHAR2
);

--------------------------------------------------------------------------------
-- move_idx:
-- Moves an index from one tablespace to another. Partitioned indexes ARE 
-- supported. Before moving, it will check to see if the given index already exists
-- in the given tablespace. If it already exists in the correct tablespace, it will
-- do nothing except report that fact.
-- 
-- %note
-- If this is a huge index that will take more than a few minutes, be sure to "tag"
-- the session in v$session using tag_session() below. Also be sure to use 
-- untag_session() when the operation is complete so that v$session doesn't report
-- information that is no longer relevant.
-- 
-- %param i_idx_nm Name of the index to move.
-- %param i_new_tablespace Name of the destination tablespace.
--------------------------------------------------------------------------------
PROCEDURE move_idx
(
   i_idx_nm         IN VARCHAR2,
   i_new_tablespace IN VARCHAR2
);

--------------------------------------------------------------------------------
-- rebuild_idx:
-- Rebuilds an index in its existing tablespace, unless a new tablespace is 
-- specified by the caller. Will automatically compute statistics as it is rebuilding
-- unless explicitly told not to.
-- 
-- %usage
-- For most indexes, simply use the first parameter, e.g.
-- <code>
-- exec ddl_utils.rebuild_idx('NM_SCHEDULE_UK');
-- </code>
-- 
-- %note
-- If this is a huge index that will take more than a few minutes, be sure to "tag"
-- the session in v$session using tag_session() below. Also be sure to use 
-- untag_session() when the operation is complete so that v$session doesn't report
-- information that is no longer relevant.
-- 
-- %warn
-- The partition parameters are really only meant to be called internally by the
-- rebuild_unusable() routine. rebuild_idx() does not check for adequate space
-- when moving partitions or subpartitions to a new tablespace since rebuild_unusable()
-- will never move partitions to new tablespaces. If you want to move an index to
-- a new tablespace, call move_idx() instead.
-- 
-- %param i_idx_nm Name of the index to rebuild.
-- %param i_new_tablespace Optional. Will rebuild the index in place if not given,
--          or will rebuild the index in the given tablespace.
-- %param i_part_nm This parameter is expected to be used only by the rebuild_unusable()
--          routine in this package. Since partitioned indexes can only be rebuilt
--          partition-by-partition, you would have to call this in a loop to 
--          rebuild every partition of a given index.
-- %param i_subpart_nm This parameter is expected to be used only by the rebuild_unusable()
--          routine in this package. Since composite partitioned indexes can only
--          be rebuilt subpartition-by-subpartition, you would have to call this in
--          a loop to rebuild every subpartition of a given index.                       
-- %param i_compute_statistics Default is TRUE. Pass in FALSE if you wish to 
--          prevent gathering index statistics at the same time it is being rebuild.
--          %warn
--          You can't do both ONLINE and COMPUTE STATISTICS on versions prior to 10gR2.
--          %warn
--          On 10g COMPUTE STATISTICS does nothing for partitioned indexes. This
--          is a bug fixed in version 11. So do not set i_compute_statistics to 
--          TRUE for 10g. You will have to continue gathering statistics manually 
--          (you can use analyze_index() below).
-- %param i_online Default is FALSE. Pass in TRUE if you wish the rebuild to occur 
--          while allowing users to continue hitting the table with queries that 
--          use the index.
--          %warn For some reason, 10g has a bug where if you ONLINE, you get an
--          ORA-01031: insufficient privileges if you don't have CREATE ANY TABLE
--          granted to you. So for now, I've commented out the ability to do ONLINE.
--------------------------------------------------------------------------------
PROCEDURE rebuild_idx
(
   i_idx_nm             IN VARCHAR2,
   i_new_tablespace     IN VARCHAR2 DEFAULT NULL,
   i_part_nm            IN VARCHAR2 DEFAULT NULL,
   i_subpart_nm         IN VARCHAR2 DEFAULT NULL,
   i_compute_statistics IN BOOLEAN DEFAULT TRUE,
   i_online             IN BOOLEAN DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- purge_dropped_objects:
-- If this is a 10g database, this will empty the trash. If it is a 9i database,
-- it will do nothing. This should be called before most large operations that 
-- deal with the user_objects view. If not called, there will be errors with
-- recyclebin objects (all of which start with "BIN$%").
--------------------------------------------------------------------------------
PROCEDURE purge_dropped_objects;

--------------------------------------------------------------------------------
-- tag_session:
-- Sets MODULE, ACTION and CLIENT_INFO on v$session to given values. Optional 
-- i_num_rows parameter determines whether tagging will take place for a given
-- call.  You would pass i_num_rows in for suspected long or looped operations
-- where the number of rows being operated upon is not known ahead of time.
-- 
-- %usage
-- <code>
-- exec ddl_utils.tag_session('CR53885','Recreate Constraint','NM_STTLCOMP_UK');
-- 
-- ALTER TABLE nm_sttl_component
--   DROP CONSTRAINT
-- ...
-- ALTER TABLE nm_sttl_component
--   ADD CONSTRAINT
-- ...
-- exec ddl_utils.analyze_index('NM_STTLCOMP_UK');
-- exec ddl_utils.untag_session;
-- </code>
-- 
-- %param i_module The governing "module", usually the CR#. The PL/SQL package name
--          is also a frequently-used value. Limited to 48 characters.
-- %param i_action The current "action", usually something like "Create Index",
--          "Move Table", etc. The packaged procedure/function name is also a
--          frequently-used value. Limited to 32 characters.
-- %param i_info The detail of the current step, usually the name of the table,
--          index or constraint being created/altered. Limited to 64 characters.
--------------------------------------------------------------------------------
PROCEDURE tag_session
(
   i_module   IN VARCHAR2,
   i_action   IN VARCHAR2,
   i_info     IN VARCHAR2
);

--------------------------------------------------------------------------------
-- untag_session:
-- Sets MODULE, ACTION and CLIENT_INFO on v$session to NULL.
-- 
-- %note
-- Make sure to call this after calling tag_session(). Otherwise the info fed to
-- tag_session will remain attached to your session, fooling administrators into
-- thinking your session is still working on the module indicated in v$session, 
-- when in fact your session has ended or moved on to other actions.
--------------------------------------------------------------------------------
PROCEDURE untag_session;

--------------------------------------------------------------------------------
-- print_dep_fks:
-- Prints out the DDL to recreate all the FKs dependent on a given table or unique
-- constraint.
--  
-- %param i_obj_nm Name of table or unique index or PK/UK.
--------------------------------------------------------------------------------
PROCEDURE print_dep_fks(i_obj_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- recreate_dep_fks:
-- Reads the FK specifications stored in g_dep_fks and recreates each one, 
-- reporting on any failures and successes.
--------------------------------------------------------------------------------
PROCEDURE recreate_dep_fks;

--------------------------------------------------------------------------------
-- process_constraint_list:
-- Reads an array of constraint specifications and drops, recreates or adds each one, 
-- depending on action discerned.
-- 
-- %algorithm
-- If old_constraint_name is filled, but [new] constraint_name is empty, it will 
-- DROP the old constraint; if old_constraint_name and constraint_name are both 
-- filled, but different, it will rename the constraint; if old_constraint_name is
-- empty, but constraint_name is filled, it will attempt to create the constraint
-- using the appropriate fields in the record. If the fields are not filled
-- properly, the constraint will not create correctly.
-- 
-- %param i_cons_recarr Array of FK records, pre-populated by calling script.
--------------------------------------------------------------------------------
PROCEDURE process_constraint_list(i_cons_recarr IN type_constraint_recarr);

--------------------------------------------------------------------------------
-- remove_parallel:
-- Removes parallelism from a named object.
-- 
-- %param i_obj_nm Name of the table or index for to be set to NOPARALLEL.
--------------------------------------------------------------------------------
PROCEDURE remove_parallel(i_obj_nm IN VARCHAR2);

--------------------------------------------------------------------------------
-- remove_parallel_all:
-- Removes parallelism from all objects in the database.
--------------------------------------------------------------------------------
PROCEDURE remove_parallel_all;

--------------------------------------------------------------------------------
-- add_logging_all:
-- Ensures all permanent (heap, IOT and partitioned) tables and indexes have 
-- LOGGING set on.
--------------------------------------------------------------------------------
PROCEDURE add_logging_all;

--------------------------------------------------------------------------------
-- enable_row_movement_all
-- Enabled row movement for any partitioned tables that have row movement
-- disabled.
--------------------------------------------------------------------------------
PROCEDURE enable_row_movement_all;

--------------------------------------------------------------------------------
-- remove_default:
-- "Removes" the DEFAULT value for the given column. Currently this is implemented
-- by modifying the column and adding a DEFAULT NULL. Although technically, the 
-- column still has a default value, since it is NULL, it is the same as if the 
-- default were removed.
-- 
-- %note Oracle does not currently provide a way to remove a default. The only way
-- to completely remove a DEFAULT is to drop and recreate the column. If you need
-- to completely remove all vestiges of a DEFAULT, pass TRUE for i_perm_removal.
-- 
-- %param i_tbl_nm Name of the table containing the column to be modified.
-- %param i_col_nm Name of the column with the DEFAULT to be removed.
-- %param i_perm_removal A flag that indicates
--          {*} FALSE Just alter the DEFAULT to NULL
--          {*} TRUE  Drop and recreate the column without a DEFAULT
--------------------------------------------------------------------------------
PROCEDURE remove_default
(
   i_tbl_nm       IN VARCHAR2,
   i_col_nm       IN VARCHAR2,
   i_perm_removal IN BOOLEAN DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- change_col:
-- Certain column operations (like decreasing length or precision, or changing the
-- datatype) cannot proceed with data in the column. A semi-complex
-- path needs to be followed to preserve the data within the column without 
-- removing it.
-- 
-- %algorithm
-- This first performs error checking to ensure it has all the information
-- it needs to proceed. Then it executes dynamic DDL to create a backup copy of the
-- old column on the same table. Then it deletes the data in the original column 
-- and executes the desired operation, then moves the data back into the new perm 
-- column from the copy. Then it finally deletes the copy. If there is any NOT NULL
-- constraint, it will be preserved.
-- 
-- %note
-- I considered calling dbms_stats to add back any statistics lost by the drop, but
-- have not come to a decision yet.
-- 
-- %param i_tbl_nm Name of the table containing the column to be modified.
-- %param i_col_nm Name of the column with the DEFAULT to be removed.
-- %param i_new_datatype Optional new datatype for the column.
-- %param i_new_length Conditional new length for the column. Should be a complete
--          length specification if given, e.g. 
--          {*} NUMBER Optional. Valid lengths would look like "(1)", "*,0", "(38,0) or "(3,4)"
--          {*} VARCHAR2 Required. Valid lengths would be between "(1)" and "(4000)"
--          {*} DATE Of course do not pass in a length for dates.
--          If the parenthesis are omitted, they will be added automatically to 
--          avoid the error at create time.
--------------------------------------------------------------------------------
PROCEDURE change_col
(
   i_tbl_nm       IN VARCHAR2,
   i_col_nm       IN VARCHAR2,
   i_new_datatype IN VARCHAR2 DEFAULT NULL,
   i_new_length   IN VARCHAR2 DEFAULT NULL
);

--------------------------------------------------------------------------------
-- rebuild_unusable:
-- Rebuilds any indexes that went unusable during migration/conversion/upgrade. It 
-- defaults to using the existing tablespace for each index/partition/subpartition.
-- 
-- %param i_compute_statistics Default is TRUE, computing the statistics for the
--          index while it is rebuilding it. Pass in FALSE if you wish to prevent 
--          gathering index statistics at the same time it is being rebuild.
--          %warn
--          You can't do both ONLINE and COMPUTE STATISTICS on versions prior to 
--          10gR2.
--          %warn
--          On 10g COMPUTE STATISTICS does nothing for partitioned indexes. This
--          is a bug fixed in version 11. So do not set i_compute_statistics to 
--          TRUE for 10g. You will have to continue gathering statistics manually 
--          (you can use analyze_index() below).
-- %param i_online Default is FALSE. Pass in TRUE if you wish the rebuild to occur
--          while allowing users to continue hitting the table with queries that 
--          use the index.
--------------------------------------------------------------------------------
PROCEDURE rebuild_unusable
(
   i_compute_statistics IN BOOLEAN DEFAULT TRUE,
   i_online             IN BOOLEAN DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- reset_seq:
-- Attempts to reconcile a sequence with the values in a surrogate key column.
-- Primarily used by build/migration scripts which empty tables, delete data, or
-- expand the data in tables without the aid of the sequence.
--
-- %design
-- This is primarily designed to work for sequences that support the surrogate PK
-- for a single table. Also if the table name isn't provided, the routine
-- attempts to derive the table name from the sequence name. It assumes you have
-- used one of following conventions to name your sequence:
--
-- {*} SEQ_table_name or SQ_table_name
-- {*} table_name_SEQ or table_name_SQ
-- {*} table_name_id_SEQ or table_name_id_SQ
-- {*} SEQ_table_name_id or SQ_table_name_id
-- {*} table_name_PK_SEQ or table_name_PK_SQ
--
-- If the sequence name does not follow any of those patterns, then the table
-- name is required in order to find the sequence-supported, PK column for that
-- table.
-- 
-- If there is no PK constraint for the given/derived table name, then the third
-- parameter, the column name holding sequence values, is also required.
--
-- %param i_seq_nm Name of the sequence to check for staleness against the MAX
--                 value found in the table's PK column or column provided in
--                 parameter i_col_nm.
-- %param i_tbl_nm Name of the table for which the sequence provides surrogate
--                 key values. Required if the table name cannot be derived
--                 from the sequence name based on the common patterns above.
-- %param i_col_nm Name of the column for which the sequence provides values.
--                 Required if the table does not have a single-column PK
--                 constraint.
-- %param i_recreate If the table is empty but the sequence is > 1, then the 
--                   sequence will be reset backwards. This can be done in a manner
--                   which does not invalidate packages. If this is important, pass
--                   FALSE for the parameter (the default). But this has a drawback in
--                   that the lowest number possible is 2. If the caller wants the
--                   sequence to be reset back to 1, pass TRUE for this parameter. 
--                   The caller is stating they are OK with the package invalidations
--                   when the sequence is dropped and re-created.                 
--------------------------------------------------------------------------------
PROCEDURE reset_seq (
   i_seq_nm   IN VARCHAR2,
   i_tbl_nm   IN VARCHAR2 DEFAULT NULL,
   i_col_nm   IN VARCHAR2 DEFAULT NULL,
   i_recreate IN BOOLEAN  DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- mod_seq_cache:
-- Alter the cache attribute of a named sequence.
-- 
-- %param i_seq_nm Name of the sequence to modify
-- %param i_new_cache_num Whole positive integer for new CACHE setting. Must be
--          0 for NOCACHE or greater than 1. Cannot be 1.
--------------------------------------------------------------------------------
PROCEDURE mod_seq_cache
(
   i_seq_nm        IN VARCHAR2,
   i_new_cache_num IN NUMBER
);

--------------------------------------------------------------------------------
-- set_table_monitoring      
-- If there are any new tables that have been created without the MONITORING      
-- attribute, this routine will find them and turn MONITORING on for them.
-- This is mainly useful for 9i environments. In 10g and higher, MONITORING is
-- turned on by default, unless the STATISTICS LEVEL has been set to BASIC, in 
-- which case this routine could still be useful on 10g.
--
-- %param i_tbl_nm Optional individual table name will set the monitoring on for
--           just the named table. Otherwise it will scan the schema for all
--           tables missing the monitoring clause.
------------------------------------------------------------------------------*/      
PROCEDURE set_table_monitoring(i_tbl_nm IN VARCHAR2 DEFAULT NULL);

--------------------------------------------------------------------------------
-- analyze_schema:
-- Analyzes all new objects of the calling user. This is appropriate for all new
-- installs (assuming dump file was stripped of statistics) and upgrades.
-- 
-- %design
-- The purpose of this routine is to encapsulate our recommended standard 
-- for analyzing an application schema. If a higher degree of control is desired, 
-- either get approval to change this routine, or write a custom statistics
-- gathering script.
-- 
-- %prereq
-- The GATHER STALE option will not work if MONITORING has not been turned on for
-- the application's tables. In 10g this is automatic as long as the init parm
-- STATISTICS_LEVEL is TYPICAL or ALL.
-- 
-- %param i_stale FALSE (the default) ignores objects that already have stats.
--          TRUE will gather stats only for stale objects (objects which have
--          changed at least 10% or been truncated since the last analyze).
--------------------------------------------------------------------------------
PROCEDURE analyze_schema
(
   i_stale_only IN BOOLEAN DEFAULT FALSE
);

--------------------------------------------------------------------------------
-- analyze_table:
-- Analyzes a named table, or optionally a named partition of the table.
-- 
-- %design
-- The purpose of this routine is to encapsulate our recommended standard 
-- for analyzing an application table. If a higher degree of control is desired, 
-- either get approval to change this routine, or call 
-- dbms_stats.gather_table_stats directly.
-- 
-- %design
-- We anticipate this routine will be called for the entire table after a DDL
-- script has backed a table up, dropped it, recreated it, and re-imported the
-- data. As such, the partition option won't be very useful for upgrades/installs.
-- The partition option will probably only be called internally as a convenience
-- to developers and tuners who are playing with large amounts of test
-- data loading and unloading in recent partitions.
-- 
-- %param i_tbl_nm The name of the table to be analyzed using DBMS_STATS.
-- %param i_part_nm Default is empty. The name of the invidual partition to which 
--          stats gathering will be limited.
--------------------------------------------------------------------------------
PROCEDURE analyze_table
(
   i_tbl_nm IN VARCHAR2,
   i_part_nm IN VARCHAR2 DEFAULT NULL
);

--------------------------------------------------------------------------------
-- analyze_index:
-- Analyzes a named index, or optionally a named partition of the index.
-- 
-- %design
-- The purpose of this routine is to encapsulate our recommended standard
-- for analyzing an application index. If a higher degree of control is desired, 
-- either get approval to change this routine, or call
-- dbms_stats.gather_index_stats directly.
-- 
-- %param i_idx_nm The name of the index to be analyzed using DBMS_STATS.
-- %param i_part_nm The name of the invidual partition to which stats gathering
--          will be limited.
--------------------------------------------------------------------------------
PROCEDURE analyze_index
(
   i_idx_nm  IN VARCHAR2,
   i_part_nm IN VARCHAR2 DEFAULT NULL
);

--------------------------------------------------------------------------------
-- refresh_grants :
-- Reads all of the owner's objects (minus any objects named in the exclude 
-- array) and grants basic privs to another user or role, as specified by the 
-- i_grantee parameter. See parameter notes below.
-- 
-- %param i_grantee If NULL, the default, will grant privs on the current schema's
--          objects to the <USER>_FULL role -- if it exists. If that role does
--          not exist, it will error out. Otherwise, if i_grantee is filled, it
--          will generate the script, or run the grants, for that role or user.
--
-- %param i_read_only If TRUE, the privileges for tables will be set to SELECT
--          only. If FALSE, full grants of SELECT, INSERT, UPDATE and DELETE 
--          will be given to the defaulted or named grantee.
--
-- %param i_gen_script If TRUE, and serveroutput is ON, will spit a SQL Grants
--          script to stdout. Defaults to FALSE, which actuall grants the privs
--          to the given role.
--
-- %param i_exclude_arr Associative array of object names to exclude from all
--                      GRANT statements.
--------------------------------------------------------------------------------
PROCEDURE refresh_grants
(
   i_grantee IN VARCHAR2 DEFAULT NULL,
   i_read_only   IN BOOLEAN DEFAULT FALSE, 
   i_gen_script IN BOOLEAN DEFAULT FALSE,
   i_exclude_arr IN type_obj_nm_arr DEFAULT empty_obj_nm_arr
);

--------------------------------------------------------------------------------
-- Recompile Utility
-- Created:   August 3, 1998
-- 
-- %version 2.0
-- %author  Solomon Yakobson
-- 
-- Recompile Utility is designed to compile the following types of objects:
-- <ul>
--  <li>PROCEDURE
--  <li>FUNCTION
--  <li>PACKAGE
--  <li>PACKAGE BODY
--  <li>TRIGGER
--  <li>VIEW
--  <li>TYPE
--  <li>TYPE BODY
--  <li>MATERIALIZED VIEW
-- </ul>
-- 
-- Objects are recompiled based on object dependency hierarchy, thereby compiling
-- all requested objects in one path. Recompile Utility can be used for Oracle 
-- 7.3 - 10g object compilation.
-- 
-- %note
-- Recompile Utility skips every object which is either of unsupported object type
-- or depends on INVALID object(s) outside of current request (compilation will 
-- fail anyway). If object recompilation is not successful, Recompile Utility 
-- continues with the next object.
-- 
-- %warn
-- No provision is made to recompile anything with DEBUG settings, or for native
-- PL/SQL compilation.
-- 
-- %param i_owner  The owner of the objects to be recompiled.
--          It accepts LIKE strings as a filter. Backslash (\) is used for 
--          escaping wildcards. Default is USER.
-- %param i_name   Filter used to define the names of objects to be recompiled.
--          It accepts LIKE strings as a filter. Backslash (\) is used for 
--          escaping wildcards. Default is '%' - any name.
-- %param i_type   Filter used to define the types of objects to be recompiled.
--          It accepts LIKE strings as a filter. Backslash (\) is used for 
--          escaping wildcards. Default is '%' - any type.
-- %param i_status Filter used to define the status of objects to be recompiled.
--          It accepts LIKE strings as a filter. Backslash (\) is used for 
--          escaping wildcards. Default is 'INVALID'.
-- %param i_verbose  BOOLEAN parameter. TRUE means object recompile status 
--          will be written to DBMS_OUTPUT buffer. FALSE means most DBMS_OUTPUT 
--          will be suppressed. Default is FALSE.
-- 
-- %return Recompile Utility returns the following values or their
-- combinations:
--  {*} 0 SUCCESS. All requested objects are recompiled and VALID.
--  {*} 1 INVALID_TYPE. At least one of the to-be-recompiled objects is not one of
--        the supported object types.
--  {*} 2 INVALID_PARENT. At least one of the to-be-recompiled objects depends on 
--        an invalid object outside of current request.
--  {*} 4 COMPILE_ERRORS. At least one of the to-be-recompiled objects was compiled 
--        with errors and is INVALID.
-- 
-- %design
-- If parameter i_display is set to TRUE, Recompile Utility writes the following 
-- information to DBMS_OUTPUT buffer:
-- 
--    RECOMPILING OBJECTS
-- 
--    Object Owner is i_owner
--    Object Name is i_name
--    Object Type is i_type
--    Object Status is i_status
-- 
-- TTT OOO.NNN is recompiled. Object status is SSS.
-- TTT OOO.NNN references invalid object(s) outside of this request.
-- OOO.NNN is TTT and can not be recompiled.
-- 
-- where i_owner is parameter i_owner value,
--       i_name is parameter i_name value,
--       i_type is parameter i_type value and 
--       i_status is parameter i_status value.
--       TTT is object type,
--       OOO is object owner,
--       NNN is object name and
--       SSS is object status after compilation.
-- 
-- %usage
-- If parameter i_display is set to TRUE, you MUST ensure DBMS_OUTPUT buffer is 
-- large enough for produced output. Otherwise Recompile Utility will not recompile
-- all the objects. If used in SQL*Plus, issue:
-- <code>
-- SET SERVEROUTPUT ON SIZE xxx FORMAT WRAPPED
-- </code>
-- FORMAT WRAPPED is needed for text alignment.
-- 
-- <pre>
-- Person      Date      Comments
-- ----------- --------- ------------------------------------------
-- SYakobson   1998Sep09 Fixed obj_cursor to include objects with no dependencies.
-- SYakobson   1999May12 Fix for DBMS_SQL behavior change in Oracle 8 (most likely 
--                       it is an Oracle bug). If object recompilation has errors, 
--                       ORACLE 8 DBMS_SQL raises exception 
--                       "ORA-24333: success with compilation" error, followed by 
--                       host environment internal error and "Unsafe to proceed" 
--                       message.
--                       Added COMPILE_ERRORS return code.
--                       Added TYPE and TYPE BODY objects.
-- SFeuerstein 2006Jan10 Upgraded for 9i and 10g
-- WAC         2006Sep13 Cleaned up function header grammar. Added plsqldoc tags.
--                       Altered to run from within DDL_UTILS package only for
--                       definer.
-- </pre>
--------------------------------------------------------------------------------
FUNCTION recompile
(
   i_owner   IN VARCHAR2 DEFAULT USER,
   i_name    IN VARCHAR2 DEFAULT '%',
   i_type    IN VARCHAR2 DEFAULT '%',
   i_status  IN VARCHAR2 DEFAULT 'INVALID',
   i_verbose IN BOOLEAN DEFAULT FALSE
) RETURN NUMBER;

--------------------------------------------------------------------------------
-- show_version:
-- Assuming caller has set SERVEROUTPUT on or has enabled and is getting from
-- the buffer, this procedure will display DDL_UTIL's current version number
-- (stored internally in the package).
--------------------------------------------------------------------------------
PROCEDURE show_version;

--------------------------------------------------------------------------------
-- get_version:
-- This function will return DDL_UTIL's current version number (stored 
-- internally in the package).
--------------------------------------------------------------------------------
FUNCTION get_version RETURN NUMBER;

--------------------------------------------------------------------------------
-- echo:
-- This is only used for testing so I have something to call to "ping" the package
-- and get Oracle's "automatic" recompiler to recompile, thus removing the annoying
-- "existing state of package has been discarded" error.
--------------------------------------------------------------------------------
PROCEDURE echo;

END ddl_utils;
/
