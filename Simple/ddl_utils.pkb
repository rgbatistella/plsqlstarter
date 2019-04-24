CREATE OR REPLACE PACKAGE BODY ddl_utils
AS 
/**----------------------------------------------------------------------------- 
<pre> 
Artisan      Date      Comments 
============ ========= ======================================================== 
bcoulam      2007Jan09 Created. 
 
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
 
-------------------------------------------------------------------------------- 
--               PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS 
-------------------------------------------------------------------------------- 
TYPE type_move_obj_rec IS RECORD ( 
    obj_nm VARCHAR2(30) 
   ,obj_type VARCHAR2(20) -- TABLE or INDEX 
   ,dest_tablespace VARCHAR2(30) 
   ,curr_tablespace VARCHAR2(30) 
   ,space_needed NUMBER 
   ,space_free NUMBER 
   ,partitioned_flg BOOLEAN 
); 
 
pkgc_pkg_nm CONSTANT user_objects.object_name%TYPE := 'ddl_utils'; 
pkgc_version_num CONSTANT NUMBER := 2.0; 
pkgc_error  CONSTANT VARCHAR2(10) := 'ERROR'; 
pkgc_warn   CONSTANT VARCHAR2(10) := 'WARNING'; 
pkgc_info   CONSTANT VARCHAR2(10) := 'INFO'; 
pkgc_large_op_rowsize INTEGER := 500000; --500K 
--gc_large_table_rowsize NUMBER := 5000000; --5M 
pkgc_huge_table_rowsize NUMBER := 50000000; --50M 
 
--pkgc_DT_MASK  CONSTANT VARCHAR2(20) := 'MM/DD/RRRR'; 
pkgc_dtm_mask CONSTANT VARCHAR2(22) := 'MM/DD/RRRR HH24:MI:SS'; 
--pkgc_SORTABLE_DTM_MASK CONSTANT VARCHAR(18) := 'YYYYMonDD HH24:MI:SS'; 
--pkgc_TM_MASK CONSTANT VARCHAR2(10) := 'HH24:MI:SS'; 
pkgc_integer_mask CONSTANT VARCHAR2(40) := 'FM999G999G999G990D0009'; 
 
-- Global variables initialized upon first use in session (see package init section) 
-- These variables can be made settable by creating public procedures to get 
-- and set their values. 
 
g_delimiter VARCHAR2(1); 
g_line_len  NUMBER(3, 0); 
g_sep_char  VARCHAR2(30); 
 
-------------------------------------------------------------------------------- 
--                   LOW-LEVEL PRIVATE PROCEDURES AND FUNCTIONS 
-------------------------------------------------------------------------------- 
 
-------------------------------------------------------------------------------- 
-- bool_to_str: 
-- Converts a BOOLEAN value to a "TRUE" or "FALSE" string. Returns NULL if NULL is 
-- given. 
-------------------------------------------------------------------------------- 
FUNCTION bool_to_str(i_bool_val IN BOOLEAN) RETURN VARCHAR2 IS 
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
-- ite: 
-- Functions to perform inline if/then/else, giving more flexibilty and allowing 
-- for more elegant code. Overloaded to accommodate strings, dates and numbers. 
--  
-- %param  i_if   Boolean to test 
-- %param  i_then Data to return if i_if is true 
-- %param  i_else Data to return if i_if is false 
-------------------------------------------------------------------------------- 
FUNCTION ite 
( 
   i_if   IN BOOLEAN, 
   i_then IN VARCHAR2, 
   i_else IN VARCHAR2 DEFAULT NULL 
) RETURN VARCHAR2 IS 
BEGIN 
   IF (i_if) THEN 
      RETURN(i_then); 
   ELSE 
      RETURN(i_else); 
   END IF; 
END ite; 
 
FUNCTION ite 
( 
   i_if   IN BOOLEAN, 
   i_then IN DATE, 
   i_else IN DATE DEFAULT NULL 
) RETURN DATE IS 
BEGIN 
   IF (i_if) THEN 
      RETURN(i_then); 
   ELSE 
      RETURN(i_else); 
   END IF; 
END ite; 
 
FUNCTION ite 
( 
   i_if   IN BOOLEAN, 
   i_then IN NUMBER, 
   i_else IN NUMBER DEFAULT NULL 
) RETURN NUMBER IS 
BEGIN 
   IF (i_if) THEN 
      RETURN(i_then); 
   ELSE 
      RETURN(i_else); 
   END IF; 
END ite; 
 
-------------------------------------------------------------------------------- 
-- ifnn (if NOT NULL): 
-- Function to perform inline if/then/else, giving more flexibilty and allowing 
-- for more elegant code. Overloaded to accommodate strings, dates and numbers. 
--  
-- %param   i_if   Data to check if it is not null 
-- %param   i_then Data to return if first parameter is not null 
-- %param   i_else Data to return if first parameter is null. If left NULL, NULL 
--                 will be returned if the i_if parameter is NULL. 
-------------------------------------------------------------------------------- 
FUNCTION ifnn 
( 
   i_if   IN VARCHAR2, 
   i_then IN VARCHAR2, 
   i_else IN VARCHAR2 DEFAULT NULL 
) RETURN VARCHAR2 IS 
BEGIN 
   RETURN(ite((i_if IS NOT NULL), i_then, i_else)); 
END ifnn; 
 
FUNCTION ifnn 
( 
   i_if   IN DATE, 
   i_then IN DATE, 
   i_else IN DATE DEFAULT NULL 
) RETURN DATE IS 
BEGIN 
   RETURN(ite((i_if IS NOT NULL), i_then, i_else)); 
END ifnn; 
 
FUNCTION ifnn 
( 
   i_if   IN NUMBER, 
   i_then IN NUMBER, 
   i_else IN NUMBER DEFAULT NULL 
) RETURN NUMBER IS 
BEGIN 
   RETURN(ite((i_if IS NOT NULL), i_then, i_else)); 
END ifnn; 
 
-------------------------------------------------------------------------------- 
-- ifn (if NULL): 
-- Function to perform inline if/then/else, giving more flexibilty and allowing 
-- for more elegant code. Overloaded to accommodate strings, dates and numbers. 
--  
-- %param   i_if   Data to check if it is null 
-- %param   i_then Data to return if first parameter is null 
-- %param   i_else Data to return if first parameter is not null. If left NULL, 
--                 NULL will be returned if i_if is NULL. But that behavior makes 
--                 this function equivalent to NVL. So be sure to provide the i_else 
--                 parameter. If you don't need to, use NVL instead. It's  
--                 optimized and faster. 
-------------------------------------------------------------------------------- 
FUNCTION ifn 
( 
   i_if   IN VARCHAR2, 
   i_then IN VARCHAR2, 
   i_else IN VARCHAR2 DEFAULT NULL 
) RETURN VARCHAR2 IS 
BEGIN 
   RETURN(ite(i_if IS NULL, i_then, i_else)); 
END ifn; 
 
FUNCTION ifn 
( 
   i_if   IN DATE, 
   i_then IN DATE, 
   i_else IN DATE DEFAULT NULL 
) RETURN DATE IS 
BEGIN 
   RETURN(ite(i_if IS NULL, i_then, i_else)); 
END ifn; 
 
FUNCTION ifn 
( 
   i_if   IN NUMBER, 
   i_then IN NUMBER, 
   i_else IN NUMBER DEFAULT NULL 
) RETURN NUMBER IS 
BEGIN 
   RETURN(ite(i_if IS NULL, i_then, i_else)); 
END ifn; 
 
-------------------------------------------------------------------------------- 
-- p: 
-- Prints characters to stdout (SQL*Plus consolue, Unix console, stdout redirected 
-- to file, etc.) 
--  
-- The first incarnation of the [P]rint procedure, the one that only 
-- takes 1 or 2 strings, was designed to be able to handle character strings 
-- longer than 255 chars, but less than 32,767 chars, which dbms_output's 
-- put_line routine cannot do. After conversion to 10g, the special handling will 
-- no longer be necessary. 
--  
-- The remaining versions of [P]rint were designed 
-- (1) for type-overridden name consistency, 
-- (2) to be a whole lot shorter to type than "dbms_output.put_line" and 
-- (3) to shorten some common uses for dbms_output. 
-- NOTE! The other versions of [P]rint that have a VARCHAR2 parameter were NOT 
-- designed to handle large VARCHAR2 values. 
--  
-- For example, most of them are designed to print out a little string tag, 
-- followed by the value. This is very useful for manual debugging, showing 
-- the name of a variable, then showing the variable's value. The p routine 
-- eliminates a little extra typing by taking care of the concatenations 
-- for you. 
-- Example: 
--    p('i_my_date',i_my_date); 
--                VS. 
--    dbms_output.put_line('i_my_date'||' : '||i_my_date); 
-------------------------------------------------------------------------------- 
PROCEDURE p 
( 
   i_str  IN VARCHAR2, 
   i_str2 IN VARCHAR2 DEFAULT NULL 
) IS 
   max_line CONSTANT NUMBER := g_line_len; -- maximum #chars put_line can handle 
   start_text NUMBER; -- starting pt of text to print 
   end_text   NUMBER; -- ending pt of text to print 
   lentxt     NUMBER; -- length from logical start to logical end of text 
   break_pt   NUMBER; -- break pt (found whitespace) 
   start_next NUMBER; -- next non-newline char 
 
   cr CONSTANT VARCHAR2(1) := CHR(13); -- carriage return character 
   lf CONSTANT VARCHAR2(1) := CHR(10); -- linefeed character 
   sp CONSTANT VARCHAR2(1) := CHR(32); -- space character 
   --DS CONSTANT VARCHAR2(2) := '  ';     -- 2 spaces 
   tb CONSTANT VARCHAR2(1) := CHR(9); -- tab character 
BEGIN 
    
   IF (i_str2 IS NOT NULL) THEN 
      p(i_str || g_sep_char || i_str2); 
   ELSE 
    
      start_text := 1; 
      LOOP 
         end_text := start_text + max_line - 1; 
         lentxt   := NVL(LENGTH(SUBSTR(i_str, start_text, max_line)), 0); 
       
         IF (lentxt < max_line) THEN 
            -- last chunk of text in string 
            DBMS_OUTPUT.put_line(SUBSTR(i_str, start_text, lentxt)); 
            EXIT; -- and we're done! 
         ELSE 
            -- not done yet so find good break pt 
            break_pt := 0; -- reset 
            FOR i IN REVERSE start_text .. end_text LOOP 
               IF (SUBSTR(i_str, i, 1) IN (cr, lf, sp, tb)) THEN 
                  break_pt := i; -- found suitable break pt 
                  EXIT; 
               END IF; 
            END LOOP; -- find break pt 
          
            IF (break_pt = 0) THEN 
               -- no suitable break pt found! 
               DBMS_OUTPUT.put_line(SUBSTR(i_str, start_text, max_line)); 
               start_text := end_text + 1; -- next start pt 
            ELSE 
               -- print to just before break pt 
               DBMS_OUTPUT.put_line(SUBSTR(i_str, 
                                           start_text, 
                                           break_pt - start_text)); 
               start_next := 0; -- reset 
             
               FOR i IN break_pt .. end_text LOOP 
                  -- find next non-newline char 
                  IF (SUBSTR(i_str, i, 1) NOT IN (cr, lf)) THEN 
                     start_next := i; 
                     EXIT; 
                  END IF; 
               END LOOP; -- find next non-newline char 
             
               IF (start_next = 0) THEN 
                  -- no non-newline char found 
                  start_text := end_text + 1; 
               ELSE 
                  start_text := start_next; -- start at non-newline char found 
               END IF; 
            END IF; -- break pt? 
         END IF; -- last chunk? 
      END LOOP; -- print long string 
   END IF; -- print tag/value pair, or long string? 
 
EXCEPTION 
   WHEN OTHERS THEN 
      BEGIN 
         DBMS_OUTPUT.put_line('ddl_utils.p ERROR: ' || SQLERRM(SQLCODE)); 
      EXCEPTION 
         WHEN OTHERS THEN 
            NULL; -- don't care 
      END; 
END p; 
 
-------------------------------------------------------------------------------- 
PROCEDURE p 
( 
   i_date IN DATE, 
   i_fmt  IN VARCHAR2 DEFAULT pkgc_dtm_mask 
    
) IS 
BEGIN 
   p(TO_CHAR(i_date, i_fmt)); 
END p; 
 
-------------------------------------------------------------------------------- 
PROCEDURE p 
( 
   i_num IN NUMBER, 
   i_fmt IN VARCHAR2 DEFAULT pkgc_integer_mask 
) IS 
BEGIN 
   p(TO_CHAR(i_num, i_fmt)); 
END p; 
 
-------------------------------------------------------------------------------- 
PROCEDURE p(i_bool IN BOOLEAN) IS 
BEGIN 
   p(bool_to_str(i_bool)); 
END p; 
 
-------------------------------------------------------------------------------- 
PROCEDURE p 
( 
   i_str  IN VARCHAR2, --  used as label, preceding date value 
   i_date IN DATE, 
   i_fmt  IN VARCHAR2 DEFAULT pkgc_dtm_mask 
) IS 
BEGIN 
   p(i_str || g_sep_char || TO_CHAR(i_date, i_fmt)); 
END p; 
 
-------------------------------------------------------------------------------- 
PROCEDURE p 
( 
   i_str IN VARCHAR2, --  used as label, preceding numeric value 
   i_num IN NUMBER, 
   i_fmt IN VARCHAR2 DEFAULT pkgc_integer_mask 
) IS 
BEGIN 
   p(i_str || g_sep_char || TO_CHAR(i_num, i_fmt)); 
END p; 
 
-------------------------------------------------------------------------------- 
PROCEDURE p 
( 
   i_str  IN VARCHAR2, --  used as label, preceding boolean (string) value 
   i_bool IN BOOLEAN --  will be converted to "TRUE", "FALSE" or NULL 
) IS 
BEGIN 
   p(i_str || g_sep_char || bool_to_str(i_bool)); 
END p; 
 
-------------------------------------------------------------------------------- 
-- err: 
-- Generic routine for getting application-generated exceptions to the screen. 
-------------------------------------------------------------------------------- 
PROCEDURE err(i_msg IN VARCHAR2) IS 
BEGIN 
      raise_application_error(-20000, pkgc_error || g_sep_char || i_msg); 
END err; 
 
-------------------------------------------------------------------------------- 
-- warn: 
-- Generic routine for getting warning information to the screen. Warnings mean 
-- the issue should be looked at and a decision made whether anything further 
-- should be done. 
-------------------------------------------------------------------------------- 
PROCEDURE warn(i_msg IN VARCHAR2) IS 
BEGIN 
   p(pkgc_warn, i_msg); 
END warn; 
 
-------------------------------------------------------------------------------- 
-- inf: 
-- Generic routine for getting informational messages to the screen. INFO messages 
-- don't necessarily have to be seen or analyzed. Used mainly for logging steps 
-- and actions taken. 
-------------------------------------------------------------------------------- 
PROCEDURE inf(i_msg IN VARCHAR2) IS 
BEGIN 
   p(pkgc_info, i_msg); 
END inf; 
 
-------------------------------------------------------------------------------- 
-- msg: 
-- Generic routine for spitting output to the screen. If i_raise is TRUE, it will 
-- ensure that an exception is raised.  This genericized version is used mainly by 
-- assert which does not know the message type ahead of time. 
-------------------------------------------------------------------------------- 
PROCEDURE msg 
( 
   i_msg      IN VARCHAR2, 
   i_msg_type IN VARCHAR2 DEFAULT pkgc_warn, 
   i_raise    IN BOOLEAN DEFAULT FALSE 
) IS 
BEGIN 
 
   IF (i_raise) THEN 
      raise_application_error(-20000, i_msg_type || g_sep_char || i_msg); 
   ELSE 
      p(i_msg_type, i_msg); 
   END IF; 
END msg; 
 
 
-------------------------------------------------------------------------------- 
-- assert: 
-- Assertions allow you to verify assumptions before proceeding in a program. 
-- This is part of the programming by contract methodology. 
--  
-- Pass an expression that has a boolean result. Assert will check it for true or 
-- false, and raise an exception if the assertion checked is false. If you wish  
-- the program to continue, you will need to pass FALSE in for the third parameter. 
-- In most cases, you will not need to fill the fourth parameter, it will default 
-- to VALUE_ERROR. However, if you have another bound or pre-defined exception, you 
-- may pass that in by name as well. 
--  
-- Numbers: 
--    assert(i_run_id > 0); 
-- Dates: 
--    assert(i_start_dtm >= trunc(sysdate)); 
-- Strings: 
--    assert(l_stmt <> ' '); 
-- Boolean: 
--    assert(l_continue_flg); 
-- NULL conditions: 
--    assert(l_stmt IS NOT NULL); 
--    assert(l_var IS NULL); 
--  
-- Optional messaging: 
--    assert(LENGTH(l_str) < 4000,'Message is too long'); 
--    Note: Messages will be sent to the screen, so this is not intended for 
--          unattended batch programs. 
--           
-- Optional named exception handling: 
--    assert(l_state_busy, NULL, 'excp.gx_row_locked'); 
--  
-- Optional continue processing: 
--    assert((SUBSTR(i_table_nme,1,2) = 'NM'), 'Not a Core table', NULL, FALSE); 
--  
-- %param i_expr Boolean expression, e.g. "1000 = i_num_recs", "i_rec_type IS NOT NULL", 
--          "l_control_num != l_counter", etc. 
-- %param i_msg The message that will be spat out to stdout/screen. 
-- %param i_msg_type Either ERROR, WARN or INFO (use package body constants) 
-- %param i_raise_excp Whether to raise an exception or allow processing to continue. 
--          {*} TRUE Default. Raises named exception (see i_excp_nm), or  
--              VALUE_ERROR if no name given. 
--          {*} FALSE Pass FALSE if you wish the program to continue rather than  
--              halting on error. 
-- %param i_excp_nm Can be an Oracle pre-defined exception, or a user-defined  
--          exception. If user-defined, the exception must be publicly visible  
--          (declared in a package specification). 
-------------------------------------------------------------------------------- 
PROCEDURE assert 
( 
   i_expr       IN BOOLEAN, 
   i_msg        IN VARCHAR2, 
   i_msg_type   IN VARCHAR2 DEFAULT pkgc_error, 
   i_raise_excp IN BOOLEAN DEFAULT TRUE, 
   i_excp_nm    IN VARCHAR2 DEFAULT NULL 
) IS 
BEGIN 
 
   IF (NOT NVL(i_expr, FALSE)) THEN 
      IF (i_raise_excp) THEN 
         IF (i_excp_nm IS NOT NULL) THEN 
            EXECUTE IMMEDIATE 'BEGIN' || '   RAISE ' || i_excp_nm || ';' || 
                              'END;'; 
         ELSE 
            raise_application_error(-20000, 
                                    i_msg_type || g_sep_char || 
                                    ifnn(i_msg, pkgc_pkg_nm || '.' || i_msg)); 
         END IF; 
      ELSE 
         msg('(Assertion Failure) ' || 
             ifnn(i_msg, pkgc_pkg_nm || '.' || i_msg), 
             i_msg_type, 
             FALSE); 
      END IF; -- if exception is provided 
    
   END IF; -- raise assertion failure if tested expression is false 
 
END assert; 
 
-------------------------------------------------------------------------------- 
--                   MID-LEVEL PRIVATE PROCEDURES AND FUNCTIONS 
-------------------------------------------------------------------------------- 
 
/* 
Mid level routines are only meant to be used privately. They assume that the 
higher level, public routines have already taken caller input and cleaned it up, 
UPPER cased object names, etc. If any of these are moved to PUBLIC, make them 
bullet-proof with assertions, UPPERcasing, etc. 
*/ 
 
-------------------------------------------------------------------------------- 
-- get_obj_type: 
-- Find the type of the object, given only the object name. Since there can be 
-- duplicate types for a given name (like the two entries for PACKAGE and PACKAGE 
-- BODY, for example, we have to filter the results on a set of limited types). 
--  
-- Note: This routine has a known flaw. If the constraint and the index match in 
-- name, the index will be found first and the returned type will be INDEX. Since 
-- this is the case 99% of the time with UK/PK constraints, the caller should call 
-- get_cons_by_idx() after get_obj_type to get the name of the constraint as well. 
--  
-- %param i_obj_nm The name of the object whose type is not known. 
-------------------------------------------------------------------------------- 
FUNCTION get_obj_type(i_obj_nm IN VARCHAR2) RETURN VARCHAR2 IS 
   --l_proc_nm user_objects.object_name%TYPE := 'get_obj_type'; 
   l_obj_type user_objects.object_type%TYPE; 
BEGIN 
   BEGIN 
      SELECT object_type 
        INTO l_obj_type 
        FROM user_objects 
       WHERE object_name = i_obj_nm 
            -- this eliminates duplicates like those that would show for PACKAGE BODY, 
            -- INDEX_PARTITION, etc. 
         AND object_type IN (gc_table, gc_index, gc_package, gc_sequence, 
              gc_trigger, gc_view, gc_type, gc_synonym, gc_function, gc_procedure); 
   EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
         -- It might be a constraint, check user_constraints 
         BEGIN 
            SELECT gc_constraint 
              INTO l_obj_type 
              FROM user_constraints 
             WHERE constraint_name = i_obj_nm; 
         EXCEPTION 
            WHEN NO_DATA_FOUND THEN 
               NULL; 
         END; 
   END; 
 
   RETURN l_obj_type; 
 
END get_obj_type; 
 
-------------------------------------------------------------------------------- 
-- is_idx_partitioned: 
-- Returns TRUE if the index is partitioned. 
--  
-- %param i_idx_nm The name of the index whose partitioning state is not known. 
-------------------------------------------------------------------------------- 
FUNCTION is_idx_partitioned(i_idx_nm IN VARCHAR2) RETURN BOOLEAN IS 
   l_count INTEGER := 0; 
BEGIN 
   SELECT COUNT(*) 
     INTO l_count 
     FROM user_part_indexes 
    WHERE index_name = UPPER(i_idx_nm); 
 
   IF (l_count = 0) THEN 
      RETURN FALSE; 
   ELSE 
      RETURN TRUE; 
   END IF; 
END is_idx_partitioned; 
 
-------------------------------------------------------------------------------- 
-- is_idx_subpartitioned: 
-- Returns TRUE if the index is subpartitioned. 
--  
-- %param i_idx_nm The name of the index whose subpartitioning state is not known. 
-------------------------------------------------------------------------------- 
FUNCTION is_idx_subpartitioned(i_idx_nm IN VARCHAR2) RETURN BOOLEAN IS 
   l_subpartitioning_type user_part_indexes.subpartitioning_type%TYPE; 
BEGIN 
   SELECT subpartitioning_type 
     INTO l_subpartitioning_type 
     FROM user_part_indexes 
    WHERE index_name = UPPER(i_idx_nm); 
 
   IF (l_subpartitioning_type = 'NONE') THEN 
      RETURN FALSE; 
   ELSE 
      RETURN TRUE; 
   END IF; 
EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      -- Can't be even partitioned, let alone subpartitioned, if 
      -- not found in user_part_indexes 
      RETURN FALSE; 
END is_idx_subpartitioned; 
 
-------------------------------------------------------------------------------- 
-- is_tbl_temporary: 
-- Returns TRUE if the table is a global temporary table. 
--  
-- %param i_tbl_nm The name of the table whose temporary nature is not known. 
-------------------------------------------------------------------------------- 
FUNCTION is_tbl_temporary(i_tbl_nm IN VARCHAR2) RETURN BOOLEAN IS 
   l_temporary VARCHAR2(1); 
BEGIN 
   SELECT TEMPORARY 
     INTO l_temporary 
     FROM user_tables 
    WHERE table_name = UPPER(i_tbl_nm); 
   IF (l_temporary = 'Y') THEN 
      RETURN TRUE; 
   ELSE 
      RETURN FALSE; 
   END IF; 
EXCEPTION 
   WHEN no_data_found THEN 
      RETURN FALSE; 
END is_tbl_temporary; 
-------------------------------------------------------------------------------- 
-- is_tbl_partitioned: 
-- Returns TRUE if the table is partitioned. 
--  
-- %param i_tbl_nm The name of the table whose partitioning state is not known. 
-------------------------------------------------------------------------------- 
FUNCTION is_tbl_partitioned(i_tbl_nm IN VARCHAR2) RETURN BOOLEAN IS 
   l_count INTEGER := 0; 
BEGIN 
   SELECT COUNT(*) 
     INTO l_count 
     FROM user_part_tables 
    WHERE table_name = UPPER(i_tbl_nm); 
 
   IF (l_count = 0) THEN 
      RETURN FALSE; 
   ELSE 
      RETURN TRUE; 
   END IF; 
END is_tbl_partitioned; 
 
-------------------------------------------------------------------------------- 
-- is_tbl_subpartitioned: 
-- Returns TRUE if the table is subpartitioned. 
--  
-- %param i_tbl_nm The name of the table whose subpartitioning state is not known. 
-------------------------------------------------------------------------------- 
FUNCTION is_tbl_subpartitioned(i_tbl_nm IN VARCHAR2) RETURN BOOLEAN IS 
   l_subpartitioning_type user_part_indexes.subpartitioning_type%TYPE; 
BEGIN 
   SELECT subpartitioning_type 
     INTO l_subpartitioning_type 
     FROM user_part_tables 
    WHERE table_name = UPPER(i_tbl_nm); 
 
   IF (l_subpartitioning_type = 'NONE') THEN 
      RETURN FALSE; 
   ELSE 
      RETURN TRUE; 
   END IF; 
EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      -- Can't be even partitioned, let alone subpartitioned, if 
      -- not found in user_part_tables 
      RETURN FALSE; 
END is_tbl_subpartitioned; 
 
-------------------------------------------------------------------------------- 
-- tablespace_exists: 
-- Returns TRUE if the tablespace exists. 
--  
-- %warn 
-- It may exist, but if the user does not have correct privileges (like the 
-- DBA role which can see all the tablespaces) or has not been granted quota on it,  
-- they won't be able to see it. If this is the case, the tablespace might as well 
-- not exist for the user, so FALSE will still be returned since the SELECT on 
-- user_tablespaces will yield nothing. 
--  
-- %param i_tablespace_nm The name of the tablespace whose existence is not known. 
-------------------------------------------------------------------------------- 
FUNCTION tablespace_exists(i_tablespace_nm IN VARCHAR2) RETURN BOOLEAN IS 
   l_count INTEGER := 0; 
BEGIN 
   SELECT COUNT(*) 
     INTO l_count 
     FROM user_tablespaces 
    WHERE tablespace_name = UPPER(i_tablespace_nm); 
 
   IF (l_count = 0) THEN 
      RETURN FALSE; 
   ELSE 
      RETURN TRUE; 
   END IF; 
END tablespace_exists; 
 
-------------------------------------------------------------------------------- 
-- get_cons_spec: 
-- Get the DDL specifications for a given named constraint. 
--  
-- %param i_cons_nm Name of the constraint whose specifications are desired. 
-------------------------------------------------------------------------------- 
FUNCTION get_cons_spec(i_cons_nm IN VARCHAR2) RETURN type_constraint_rec IS 
   l_proc_nm user_objects.object_name%TYPE := 'get_cons_spec'; 
   l_cons_spec type_constraint_rec; 
 
BEGIN 
   SELECT c.table_name 
         ,NULL -- old_constraint_name 
         ,c.constraint_name 
         ,c.constraint_type 
         ,get_cons_columns(c.constraint_name) 
         ,c.index_name 
         ,i.tablespace_name 
         ,DECODE(c.constraint_type 
                ,'R' 
                ,get_tbl_by_cons(c.r_constraint_name) 
                ,NULL) AS ref_table_name 
         ,DECODE(c.constraint_type 
                ,'R' 
                ,get_cons_columns(c.r_constraint_name) 
                ,NULL) AS ref_constraint_columns 
         ,DECODE(c.status, 'ENABLED', 'ENABLE', 'DISABLED', 'DISABLE') AS status 
         ,DECODE(c.validated, 'NOT VALIDATED', 'NOVALIDATE', 'VALIDATE') AS validated 
         ,DECODE(c.delete_rule 
                ,'SET NULL' 
                ,'ON DELETE SET NULL' 
                ,'CASCADE' 
                ,'ON DELETE CASCADE' 
                ,NULL) AS delete_rule 
         ,DECODE(c.constraint_type 
                ,'C' 
                ,get_search_condition(c.constraint_name) 
                ,NULL) AS check_condition 
     INTO l_cons_spec 
     FROM user_constraints c 
         ,user_indexes     i 
    WHERE constraint_name = i_cons_nm 
      AND c.index_name = i.index_name(+); 
 
   IF (l_cons_spec.constraint_type IN ('P','U') AND l_cons_spec.tablespace_name IS NULL) THEN 
      -- If this is a partitioned UK or PK, get the tablespace differently 
      IF (is_idx_partitioned(l_cons_spec.index_name)) THEN 
         BEGIN 
            SELECT DISTINCT tablespace_name 
            INTO l_cons_spec.tablespace_name 
            FROM user_ind_partitions 
            WHERE index_name = l_cons_spec.index_name; 
         EXCEPTION 
            WHEN too_many_rows THEN 
               err(l_proc_nm || g_sep_char || l_cons_spec.index_name||' is laid out over multiple tablespaces. This index requires manual handling.'); 
         END; 
      ELSE 
         -- we have a normal PK or UK with no tablespace = Odd 
         err(l_proc_nm || g_sep_char || l_cons_spec.index_name||' has no record of a tablespace. Odd. Investigate.'); 
      END IF; 
   END IF; 
 
   RETURN l_cons_spec; 
 
END get_cons_spec; 
 
-------------------------------------------------------------------------------- 
-- get_cons_by_idx: 
-- Find the constraint being supported by the given index. 
--  
-- %param i_idx_nm Index name used to look up its associated constraint. 
-------------------------------------------------------------------------------- 
FUNCTION get_cons_by_idx(i_idx_nm IN VARCHAR2) RETURN VARCHAR2 IS 
   l_proc_nm user_objects.object_name%TYPE := 'get_cons_by_idx'; 
   l_idx_nm user_constraints.index_name%TYPE; 
   l_cons_nm user_constraints.constraint_name%TYPE; 
BEGIN 
   l_idx_nm := UPPER(i_idx_nm); 
    
   SELECT constraint_name 
     INTO l_cons_nm 
     FROM user_constraints 
    WHERE index_name = l_idx_nm; 
 
   RETURN l_cons_nm; 
EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      warn(l_proc_nm || g_sep_char || 'Index ' || l_idx_nm ||' not found.'); 
   WHEN TOO_MANY_ROWS THEN 
      err(l_proc_nm || g_sep_char || 'Index ' || l_idx_nm ||' supports more than one constraint. Unable to determine which constraint is desired.'); 
END get_cons_by_idx; 
 
-------------------------------------------------------------------------------- 
-- get_idx_by_cons: 
-- Find the index supporting the given constraint. 
--  
-- %param i_cons_nm Constraint name used to look up its associated index. 
-------------------------------------------------------------------------------- 
FUNCTION get_idx_by_cons(i_cons_nm IN VARCHAR2) RETURN VARCHAR2 IS 
   l_proc_nm  user_objects.object_name%TYPE := 'get_idx_by_cons'; 
   l_idx_nm user_constraints.index_name%TYPE; 
   l_cons_nm user_constraints.constraint_name%TYPE; 
BEGIN 
   l_cons_nm := UPPER(i_cons_nm); 
    
   SELECT index_name 
     INTO l_idx_nm 
     FROM user_constraints 
    WHERE constraint_name = l_cons_nm; 
 
   RETURN l_idx_nm; 
EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      warn(l_proc_nm || g_sep_char || 'Constraint ' || l_cons_nm ||' not found.'); 
END get_idx_by_cons; 
 
-------------------------------------------------------------------------------- 
-- get_dep_fks: 
-- Determines the type of the object being dropped. Then gathers a list of all FKs  
-- that are dependent on a table or PK/UK being dropped. 
--  
-- If the item being dropped is a table, it finds the unique constraints (UK or PK) 
-- that are on the table. For each unique constraint, it finds and returns a list 
-- of the FK constraints that depend on the table. 
--  
-- If the item being dropped is a constraint, like a UK or PK (or its supporting 
-- index), it finds and returns a list of the FK constraints that depend on that 
-- constraint. 
--  
-- %param i_obj_being_dropped Name of table or unique index or PK/UK. 
-------------------------------------------------------------------------------- 
FUNCTION get_dep_fks(i_obj_being_dropped IN VARCHAR2) RETURN type_obj_nm_arr IS 
   --l_proc_nm user_objects.object_name%TYPE := 'get_dep_fks'; 
   l_obj_nm   user_objects.object_name%TYPE; 
   l_obj_type user_objects.object_type%TYPE; 
   l_dep_fk_names  type_obj_nm_arr; 
   l_cons_nm  user_constraints.constraint_name%TYPE; 
 
   CURSOR cur_uks(i_tbl_nm IN VARCHAR2) IS 
      SELECT constraint_name 
        FROM user_constraints 
       WHERE table_name = i_tbl_nm 
         AND constraint_type IN ('P', 'U'); 
          
   CURSOR cur_fks(i_cons_nm IN VARCHAR2) IS 
      SELECT constraint_name 
        FROM user_constraints 
       WHERE r_constraint_name = i_cons_nm 
         AND constraint_type = 'R'; 
 
   PROCEDURE load_fks(i_constraint_name IN VARCHAR2) IS 
   BEGIN 
      FOR lrc IN cur_fks(i_constraint_name) LOOP 
         l_dep_fk_names(lrc.constraint_name) := 'Y'; 
      END LOOP; 
   END load_fks; 
 
BEGIN 
   l_obj_nm   := UPPER(i_obj_being_dropped); 
   l_obj_type := get_obj_type(l_obj_nm); 
 
   IF (l_obj_type = gc_table) THEN 
      -- get all the PKs and UKs on the table 
      FOR lr IN cur_uks(l_obj_nm) LOOP 
         -- for each referenceable constraint, get the dependent FKs 
         load_fks(lr.constraint_name); 
      END LOOP; 
   ELSIF (l_obj_type IN (gc_index, gc_constraint)) THEN 
      -- if we are dealing with an index, get its constraint name first (usually 
      -- but not always, they are the same). 
      IF (l_obj_type = gc_index) THEN 
         l_cons_nm := get_cons_by_idx(l_obj_nm); 
      ELSE 
         l_cons_nm := l_obj_nm; 
      END IF; 
      -- now that we're down to lowest common denominator of a constraint_name, 
      -- we can use the common cursor to find the dependent FKs 
      load_fks(l_cons_nm); 
   END IF; 
 
   RETURN l_dep_fk_names; 
 
END get_dep_fks; 
 
-------------------------------------------------------------------------------- 
-- save_drop_dep_fks: 
-- Saves off the FK specs that depend upon the named table, if there are any. Then 
-- it drops them. 
--  
-- %param i_tbl_nm Name of the table that might have dependent FKs pointing to it. 
-------------------------------------------------------------------------------- 
PROCEDURE save_drop_dep_fks(i_tbl_nm IN VARCHAR2) 
IS 
   l_fk_list type_obj_nm_arr; 
   l_arr_idx user_objects.object_name%TYPE; 
BEGIN 
   p('Saving dependent FK DDL in DDL_UTILS.G_DEP_FKS for later retrieval by DDL_UTILS.RECREATE_DEP_FKS...'); 
   -- get list of dependent FKs 
   l_fk_list := get_dep_fks(i_tbl_nm); 
 
--   IF (l_fk_list IS NOT NULL AND l_fk_list.COUNT > 0) THEN 
   IF (l_fk_list.COUNT > 0) THEN 
 
      l_arr_idx := l_fk_list.FIRST; 
 
      WHILE l_arr_idx IS NOT NULL 
      LOOP 
         -- stores specifications for each dependent FK on public structure for 
         -- later retrieval and recreation 
         g_dep_fks(g_dep_fks.COUNT + 1) := get_cons_spec(l_arr_idx); 
          
         -- drop dependent FKs, reporting on each 
         drop_fk(l_arr_idx, g_dep_fks(g_dep_fks.COUNT).table_name); 
         p('Constraint ' || g_dep_fks(g_dep_fks.COUNT).table_name ||'.'||l_arr_idx|| ' saved and dropped.'); 
              
         -- move to next element 
         l_arr_idx := l_fk_list.NEXT(l_arr_idx); 
      END LOOP;    
       
--      FOR i IN l_fk_list.FIRST .. l_fk_list.LAST LOOP 
--         g_dep_fks(g_dep_fks.COUNT + 1) := get_cons_spec(l_fk_list(i)); 
--         -- drop dependent FKs, reporting on each 
--         drop_fk(l_fk_list(i), g_dep_fks(g_dep_fks.COUNT).table_name); 
--         p('Constraint ' || g_dep_fks(g_dep_fks.COUNT).table_name ||'.'||l_fk_list(i) || ' saved and dropped.'); 
--      END LOOP; 
   END IF; 
END save_drop_dep_fks; 
 
 
-------------------------------------------------------------------------------- 
-- drop_cons: 
-- Drops the given constraint, preserving the underlying index if there is one and 
-- caller has asked for it. Will save the dependent FKs and drop them if this 
-- constraint supports child FKS. 
--  
-- %param i_cons_nm Name of the constraint to drop. 
-- %param i_cons_type Type of the constraint to drop. Must be P, U, R or C. 
-- %param i_tbl_nm Name of the table that owns the constraint. This routine will 
--          find the owning table if not given. 
-- %param i_keep_index If the constraint is PK or UK, set this to TRUE if you desire 
--          to keep the underlying index. 
-------------------------------------------------------------------------------- 
PROCEDURE drop_cons 
( 
   i_cons_nm    IN VARCHAR2, 
   i_cons_type  IN VARCHAR2, 
   i_tbl_nm     IN VARCHAR2 DEFAULT NULL, 
   i_keep_index IN BOOLEAN DEFAULT FALSE 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_cons'; 
   l_cons_nm user_constraints.constraint_name%TYPE; 
   l_idx_nm  user_constraints.index_name%TYPE; 
   l_tbl_nm  user_constraints.table_name%TYPE; 
    
   lx_ucons_refd_by_fk EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_ucons_refd_by_fk, -2273); 
    
   PROCEDURE dyn_drop IS 
   BEGIN 
      EXECUTE IMMEDIATE 'ALTER TABLE ' || l_tbl_nm || ' DROP CONSTRAINT ' || 
                        l_cons_nm || ite(i_keep_index, ' KEEP INDEX', NULL); 
   END dyn_drop; 
BEGIN 
   l_cons_nm := UPPER(i_cons_nm); 
   l_tbl_nm  := UPPER(i_tbl_nm); 
 
   assert(i_cons_type IS NOT NULL, 
          l_proc_nm || g_sep_char || 'Must provide constraint type.'); 
           
   assert(i_cons_type IN ('C', 'P', 'U', 'R'), 
          l_proc_nm || g_sep_char || 
          'Constraint type must be [P]rimary, [U]unique, [R]eferential or [C]heck.'); 
 
   IF (obj_exists(l_cons_nm, gc_constraint)) THEN 
    
      IF (l_tbl_nm IS NULL) THEN 
         l_tbl_nm := get_tbl_by_cons(l_cons_nm); 
      ELSE 
         assert(obj_exists(l_tbl_nm, gc_table), 
                l_proc_nm || g_sep_char || l_tbl_nm || ' does not exist.'); 
      END IF; 
 
      p('Dropping constraint '||l_cons_nm||'...'); 
 
      -- If one of the index-backed constraints, get its index first 
      IF (i_cons_type IN ('P', 'U')) THEN 
         l_idx_nm := get_idx_by_cons(l_cons_nm); 
 
         BEGIN 
            dyn_drop; 
         EXCEPTION 
            WHEN lx_ucons_refd_by_fk THEN 
               -- There are FKs that depend on this PK. Save and drop them first. 
               -- Then try again. 
               save_drop_dep_fks(l_tbl_nm); 
               dyn_drop; 
         END; 
 
         -- If the index was created along with the unique constraint with "USING INDEX" 
         -- then it will already be dropped (if i_keep_index was FALSE). 
         IF (i_keep_index = FALSE) THEN 
            drop_idx(l_idx_nm); 
         END IF; 
       
      ELSE 
         -- reserved for Check and Referential constraints with no underlying indexes 
         EXECUTE IMMEDIATE 'ALTER TABLE ' || l_tbl_nm || ' DROP CONSTRAINT ' || 
                           l_cons_nm; 
      END IF; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Constraint '||l_cons_nm||' not found.'); 
   END IF; 
 
END drop_cons; 
 
-------------------------------------------------------------------------------- 
-- get_tablespace_freespace: 
-- Determines how much space, in bytes, is left in the given tablespace. 
--  
-- %param i_tablespace_nm Name of the tablespace to check for existing freespace. 
-------------------------------------------------------------------------------- 
FUNCTION get_tablespace_freespace(i_tablespace_nm IN VARCHAR2) RETURN NUMBER 
IS 
   l_proc_nm user_objects.object_name%TYPE := 'get_tablespace_freespace'; 
   l_freespace NUMBER; 
BEGIN 
   assert(tablespace_exists(i_tablespace_nm), 
      l_proc_nm || g_sep_char || UPPER(i_tablespace_nm) ||' is not a valid tablespace.'); 
           
   SELECT SUM(bytes) 
     INTO l_freespace 
     FROM user_free_space 
    WHERE tablespace_name = UPPER(i_tablespace_nm); 
    
   RETURN l_freespace; 
END get_tablespace_freespace;             
 
-------------------------------------------------------------------------------- 
-- get_obj_used_space: 
-- Determines how much space, in bytes, is used by a given table or index. 
--  
-- %param i_obj_nm Name of the object to check for used space. 
-- %param i_obj_type From package constants. Used either gc_table or gc_index. 
-------------------------------------------------------------------------------- 
FUNCTION get_obj_used_space(i_obj_nm IN VARCHAR2, i_obj_type IN VARCHAR2) RETURN NUMBER 
IS 
   l_proc_nm user_objects.object_name%TYPE := 'get_obj_used_space'; 
   l_used_space NUMBER; 
BEGIN 
   assert(obj_exists(i_obj_nm, i_obj_type), 
      l_proc_nm || g_sep_char || INITCAP(i_obj_type)||' '||i_obj_nm||' does not exist.'); 
       
   SELECT SUM(bytes) 
     INTO l_used_space 
     FROM user_segments 
    WHERE segment_name = i_obj_nm; 
    
   -- Add 25% as fudge factor. Certain operations could actually take double 
   -- the amount, but I believe that happens in TEMP. 
   l_used_space := l_used_space + TRUNC(l_used_space * .25); 
    
   RETURN l_used_space; 
     
END get_obj_used_space; 
 
-------------------------------------------------------------------------------- 
-- check_space: 
-- Determines whether the given object will fit in the new destination tablespace. 
-- Will error with recommendation for datafile/tablespace expansion if the new 
-- tablespace is not big enough. 
--  
-- %param i_move_obj_rec Name of the tablespace to check for existing freespace. 
-------------------------------------------------------------------------------- 
PROCEDURE check_space(i_move_obj_rec type_move_obj_rec) 
IS 
   l_proc_nm user_objects.object_name%TYPE := 'check_space'; 
   l_move_obj_rec type_move_obj_rec; 
BEGIN 
 
   l_move_obj_rec := i_move_obj_rec; 
    
   p('Checking tablespace '||l_move_obj_rec.dest_tablespace|| 
     ' to ensure it has enough space for '||l_move_obj_rec.obj_nm||'...'); 
 
   IF (l_move_obj_rec.obj_type = gc_table) THEN 
      l_move_obj_rec.partitioned_flg := is_tbl_partitioned(l_move_obj_rec.obj_nm); 
   ELSIF (l_move_obj_rec.obj_type = gc_index) THEN 
      l_move_obj_rec.partitioned_flg := is_idx_partitioned(l_move_obj_rec.obj_nm); 
   END IF; 
    
   l_move_obj_rec.space_needed := get_obj_used_space(l_move_obj_rec.obj_nm, l_move_obj_rec.obj_type); 
   l_move_obj_rec.space_free := get_tablespace_freespace(l_move_obj_rec.dest_tablespace); 
 
--   inf(l_proc_nm || g_sep_char || 'Object '||l_move_obj_rec.obj_type||'-'||l_move_obj_rec.obj_nm); 
--   inf(l_proc_nm || g_sep_char || 'Old Tablespace: '||l_move_obj_rec.curr_tablespace); 
--   inf(l_proc_nm || g_sep_char || 'New Tablespace: '||l_move_obj_rec.dest_tablespace); 
--   inf(l_proc_nm || g_sep_char || 'Space needed: '||l_move_obj_rec.space_needed); 
--   inf(l_proc_nm || g_sep_char || 'Space free: '||l_move_obj_rec.space_free); 
    
   IF (l_move_obj_rec.space_needed > l_move_obj_rec.space_free) THEN 
      err(l_proc_nm || g_sep_char || 'At least '|| 
         ROUND((l_move_obj_rec.space_needed - l_move_obj_rec.space_free)/1024/1024,2)|| 
         'MB in additional space needs to be allocated to tablespace '||l_move_obj_rec.dest_tablespace); 
   END IF; 
 
END check_space; 
 
-------------------------------------------------------------------------------- 
-- get_obj_tablespace: 
-- Determines the current tablespace of the given object. If the object is 
-- partitioned, it will attempt to find a distinct tablespace name shared by 
-- all the partitions/subpartitions. Will return NULL if object is a temp table, 
-- or if the partitioned object is stored across multiple tablespaces. 
-- 
-- %design 
--Oracle handles the tablespace_name attribute for partitioned objects in a 
--weird way. If the object is partitioned only, tablespace_name from  
--user_*_partitions can be assumed to be correct. If the object is  
--subpartitioned, tablespace_name from user_*_partitions is unreliable. It is 
--possible to rebuild all the subpartitions for a given partition in a 
--different tablespace, but user_*_partitions will still report the old 
--tablespace. For this reason, this routine delves down to the  
--user_*_subpartitions views when the object is subpartitioned. 
--  
-- %param i_obj_nm Name of the object to check for its tablespace. 
-- %param i_obj_type From package constants. Used either gc_table or gc_index. 
-- 
-- %return The tablespace name where the object is stored. 
-------------------------------------------------------------------------------- 
FUNCTION get_obj_tablespace(i_obj_nm IN VARCHAR2, i_obj_type IN VARCHAR2) RETURN VARCHAR2 
IS 
   l_proc_nm user_objects.object_name%TYPE := 'get_obj_tablespace'; 
   l_obj_nm   user_objects.object_name%TYPE; 
   l_tablespace_nm VARCHAR2(30); 
BEGIN 
   l_obj_nm := UPPER(i_obj_nm); 
    
   assert(obj_exists(l_obj_nm, i_obj_type), 
      l_proc_nm || g_sep_char || INITCAP(i_obj_type)||' '||l_obj_nm||' does not exist.'); 
    
   BEGIN 
      -- Attempt to get the tablespace used by the partitioned object. If the 
      -- object is stored in more than one tablespace, then this function returns 
      -- a NULL. 
      IF (i_obj_type = gc_table) THEN 
         IF (is_tbl_subpartitioned(l_obj_nm)) THEN 
            SELECT DISTINCT tablespace_name 
            INTO l_tablespace_nm 
            FROM user_tab_subpartitions 
            WHERE table_name = UPPER(l_obj_nm); 
         -- Subpartitioned objects are also partitioned. So we use a mutually 
         -- exclusive ELSE here to keep both checks from being evaluated 
         ELSE 
            IF (is_tbl_partitioned(l_obj_nm)) THEN 
               SELECT DISTINCT tablespace_name 
               INTO l_tablespace_nm 
               FROM user_tab_partitions 
               WHERE table_name = UPPER(l_obj_nm); 
            ELSE 
               SELECT tablespace_name 
               INTO l_tablespace_nm 
               FROM user_tables 
               WHERE table_name = UPPER(l_obj_nm); 
            END IF; 
         END IF; 
          
      ELSIF (i_obj_type = gc_index) THEN 
         IF (is_idx_subpartitioned(l_obj_nm)) THEN 
            SELECT DISTINCT tablespace_name 
            INTO l_tablespace_nm 
            FROM user_ind_subpartitions 
            WHERE index_name = l_obj_nm; 
         -- Subpartitioned objects are also partitioned. So we use a mutually 
         -- exclusive ELSE here to keep both checks from being evaluated 
         ELSE 
            IF (is_idx_partitioned(l_obj_nm)) THEN 
               SELECT DISTINCT tablespace_name 
               INTO l_tablespace_nm 
               FROM user_ind_partitions 
               WHERE index_name = l_obj_nm; 
            ELSE 
               SELECT tablespace_name 
               INTO l_tablespace_nm 
               FROM user_indexes 
               WHERE index_name = UPPER(l_obj_nm); 
            END IF; 
         END IF; 
 
      ELSE 
         err(l_proc_nm || g_sep_char ||i_obj_type || 
             ' is not a supported object type.'); 
      END IF; 
       
   EXCEPTION 
      WHEN TOO_MANY_ROWS THEN 
         -- If DISTINCT found more than one value, the first value will still be 
         -- in the variable, so empty it out. 
         l_tablespace_nm := NULL; 
          
         inf(l_proc_nm || g_sep_char || l_obj_nm || ' is stored in more than '|| 
         'one tablespace. Unable to return a single tablespace for this object.'); 
   END; 
    
   RETURN l_tablespace_nm; 
    
END get_obj_tablespace; 
              
-------------------------------------------------------------------------------- 
--                   PUBLIC PROCEDURE AND FUNCTION DEFINITIONS 
-------------------------------------------------------------------------------- 
 
-------------------------------------------------------------------------------- 
FUNCTION get_db_version RETURN NUMBER IS 
   l_version VARCHAR2(30); 
   l_version_num INTEGER := 0; 
BEGIN 
   SELECT SUBSTR(banner, 
                 INSTR(banner, CHR(9), 1, 1) + 1, 
                 INSTR(banner, CHR(9), 1, 2) - INSTR(banner, CHR(9), 1, 1) - 1) version 
     INTO l_version 
     FROM v$version 
    WHERE UPPER(banner) LIKE 'CORE%'; 
   IF (l_version LIKE '9%') THEN 
      l_version_num := 9; 
   ELSIF (l_version LIKE '10%') THEN 
      l_version_num := 10; 
   ELSIF (l_version LIKE '11%') THEN 
      l_version_num := 11; 
   ELSIF (l_version LIKE '8%') THEN 
      l_version_num := 8; 
   ELSIF (l_version LIKE '7%') THEN 
      l_version_num := 7; 
   END IF; 
    
   RETURN l_version_num; 
END get_db_version; 
 
-------------------------------------------------------------------------------- 
FUNCTION data_is_found 
( 
   i_tbl_nm  IN VARCHAR2, 
   i_part_nm IN VARCHAR2 DEFAULT NULL 
) RETURN BOOLEAN IS 
   l_proc_nm user_objects.object_name%TYPE := 'data_is_found'; 
   l_obj_nm  user_objects.object_name%TYPE; 
   l_count   INTEGER := 0; 
    
   lx_partition_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_partition_not_there, -02149); 
BEGIN 
   l_obj_nm := UPPER(i_tbl_nm); 
 
   IF (NOT obj_exists(l_obj_nm, gc_table)) THEN 
      -- If table doesn't exist, we'll pretend it does and has no data. 
      -- Otherwise, calls to drop_tbl end up spitting out two similar messages 
      l_count := 0; 
   ELSE 
      EXECUTE IMMEDIATE 'SELECT COUNT(*) ' || 'FROM ' || l_obj_nm || 
                        ifnn(i_part_nm, ' PARTITION (' || i_part_nm || ') ') || 
                        ' WHERE ROWNUM <= 1' 
         INTO l_count; 
   END IF; 
       
   IF (l_count > 0) THEN 
      RETURN TRUE; 
   ELSE 
      RETURN FALSE; 
   END IF; 
EXCEPTION 
   WHEN lx_partition_not_there then 
      err(l_proc_nm || g_sep_char || 'Partition '||l_obj_nm||'.'||UPPER(i_part_nm)||' not found.'); 
END data_is_found; 
 
-------------------------------------------------------------------------------- 
FUNCTION obj_exists 
( 
   i_obj_nm   IN VARCHAR2, 
   i_obj_type IN VARCHAR2 DEFAULT NULL 
) RETURN BOOLEAN IS 
   l_proc_nm  user_objects.object_name%TYPE := 'obj_exists'; 
   l_obj_nm   user_objects.object_name%TYPE; 
   l_count    INTEGER := 0; 
   l_obj_type user_objects.object_type%TYPE; 
BEGIN 
   l_obj_nm := UPPER(i_obj_nm); 
 
   IF (i_obj_type IS NULL) THEN 
      SELECT COUNT(*) 
        INTO l_count 
        FROM user_objects 
       WHERE object_name = l_obj_nm; 
   ELSE 
      l_obj_type := UPPER(i_obj_type); 
      assert(l_obj_type IN 
             (gc_table, gc_index, gc_package, gc_package_body, gc_constraint,
              gc_sequence, gc_trigger, gc_view, gc_type, gc_type_body, gc_synonym,
              gc_mv, gc_function, gc_procedure), 
             l_proc_nm || g_sep_char || i_obj_type || 
             ' is not a supported object type.'); 
    
      IF (l_obj_type IN (gc_table, gc_index, gc_package, gc_package_body,
                         gc_sequence, gc_trigger, gc_view, gc_type, gc_type_body, gc_synonym,
                         gc_mv, gc_function, gc_procedure)) THEN 
         SELECT COUNT(*) 
           INTO l_count 
           FROM user_objects 
          WHERE object_name = l_obj_nm 
            AND object_type = l_obj_type;
             
      ELSIF (l_obj_type = gc_constraint) THEN 
         SELECT COUNT(*) 
           INTO l_count 
           FROM user_constraints 
          WHERE constraint_name = l_obj_nm; 
      END IF; 
   END IF; 
 
   IF (l_count = 0) THEN 
      RETURN FALSE; 
   ELSE 
      RETURN TRUE; 
   END IF; 
END obj_exists; 
 
-------------------------------------------------------------------------------- 
FUNCTION attr_exists 
( 
   i_obj_nm    IN VARCHAR2, 
   i_attr_nm   IN VARCHAR2, 
   i_attr_type IN VARCHAR2 DEFAULT gc_column 
) RETURN BOOLEAN 
IS 
   l_proc_nm  user_objects.object_name%TYPE := 'attr_exists'; 
   l_obj_nm   user_objects.object_name%TYPE; 
   l_obj_type user_objects.object_type%TYPE; 
   l_attr_nm  VARCHAR2(30); 
   l_attr_type VARCHAR2(20); 
   l_count    INTEGER := 0; 
BEGIN 
   l_obj_nm := UPPER(i_obj_nm); 
   assert(obj_exists(l_obj_nm), 
          l_proc_nm || g_sep_char || l_obj_nm || ' does not exist.'); 
 
   l_obj_type := get_obj_type(l_obj_nm); 
    
   l_attr_type := UPPER(i_attr_type); 
   assert(l_attr_type IN (gc_column, gc_attribute, gc_method, gc_routine,  
                          gc_part, gc_subpart), 
          l_proc_nm || g_sep_char || l_attr_type ||' is not a supported attribute type.');           
    
   l_attr_nm := UPPER(i_attr_nm); 
   -- Based on attribute type, pull count from data dictionary 
   CASE 
      WHEN (l_attr_type = gc_column AND l_obj_type = gc_table ) THEN 
         SELECT COUNT(*) 
         INTO l_count 
         FROM user_tab_columns 
         WHERE table_name = l_obj_nm 
         AND column_name = l_attr_nm; 
          
      WHEN (l_attr_type = gc_attribute AND l_obj_type = gc_type ) THEN 
         SELECT COUNT(*) 
         INTO l_count 
         FROM user_type_attrs 
         WHERE type_name = l_obj_nm 
         AND attr_name = l_attr_nm; 
          
      WHEN (l_attr_type = gc_method AND l_obj_type = gc_type ) THEN 
         SELECT COUNT(*) 
         INTO l_count 
         FROM user_type_methods 
         WHERE type_name = l_obj_nm 
         AND method_name = l_attr_nm; 
          
      WHEN (l_attr_type = gc_routine AND l_obj_type = gc_package ) THEN 
         SELECT COUNT(*) 
         INTO l_count 
         FROM user_arguments 
         WHERE package_name = l_obj_nm 
         AND object_name = l_attr_nm; 
      WHEN (l_attr_type = gc_part AND l_obj_type IN (gc_table, gc_index)) THEN 
         IF (l_obj_type = gc_table) THEN 
            SELECT COUNT(*) 
            INTO l_count 
            FROM user_tab_partitions 
            WHERE table_name = l_obj_nm 
            AND   partition_name = l_attr_nm; 
         ELSIF (l_obj_type = gc_index) THEN 
            SELECT COUNT(*) 
            INTO l_count 
            FROM user_ind_partitions 
            WHERE index_name = l_obj_nm 
            AND   partition_name = l_attr_nm; 
         END IF; 
      WHEN (l_attr_type = gc_subpart AND l_obj_type IN (gc_table, gc_index)) THEN 
         IF (l_obj_type = gc_table) THEN 
            SELECT COUNT(*) 
            INTO l_count 
            FROM user_tab_subpartitions 
            WHERE table_name = l_obj_nm 
            AND   subpartition_name = l_attr_nm; 
         ELSIF (l_obj_type = gc_index) THEN 
            SELECT COUNT(*) 
            INTO l_count 
            FROM user_ind_subpartitions 
            WHERE index_name = l_obj_nm 
            AND   subpartition_name = l_attr_nm; 
         END IF; 
      ELSE 
         err(l_proc_nm || g_sep_char || 'You have asked for the existence of a(n) '||l_attr_type|| 
             ' on a '||l_obj_type||'. This is not a supported combination for'|| 
             ' '||l_proc_nm||'().'); 
   END CASE; 
 
   IF (l_count = 0) THEN 
      RETURN FALSE; 
   ELSE 
      RETURN TRUE; 
   END IF; 
END attr_exists; 
 
-------------------------------------------------------------------------------- 
FUNCTION get_num_rows 
( 
   i_tbl_nm            IN VARCHAR2, 
   i_stale_count_limit IN NUMBER DEFAULT 5 
) RETURN user_tables.num_rows%TYPE IS 
   l_proc_nm       user_objects.object_name%TYPE := 'get_num_rows'; 
   l_tbl_nm      user_tables.table_name%TYPE := UPPER(i_tbl_nm); 
   l_last_analyzed user_tables.last_analyzed%TYPE; 
   l_count         user_tables.num_rows%TYPE := 0; 
   l_temporary     user_tables.TEMPORARY%TYPE; 
BEGIN 
   assert(obj_exists(i_tbl_nm, gc_table), 
          l_proc_nm || g_sep_char || 'Table '|| i_tbl_nm || ' does not exist.'); 
 
   SELECT temporary, 
          last_analyzed, 
          num_rows 
     INTO l_temporary, 
          l_last_analyzed, 
          l_count 
     FROM user_tables 
    WHERE table_name = l_tbl_nm; 
 
   -- Check how long it has been since the table was analyzed. We want at least 
   -- a semi-fresh count. 
   IF (l_temporary = 'Y') THEN 
      l_count := 0; 
   ELSE 
      IF (l_last_analyzed < (SYSDATE - i_stale_count_limit) 
          OR 
          l_last_analyzed IS NULL) THEN 
         -- Get the count from the table itself 
         EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || l_tbl_nm 
            INTO l_count; 
      ELSE 
         -- num_rows already contained in l_count from earlier select 
         NULL; 
      END IF; 
   END IF; 
 
   RETURN l_count; 
 
END get_num_rows; 
 
-------------------------------------------------------------------------------- 
FUNCTION get_cons_columns(i_cons_nm IN VARCHAR2) RETURN VARCHAR2 IS 
   l_proc_nm user_objects.object_name%TYPE := 'get_cons_columns'; 
   l_cols    VARCHAR2(2000); 
   l_cons_nm user_constraints.constraint_name%TYPE; 
BEGIN 
   l_cons_nm := UPPER(i_cons_nm); 
 
   assert(obj_exists(l_cons_nm, gc_constraint), 
          l_proc_nm || g_sep_char ||'Constraint '||l_cons_nm||' does not exist.'); 
           
   FOR lrc IN (SELECT t.column_name 
                 FROM user_cons_columns t 
                WHERE constraint_name = l_cons_nm 
                ORDER BY t.position) LOOP 
    
      l_cols := l_cols || ', ' || LOWER(lrc.column_name); 
   END LOOP; 
 
   IF (LENGTH(l_cols) > 255) THEN 
      RETURN '(Too many to list: see user_cons_columns)'; 
   ELSE 
      RETURN '(' || LTRIM(l_cols, ',') || ' )'; 
   END IF; 
END get_cons_columns; 
 
-------------------------------------------------------------------------------- 
FUNCTION get_tbl_by_cons(i_cons_nm IN VARCHAR2) RETURN VARCHAR2 IS 
   l_proc_nm  user_objects.object_name%TYPE := 'get_table_by_cons'; 
   l_tbl_nm user_constraints.table_name%TYPE; 
BEGIN 
   SELECT table_name 
     INTO l_tbl_nm 
     FROM user_constraints 
    WHERE constraint_name = i_cons_nm; 
 
   RETURN l_tbl_nm; 
EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      warn(l_proc_nm || g_sep_char || 'Constraint ' || i_cons_nm || 
          ' not found.'); 
      RETURN NULL; 
END get_tbl_by_cons; 
 
-------------------------------------------------------------------------------- 
FUNCTION get_tbl_by_idx(i_idx_nm IN VARCHAR2) RETURN VARCHAR2 IS 
   l_proc_nm  user_objects.object_name%TYPE := 'get_tbl_by_idx'; 
   l_tbl_nm user_constraints.table_name%TYPE; 
BEGIN 
   SELECT table_name 
     INTO l_tbl_nm 
     FROM user_indexes 
    WHERE index_name = i_idx_nm; 
 
   RETURN l_tbl_nm; 
EXCEPTION 
   WHEN NO_DATA_FOUND THEN 
      warn(l_proc_nm || g_sep_char || 'Index ' || i_idx_nm || 
          ' not found.'); 
END get_tbl_by_idx; 
 
-------------------------------------------------------------------------------- 
FUNCTION get_search_condition(i_check_nm IN VARCHAR2) RETURN VARCHAR2 IS 
   l_search_condition user_constraints.search_condition%TYPE; 
BEGIN 
   SELECT search_condition 
     INTO l_search_condition 
     FROM user_constraints 
    WHERE constraint_name = i_check_nm; 
 
   RETURN l_search_condition; 
END get_search_condition; 
 
-------------------------------------------------------------------------------- 
FUNCTION get_default_value 
( 
   i_tbl_nm IN VARCHAR2, 
   i_col_nm IN VARCHAR2 
) RETURN VARCHAR2 IS 
   l_default_val user_constraints.search_condition%TYPE; 
BEGIN 
   SELECT data_default 
     INTO l_default_val 
     FROM user_tab_columns 
    WHERE table_name = UPPER(i_tbl_nm) 
      AND column_name = UPPER(i_col_nm); 
 
   RETURN l_default_val; 
END get_default_value; 
 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_tbl 
( 
   i_tbl_nm         IN VARCHAR2, 
   i_drop_with_data IN BOOLEAN DEFAULT FALSE 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_tbl'; 
   l_tbl_nm  user_tables.table_name%TYPE; 
   l_purge_ind VARCHAR2(10); 
    
   lx_table_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_table_not_there, -00942); 
   lx_dependent_tables EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_dependent_tables, -02449); 
 
BEGIN 
   IF (get_db_version >= 10) THEN 
      l_purge_ind := 'PURGE'; 
   ELSIF (get_db_version = 9) THEN 
      l_purge_ind := NULL; 
   END IF; 
    
   l_tbl_nm := UPPER(i_tbl_nm);
   
   IF (obj_exists(l_tbl_nm, gc_table)) THEN 
 
      IF (i_drop_with_data = FALSE) THEN 
         -- assert that table doesn't have any data 
         assert(NOT data_is_found(l_tbl_nm), 
                l_tbl_nm || ' still has data. Cannot drop until emptied.'); 
      ELSE 
         -- if dropping with data is OK, must truncate temp tables first 
         IF (is_tbl_temporary(i_tbl_nm) = TRUE) THEN 
            EXECUTE IMMEDIATE 'TRUNCATE TABLE '||i_tbl_nm; 
         END IF; 
      END IF; 
    
      BEGIN 
         p('Dropping table '||l_tbl_nm||'...'); 
         EXECUTE IMMEDIATE 'DROP TABLE ' || l_tbl_nm ||' '|| l_purge_ind; 
      EXCEPTION 
         WHEN lx_dependent_tables THEN 
    
            save_drop_dep_fks(l_tbl_nm);       
    
            -- try again now that FKs are out of the picture 
            EXECUTE IMMEDIATE 'DROP TABLE ' || l_tbl_nm ||' '|| l_purge_ind; 
    
      END;
   ELSE
      inf(l_proc_nm || g_sep_char || 'Table '||l_tbl_nm||' not found.');
   END IF;
 
END drop_tbl; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_col 
( 
   i_tbl_nm IN VARCHAR2, 
   i_col_nm IN VARCHAR2 
) IS 
   l_proc_nm  user_objects.object_name%TYPE := 'drop_col'; 
   l_tbl_nm   user_tables.table_name%TYPE; 
   l_num_rows user_tables.num_rows%TYPE; 
 
   lx_column_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_column_not_there, -00904); 
BEGIN 
   l_tbl_nm := UPPER(i_tbl_nm); 
   assert(obj_exists(l_tbl_nm, gc_table), 
          l_proc_nm || g_sep_char || l_tbl_nm || ' does not exist.'); 
 
   l_num_rows := get_num_rows(l_tbl_nm); 
 
   IF (l_num_rows < pkgc_huge_table_rowsize) THEN 
      p('Dropping column '||LOWER(i_col_nm)|| ' from '||l_tbl_nm||'...'); 
      EXECUTE IMMEDIATE 'ALTER TABLE ' || i_tbl_nm || ' DROP COLUMN ' || 
                        i_col_nm; 
   ELSE 
      -- Ideally this logic should never be hit. When we design our DROP and  
      -- SET UNUSED calls, it should be done knowing the size of these tables 
      -- in the wild. This is just a backup in case some client has a table that 
      -- is wildly out of control. 
      inf(l_proc_nm || g_sep_char || 'Table '||l_tbl_nm||' has over '||TO_CHAR(l_num_rows)||' rows. '|| 
        'This is too large for a DROP operation. Will set to UNUSED instead.'); 
      set_unused(i_tbl_nm, i_col_nm); 
   END IF; 
    
EXCEPTION 
   WHEN lx_column_not_there THEN 
      inf(l_proc_nm || g_sep_char || 'Column '||LOWER(i_col_nm)||' is not found in table '||l_tbl_nm||'.'); 
END drop_col; 
 
-------------------------------------------------------------------------------- 
PROCEDURE set_unused 
( 
   i_tbl_nm IN VARCHAR2, 
   i_col_nm IN VARCHAR2 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'set_unused'; 
   l_tbl_nm  user_tables.table_name%TYPE; 
   l_count INTEGER := 0; 
    
   lx_column_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_column_not_there, -00904); 
BEGIN 
   l_tbl_nm := UPPER(i_tbl_nm); 
   assert(obj_exists(l_tbl_nm, gc_table), 
          l_proc_nm || g_sep_char || l_tbl_nm || ' does not exist.'); 
 
   p('Setting column '||l_tbl_nm||'.'||UPPER(i_col_nm)||' to UNUSED...'); 
   EXECUTE IMMEDIATE 'ALTER TABLE ' || i_tbl_nm || ' SET UNUSED (' || 
                     i_col_nm || ')'; 
 
EXCEPTION 
   WHEN lx_column_not_there THEN 
      SELECT COUNT(*) 
      INTO l_count 
      FROM user_unused_col_tabs 
      WHERE table_name = l_tbl_nm; 
 
      IF (l_count = 0) THEN 
         warn(l_proc_nm || g_sep_char || 'Column '||UPPER(i_col_nm)||' has either never existed on '|| 
              l_tbl_nm||' or it was recently dropped by another script.'); 
      ELSE 
         inf(l_proc_nm || g_sep_char || 'Table '||l_tbl_nm||' has UNUSED columns. It is likely column '|| 
             UPPER(i_col_nm)||' has already been set UNUSED in a previous run of '|| 
             'this script.'); 
      END IF; 
END set_unused; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_col_list 
( 
   i_tbl_nm   IN VARCHAR2, 
   i_col_list IN VARCHAR2 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_col_list'; 
   l_tbl_nm  user_tables.table_name%TYPE; 
   l_col_list VARCHAR2(4000); 
 
   lx_column_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_column_not_there, -00904); 
BEGIN 
   l_tbl_nm := UPPER(i_tbl_nm); 
   assert(obj_exists(l_tbl_nm, gc_table), 
          l_proc_nm || g_sep_char || l_tbl_nm || ' does not exist.'); 
    
   -- strip parenthesis if the caller mistakenly thought they needed to send them 
   l_col_list := REPLACE(REPLACE(i_col_list,'(',NULL),')',NULL); 
       
   p('Dropping columns '||LOWER(l_col_list)|| ' from '||l_tbl_nm||'...'); 
   EXECUTE IMMEDIATE 'ALTER TABLE ' || l_tbl_nm || ' DROP (' || l_col_list || ')'; 
 
EXCEPTION 
   WHEN lx_column_not_there THEN 
      inf(l_proc_nm || g_sep_char || 'One or more columns in the following list are not found on table '|| 
         l_tbl_nm||': ('||LOWER(l_col_list)||')'); 
 
END drop_col_list; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_idx(i_idx_nm IN VARCHAR2) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_idx'; 
   l_obj_nm user_objects.object_name%TYPE; 
    
   lx_index_used_by_ucons EXCEPTION; -- ucons stands for "unique constraint" 
   PRAGMA EXCEPTION_INIT(lx_index_used_by_ucons, -2429); 
BEGIN 
   l_obj_nm := UPPER(i_idx_nm); 
    
   IF (obj_exists(l_obj_nm, gc_index)) THEN 
      p('Dropping index '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP INDEX ' || l_obj_nm; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Index '||l_obj_nm||' not found. It never existed, or was already dropped.'); 
   END IF; 
EXCEPTION 
   WHEN lx_index_used_by_ucons THEN 
      inf(l_proc_nm || g_sep_char || 'Index '||l_obj_nm||' is used by a unique constraint that must be dropped first.'); 
      drop_pk(l_obj_nm); 
       
END drop_idx; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_pk 
( 
   i_pk_nm      IN VARCHAR2, 
   i_tbl_nm     IN VARCHAR2 DEFAULT NULL, 
   i_keep_index IN BOOLEAN DEFAULT FALSE 
) IS 
   --l_proc_nm user_objects.object_name%TYPE := 'drop_pk'; 
BEGIN 
   drop_cons(i_pk_nm, 'P', i_tbl_nm, i_keep_index); 
END drop_pk; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_uk 
( 
   i_uk_nm      IN VARCHAR2, 
   i_tbl_nm     IN VARCHAR2 DEFAULT NULL, 
   i_keep_index IN BOOLEAN DEFAULT FALSE 
) IS 
   --l_proc_nm user_objects.object_name%TYPE := 'drop_uk'; 
BEGIN 
   drop_cons(i_uk_nm, 'U', i_tbl_nm, i_keep_index); 
END drop_uk; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_fk 
( 
   i_fk_nm  IN VARCHAR2, 
   i_tbl_nm IN VARCHAR2 DEFAULT NULL 
) IS 
   --l_proc_nm user_objects.object_name%TYPE := 'drop_fk'; 
BEGIN 
   drop_cons(i_fk_nm, 'R', i_tbl_nm); 
END drop_fk; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_chk 
( 
   i_chk_nm IN VARCHAR2, 
   i_tbl_nm IN VARCHAR2 DEFAULT NULL 
) IS 
--   l_proc_nm user_objects.object_name%TYPE := 'drop_chk'; 
BEGIN 
   drop_cons(i_chk_nm, 'C', i_tbl_nm); 
END drop_chk; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_syn(i_syn_nm IN VARCHAR2) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_syn'; 
--   lx_private_syn_not_there EXCEPTION; 
--   PRAGMA EXCEPTION_INIT(lx_private_syn_not_there, -01434); 
   l_obj_nm  user_objects.object_name%TYPE; 
BEGIN 
   l_obj_nm := UPPER(i_syn_nm); 
    
   IF (obj_exists(l_obj_nm, gc_synonym)) THEN 
      p('Dropping synonym '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP SYNONYM ' || l_obj_nm; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Private synonym '||l_obj_nm||' not found.'); 
   END IF; 
END drop_syn; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_trig(i_trig_nm IN VARCHAR2)
IS
   l_proc_nm user_objects.object_name%TYPE := 'drop_trig'; 
   l_obj_nm  user_objects.object_name%TYPE; 
BEGIN
   l_obj_nm := UPPER(i_trig_nm); 

   IF (obj_exists(l_obj_nm, gc_trigger)) THEN 
      p('Dropping trigger '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP TRIGGER ' || l_obj_nm; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Trigger '||l_obj_nm||' not found.'); 
   END IF; 
END drop_trig;

-------------------------------------------------------------------------------- 
PROCEDURE drop_view(i_view_nm IN VARCHAR2)
IS
   l_proc_nm user_objects.object_name%TYPE := 'drop_view'; 
   l_obj_nm  user_objects.object_name%TYPE; 
BEGIN
   l_obj_nm := UPPER(i_view_nm); 

   IF (obj_exists(l_obj_nm, gc_view)) THEN 
      p('Dropping view '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP VIEW ' || l_obj_nm; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'View '||l_obj_nm||' not found.'); 
   END IF; 
END drop_view;

-------------------------------------------------------------------------------- 
PROCEDURE drop_mv(i_mv_nm IN VARCHAR2)
IS
   l_proc_nm user_objects.object_name%TYPE := 'drop_mv'; 
   l_obj_nm  user_objects.object_name%TYPE; 
BEGIN
   l_obj_nm := UPPER(i_mv_nm); 

   IF (obj_exists(l_obj_nm, gc_mv)) THEN 
      p('Dropping materialized view '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW ' || l_obj_nm; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Materialized view '||l_obj_nm||' not found.'); 
   END IF; 
END drop_mv;
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_pub_syn(i_syn_nm IN VARCHAR2) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_pub_syn'; 
--   lx_public_syn_not_there EXCEPTION; 
--   PRAGMA EXCEPTION_INIT(lx_public_syn_not_there, -01433); 
   l_count INTEGER := 0; 
   l_obj_nm  user_objects.object_name%TYPE; 
 
   lx_not_big_cheese EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_not_big_cheese, -01031); 
BEGIN 
   l_obj_nm := UPPER(i_syn_nm); 
 
   SELECT COUNT(*) 
   INTO l_count 
   FROM all_synonyms 
   WHERE owner = 'PUBLIC' 
   AND synonym_name = l_obj_nm; 
    
   IF (l_count > 0) THEN 
      p('Dropping public synonym '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM ' || l_obj_nm; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Public synonym '||l_obj_nm||' not found.'); 
   END IF; 
EXCEPTION 
   WHEN lx_not_big_cheese THEN 
      err(l_proc_nm || g_sep_char || 'Current user does not have rights granted to drop public synonyms.'); 
END drop_pub_syn; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_all_pub_syn 
IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_all_pub_syn'; 
   l_schema_nm all_users.username%TYPE; 
   lx_not_big_cheese EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_not_big_cheese, -01031); 
BEGIN 
   l_schema_nm := USER; 
 
   assert(l_schema_nm NOT IN ('SYS','SYSTEM'), 
          l_proc_nm || g_sep_char || l_schema_nm||' cannot be allowed to run this routine. It would break Oracle.'); 
 
   inf(l_proc_nm || g_sep_char || 'Dropping all public synonyms for '||l_schema_nm); 
   FOR lr IN ( 
      SELECT synonym_name 
        FROM all_synonyms 
       WHERE table_owner = l_schema_nm 
         AND owner = 'PUBLIC' 
   ) LOOP 
      EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM '||lr.synonym_name; 
   END LOOP; 
EXCEPTION 
   WHEN lx_not_big_cheese THEN 
      err(l_proc_nm || g_sep_char || 'Current user does not have rights granted to drop public synonyms.'); 
END drop_all_pub_syn; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_all_priv_syn(i_ref_owner IN VARCHAR2 DEFAULT NULL) 
IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_all_priv_syn'; 
   l_schema_nm all_users.username%TYPE; 
BEGIN 
   l_schema_nm := USER; 
   assert(l_schema_nm NOT IN ('SYS','SYSTEM'), 
          l_proc_nm || g_sep_char || l_schema_nm||' cannot be allowed to run this routine.'); 
   IF (i_ref_owner IS NULL) THEN 
      inf(l_proc_nm || g_sep_char || 'Dropping all private synonyms for '||l_schema_nm); 
      FOR lr IN ( 
         SELECT synonym_name 
           FROM user_synonyms 
      ) LOOP 
         EXECUTE IMMEDIATE 'DROP SYNONYM '||lr.synonym_name; 
      END LOOP; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Dropping all '||l_schema_nm||' synonyms to '||i_ref_owner||' objects.'); 
      FOR lr IN ( 
         SELECT synonym_name 
           FROM user_synonyms 
          WHERE table_owner = UPPER(i_ref_owner) 
      ) LOOP 
         EXECUTE IMMEDIATE 'DROP SYNONYM '||lr.synonym_name; 
      END LOOP; 
   END IF; 
END drop_all_priv_syn; 
-------------------------------------------------------------------------------- 
/* 
bcoulam: This routine uses a brute force approach, calling itself in a loop  
until all the dependency issues work themselves out. If this routine is used  
much in the future, it should be revisited to organize the driving cursor by a  
dependency hierarchy so that the whole thing only need run once, not looped. 
*/ 
PROCEDURE drop_all_obj 
IS 
 
--   l_proc_nm user_objects.object_name%TYPE := 'drop_all_obj'; 
   l_object_count           NUMBER;  -- the current count of objects in the schema 
   l_object_count_previous  NUMBER;  -- the previous count of objects in the schema 
   l_sql                    VARCHAR2(1000);  -- the dynamic SQL "drop" statement 
   l_purge_ind              VARCHAR2(10); 
   
   -- a cursor of the "droppable" objects 
   CURSOR cur_obj IS 
    SELECT * 
      FROM user_objects 
     WHERE object_type IN ('FUNCTION', 'PACKAGE', 'PROCEDURE', 'SEQUENCE', 
                           'SYNONYM', 'TABLE', 'TYPE', 'VIEW', 'JAVA SOURCE') 
       AND object_name <> 'DDL_UTILS'; 
 
BEGIN 
 
   purge_dropped_objects(); 
 
   IF (get_db_version >= 10) THEN 
      l_purge_ind := 'PURGE'; 
   ELSIF (get_db_version = 9) THEN 
      l_purge_ind := NULL; 
   END IF; 
   
  -- get the current count of objects in the schema 
  SELECT count(*) 
  INTO l_object_count 
  FROM user_objects; 
   
  -- set the previous object count higher than current to force entry into following loop 
  l_object_count_previous := l_object_count + 1; 
 
  -- keep attempting to drop objects until the object count remains the same or all objects are gone 
  WHILE NOT ( l_object_count_previous = l_object_count OR l_object_count = 0 ) LOOP 
   
    -- remember the count before attempting to drop objects 
    l_object_count_previous := l_object_count; 
 
    -- loop through the droppable objects 
    FOR rec IN cur_obj LOOP 
 
      -- build the drop statement for the current object 
      l_sql := 'DROP ' || rec.object_type || ' "' || rec.object_name||'"'; 
 
      -- if it is a table, add the CASCADE CONSTRAINTS clause to avoid having 
      --   to drop the tables in a dependency-related order. 
      IF rec.object_type = 'TABLE' THEN 
        l_sql := l_sql || ' CASCADE CONSTRAINTS'||' '||l_purge_ind; 
      END IF; 
    
 
      -- run the drop command, ignoring any errors 
      BEGIN 
        EXECUTE IMMEDIATE l_sql; 
      EXCEPTION 
        WHEN OTHERS THEN 
          NULL; 
      END; 
 
    END LOOP; 
 
    -- get the count of objects after the drop statement 
    SELECT COUNT(*) 
    INTO l_object_count 
    FROM user_objects; 
    
  END LOOP; 
     
END drop_all_obj; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_seq(i_seq_nm IN VARCHAR2) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_seq'; 
--   lx_seq_not_there EXCEPTION; 
--   PRAGMA EXCEPTION_INIT(lx_seq_not_there, -02289); 
   l_obj_nm  user_objects.object_name%TYPE; 
BEGIN 
   l_obj_nm := UPPER(i_seq_nm); 
    
   IF (obj_exists(l_obj_nm, gc_sequence)) THEN 
      p('Dropping sequence '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP SEQUENCE ' || l_obj_nm; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Sequence '||l_obj_nm||' not found.'); 
   END IF; 
END drop_seq; 
 
-------------------------------------------------------------------------------- 
PROCEDURE drop_obj(i_obj_nm IN VARCHAR2, i_obj_type IN VARCHAR2 DEFAULT NULL) IS 
   l_proc_nm user_objects.object_name%TYPE := 'drop_obj'; 
   l_obj_nm  user_objects.object_name%TYPE; 
   l_obj_type user_objects.object_type%TYPE; 
BEGIN 
   l_obj_nm := UPPER(i_obj_nm);
   
   -- if caller bothers to supply an object type, ensure it is uppercased and
   -- one of the supported types for DROP
   IF (i_obj_type IS NOT NULL) THEN
      l_obj_type := UPPER(i_obj_type);
      assert(l_obj_type IN 
             (gc_table, gc_index, gc_package, gc_package_body,
              gc_sequence, gc_trigger, gc_view, gc_type, gc_type_body, gc_synonym,
              gc_mv, gc_function, gc_procedure), 
             l_proc_nm || g_sep_char || i_obj_type || 
             ' is not a supported object type.'); 
   END IF;
 
   IF (obj_exists(l_obj_nm, l_obj_type)) THEN 
    
      IF (l_obj_type IS NULL) THEN 
         l_obj_type := get_obj_type(l_obj_nm); 
      END IF; 
 
      p('Dropping '||LOWER(l_obj_type)||' '||l_obj_nm||'...'); 
      EXECUTE IMMEDIATE 'DROP '||l_obj_type||' ' || l_obj_nm; 
    
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Object '||l_obj_nm||' not found.'); 
   END IF; 
END drop_obj; 
 
-- RENAME routines 
-------------------------------------------------------------------------------- 
PROCEDURE rename_tbl 
( 
   i_tbl_nm     IN VARCHAR2, 
   i_new_tbl_nm IN VARCHAR2 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'rename_tbl'; 
   l_obj_nm  user_objects.object_name%TYPE;
   l_new_obj_nm  user_objects.object_name%TYPE;
 
BEGIN 
   assert(i_tbl_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'Old table name cannot be blank/empty/NULL.');

   assert(i_new_tbl_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'New table name cannot be blank/empty/NULL.');

   assert(LENGTH(i_new_tbl_nm) <= 30, 
          l_proc_nm || g_sep_char || i_new_tbl_nm || ' is ' || 
          TO_CHAR(LENGTH(i_new_tbl_nm) - 30) || ' characters too long.'); 
 
   l_obj_nm := UPPER(i_tbl_nm);
   l_new_obj_nm := UPPER(i_new_tbl_nm); 

   -- See if old table exists before trying to rename it 
   IF (obj_exists(l_obj_nm, gc_table)) THEN 
      IF (l_obj_nm <> l_new_obj_nm) THEN
         p('Renaming table ' || l_obj_nm || ' to ' || UPPER(i_new_tbl_nm)); 
         EXECUTE IMMEDIATE 'RENAME ' || i_tbl_nm || ' TO ' || i_new_tbl_nm;
      ELSIF (l_obj_nm = l_new_obj_nm) THEN
         inf(l_proc_nm || g_sep_char || 'Old table name and new table name are the same.');
      END IF;
 
   -- If that fails, see if the new table name already exists 
   ELSIF (obj_exists(i_new_tbl_nm, gc_table)) THEN 
      inf(l_proc_nm || g_sep_char || 'Table ' || UPPER(i_new_tbl_nm) || ' already exists. This is OK.'); 
 
   -- With no success above, something must be wrong    
   ELSE 
      err(l_proc_nm || g_sep_char || 'Both ' || l_obj_nm || ' and ' || UPPER(i_new_tbl_nm) || 
          ' do not exist. Check for spelling and assumption errors.'); 
   END IF; 
 
END rename_tbl; 
 
-------------------------------------------------------------------------------- 
PROCEDURE rename_col 
( 
   i_tbl_nm     IN VARCHAR2, 
   i_col_nm     IN VARCHAR2, 
   i_new_col_nm IN VARCHAR2 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'rename_col'; 
   l_obj_nm  user_objects.object_name%TYPE; 
   l_old_col_nm user_tab_columns.column_name%TYPE; 
   l_new_col_nm user_tab_columns.column_name%TYPE; 
    
   lx_column_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_column_not_there, -00904); 
   lx_column_already_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_column_already_there, -00957);    
BEGIN 
   l_obj_nm := UPPER(i_tbl_nm); 
    
   assert(obj_exists(l_obj_nm, gc_table), 
          l_proc_nm || g_sep_char || 'Table ' || l_obj_nm || ' does not exist.'); 
 
   assert(i_col_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'Old column name cannot be blank/empty/NULL.');

   assert(i_new_col_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'New column name cannot be blank/empty/NULL.');

   assert(LENGTH(i_new_col_nm) <= 30, 
          l_proc_nm || g_sep_char || i_new_col_nm || ' is ' || 
          TO_CHAR(LENGTH(i_new_col_nm) - 30) || ' characters too long.'); 
           
   l_old_col_nm := UPPER(i_col_nm); 
   l_new_col_nm := UPPER(i_new_col_nm); 
    
   assert(l_old_col_nm <> l_new_col_nm,
          l_proc_nm || g_sep_char ||'Both column names are the same. Check call for copy/paste mistake.');

   BEGIN 
      p('Renaming '||l_obj_nm||'.'||l_old_col_nm||' to '||l_new_col_nm||'...'); 
      EXECUTE IMMEDIATE 'ALTER TABLE ' || i_tbl_nm || ' RENAME COLUMN ' || 
                        i_col_nm || ' TO ' || i_new_col_nm; 
   EXCEPTION 
      WHEN lx_column_already_there THEN 
         -- New column found. Script must have already been run. 
         inf(l_proc_nm || g_sep_char || 'Column ' || l_new_col_nm || 
             ' already exists on table ' || l_obj_nm || '. This is OK.'); 
      WHEN lx_column_not_there THEN 
         -- Old name not there. New name not there. Something is wrong. 
         err(l_proc_nm || g_sep_char || 'Table ' || l_obj_nm || ' does not contain column ' || 
             l_old_col_nm || ' or ' || l_new_col_nm||'. '|| 
             'Check for spelling and assumption errors.'); 
   END; 
END rename_col; 
 
-------------------------------------------------------------------------------- 
PROCEDURE rename_idx 
( 
   i_idx_nm     IN VARCHAR2, 
   i_new_idx_nm IN VARCHAR2 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'rename_idx'; 
   l_obj_nm  user_objects.object_name%TYPE; 
   l_new_obj_nm  user_objects.object_name%TYPE;
BEGIN 
   assert(i_idx_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'Old index name cannot be blank/empty/NULL.');

   assert(i_new_idx_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'New index name cannot be blank/empty/NULL.');
 
   assert(LENGTH(i_new_idx_nm) <= 30, 
          l_proc_nm || g_sep_char || i_new_idx_nm || ' is ' || 
          TO_CHAR(LENGTH(i_new_idx_nm) - 30) || ' characters too long.'); 
 
   l_obj_nm := UPPER(i_idx_nm); 
   l_new_obj_nm := UPPER(i_new_idx_nm);
   
   -- try to find the index by old name first 
   IF (obj_exists(l_obj_nm, gc_index)) THEN
      IF (l_obj_nm <> l_new_obj_nm) THEN
         p('Renaming index '||l_obj_nm||' to '||l_new_obj_nm||'...'); 
         EXECUTE IMMEDIATE 'ALTER INDEX ' || i_idx_nm || ' RENAME TO ' || 
                           i_new_idx_nm;
      ELSIF (l_obj_nm = l_new_obj_nm) THEN
         inf(l_proc_nm || g_sep_char || 'Old index name and new index name are the same.');
      END IF;
   -- the first check failed, let's see if the new index name already exists 
   ELSIF (obj_exists(i_new_idx_nm)) THEN 
      inf(l_proc_nm || g_sep_char || 'Index '||l_new_obj_nm||' already exists. This is OK.'); 
   ELSE 
      err(l_proc_nm || g_sep_char || 'Both ' || l_obj_nm || ' and ' || l_new_obj_nm || 
          ' do not exist. Check for spelling and assumption errors.'); 
   END IF; 
END rename_idx; 
 
-------------------------------------------------------------------------------- 
PROCEDURE rename_cons 
( 
   i_cons_nm     IN VARCHAR2, 
   i_new_cons_nm IN VARCHAR2 
) IS 
   l_proc_nm    user_objects.object_name%TYPE := 'rename_cons'; 
   l_obj_nm     user_objects.object_name%TYPE;
   l_new_obj_nm  user_objects.object_name%TYPE;
   l_cons_tbl   user_constraints.table_name%TYPE; 
   l_cons_type  user_constraints.constraint_type%TYPE; 
   l_cons_index user_constraints.index_name%TYPE; 
 
BEGIN 
   assert(i_cons_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'Old constraint name cannot be blank/empty/NULL.');
          
   assert(i_new_cons_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'New constraint name cannot be blank/empty/NULL.');
   
   
   assert(LENGTH(i_new_cons_nm) <= 30, 
          l_proc_nm || g_sep_char || i_new_cons_nm || ' is ' || 
          TO_CHAR(LENGTH(i_new_cons_nm) - 30) || ' characters too long.'); 
 
   l_obj_nm := UPPER(i_cons_nm); 
   l_new_obj_nm := UPPER(i_new_cons_nm);

   -- try to find the constraint by old name first 
   BEGIN 
      SELECT table_name, 
             constraint_type, 
             index_name 
        INTO l_cons_tbl, 
             l_cons_type, 
             l_cons_index 
        FROM user_constraints 
       WHERE constraint_name = l_obj_nm; 
    
      IF (l_obj_nm <> l_new_obj_nm) THEN
         p('Renaming constraint '||l_obj_nm||' to '||l_new_obj_nm||'...'); 
         EXECUTE IMMEDIATE 'ALTER TABLE ' || l_cons_tbl || 
                           ' RENAME CONSTRAINT ' || i_cons_nm || ' TO ' || 
                           i_new_cons_nm;
      ELSIF (l_obj_nm = l_new_obj_nm) THEN
         inf(l_proc_nm || g_sep_char || 'Old constraint name and new constraint name are the same.');
      END IF;
    
      -- If the above succeeds, then the object exists. Let's now rename the underlying 
      -- index if it is a PK or UK and doesn't match the new constraint name. 
      IF (l_cons_type IN ('P','U')) THEN 
         IF (l_cons_index = l_new_obj_nm) THEN 
            NULL; -- do nothing, constraint and index now match 
         ELSE 
            rename_idx(l_cons_index, i_new_cons_nm); 
         END IF; 
      END IF; 
    
   EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
         -- try to find the constraint by the new name 
         BEGIN 
            SELECT table_name, 
                   constraint_type, 
                   index_name 
              INTO l_cons_tbl, 
                   l_cons_type, 
                   l_cons_index 
              FROM user_constraints 
             WHERE constraint_name = l_new_obj_nm; 
          
            IF (l_cons_type IN ('P','U')) THEN 
               IF (l_cons_index = l_new_obj_nm) THEN 
                  inf(l_proc_nm || g_sep_char || 'Constraint ' || l_new_obj_nm || 
                         ' already exists and matches associated index name. This is OK.'); 
               ELSE 
                  -- Somehow the new constraint exists, but doesn't match its underlying index. Fix it. 
                  rename_idx(l_cons_index, i_new_cons_nm); 
               END IF; 
            ELSE 
               inf(l_proc_nm || g_sep_char || 'Constraint ' || l_new_obj_nm || 
                   ' already exists. This is OK.'); 
            END IF;          
         EXCEPTION 
            WHEN NO_DATA_FOUND THEN 
               err(l_proc_nm || g_sep_char || 'Constraint ' || l_obj_nm || 
                   ' does not exist. Nor does the new name ' || 
                   l_new_obj_nm||'. '|| 
                   'Check for spelling and assumption errors.'); 
         END; 
   END; 
 
END rename_cons; 
 
-------------------------------------------------------------------------------- 
PROCEDURE rename_seq 
( 
   i_seq_nm     IN VARCHAR2, 
   i_new_seq_nm IN VARCHAR2 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'rename_seq'; 
   l_obj_nm  user_objects.object_name%TYPE; 
   l_new_obj_nm user_objects.object_name%TYPE;
 
BEGIN 
   assert(i_seq_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'Old sequence name cannot be blank/empty/NULL.');

   assert(i_new_seq_nm IS NOT NULL,
          l_proc_nm || g_sep_char || 'New sequence name cannot be blank/empty/NULL.');

   l_obj_nm := UPPER(i_seq_nm);
   l_new_obj_nm := UPPER(i_new_seq_nm);
 
   assert(LENGTH(i_new_seq_nm) <= 30, 
          l_proc_nm || g_sep_char || i_new_seq_nm || ' is ' || 
          TO_CHAR(LENGTH(i_new_seq_nm) - 30) || ' characters too long.'); 
 
   -- See if old sequence exists before trying to rename it 
   IF (obj_exists(l_obj_nm, gc_sequence)) THEN 
      IF (l_obj_nm <> l_new_obj_nm) THEN
         p('Renaming sequence ' || l_obj_nm || ' to ' || l_new_obj_nm); 
         EXECUTE IMMEDIATE 'RENAME ' || i_seq_nm || ' TO ' || i_new_seq_nm; 
      ELSIF (l_obj_nm = l_new_obj_nm) THEN
         inf(l_proc_nm || g_sep_char || 'Old sequence name and new sequence name are the same.');
      END IF;
 
   -- If that fails, see if the new sequence name already exists 
   ELSIF (obj_exists(l_new_obj_nm, gc_sequence)) THEN 
      inf(l_proc_nm || g_sep_char || 'Sequence ' || l_new_obj_nm || ' already exists. This is OK.'); 
 
   -- With no success above, something must be wrong    
   ELSE 
      err(l_proc_nm || g_sep_char || 'Both ' || l_obj_nm || ' and ' || l_new_obj_nm || 
          ' do not exist. Check for spelling and assumption errors.'); 
   END IF; 
 
END rename_seq; 
 
-- MOVE routines 
-------------------------------------------------------------------------------- 
PROCEDURE move_tbl 
( 
   i_tbl_nm         IN VARCHAR2, 
   i_new_tablespace IN VARCHAR2 
) IS 
   l_proc_nm             user_objects.object_name%TYPE := 'move_tbl'; 
   l_move_obj_rec        type_move_obj_rec; 
BEGIN 
   assert(i_new_tablespace IS NOT NULL, 
          l_proc_nm || g_sep_char || 'Please provide a tablespace name.'); 
 
   assert(tablespace_exists(i_new_tablespace), 
          l_proc_nm || g_sep_char || i_new_tablespace||' does not exist. '|| 
          'Please provide a real or accessible tablespace.'); 
 
   l_move_obj_rec.obj_nm := UPPER(i_tbl_nm); 
   l_move_obj_rec.obj_type := gc_table; 
   l_move_obj_rec.dest_tablespace := UPPER(i_new_tablespace); 
 
   assert(obj_exists(l_move_obj_rec.obj_nm, l_move_obj_rec.obj_type), 
          l_proc_nm || g_sep_char || 'Table ' || l_move_obj_rec.obj_nm || 
          ' does not exist.'); 
 
   assert(is_tbl_partitioned(l_move_obj_rec.obj_nm) = FALSE, 
          l_proc_nm || g_sep_char || 
          'Partitioned tables are not supported. ' || l_move_obj_rec.obj_nm || 
          ' is partitioned.'); 
 
   SELECT tablespace_name 
     INTO l_move_obj_rec.curr_tablespace 
     FROM user_tables 
    WHERE table_name = l_move_obj_rec.obj_nm; 
 
   IF (l_move_obj_rec.curr_tablespace <> l_move_obj_rec.dest_tablespace) THEN 
      check_space(l_move_obj_rec); 
       
      -- If it passed check_space() above with no error raised, then we should be good to go 
      p('Moving table ' || l_move_obj_rec.obj_nm || ' from '||l_move_obj_rec.curr_tablespace|| 
        ' to ' ||l_move_obj_rec.dest_tablespace||'...'); 
      EXECUTE IMMEDIATE 'ALTER TABLE ' || l_move_obj_rec.obj_nm || ' MOVE TABLESPACE '|| 
         l_move_obj_rec.dest_tablespace; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Table ' || l_move_obj_rec.obj_nm || ' is already in tablespace ' || 
          l_move_obj_rec.dest_tablespace); 
   END IF; 
END move_tbl; 
 
-------------------------------------------------------------------------------- 
PROCEDURE move_idx 
( 
   i_idx_nm         IN VARCHAR2, 
   i_new_tablespace IN VARCHAR2 
) IS 
   l_proc_nm             user_objects.object_name%TYPE := 'move_idx'; 
   l_move_obj_rec        type_move_obj_rec; 
BEGIN 
   assert(i_new_tablespace IS NOT NULL, 
          l_proc_nm || g_sep_char || 'Please provide a tablespace name.'); 
 
   assert(tablespace_exists(i_new_tablespace), 
          l_proc_nm || g_sep_char || i_new_tablespace||' is not a valid tablespace. '|| 
          'Please provide a real or accessible tablespace.'); 
 
   l_move_obj_rec.obj_nm := UPPER(i_idx_nm); 
   l_move_obj_rec.obj_type := gc_index; 
   l_move_obj_rec.dest_tablespace := UPPER(i_new_tablespace); 
 
   -- get current tablespace of index 
   l_move_obj_rec.curr_tablespace := get_obj_tablespace(l_move_obj_rec.obj_nm, l_move_obj_rec.obj_type); 
 
   -- Check new tablespace versus current 
   IF (l_move_obj_rec.curr_tablespace IS NULL) THEN 
 
      inf(l_proc_nm || g_sep_char || 'Ceasing requested operation. Unable to '|| 
         'determine current tablespace of index '||l_move_obj_rec.obj_nm); 
 
   ELSIF (l_move_obj_rec.curr_tablespace <> l_move_obj_rec.dest_tablespace) THEN 
 
      check_space(l_move_obj_rec); 
 
      -- If it passed check_space() above with no error raised, then we should be good to go 
      rebuild_idx(l_move_obj_rec.obj_nm, l_move_obj_rec.dest_tablespace); 
 
   ELSIF (l_move_obj_rec.curr_tablespace = l_move_obj_rec.dest_tablespace) THEN 
 
      inf(l_proc_nm || g_sep_char || 'Index ' || l_move_obj_rec.obj_nm || ' is already in tablespace ' || 
          l_move_obj_rec.dest_tablespace); 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Reached unexpected logic branch.'); 
   END IF; 
 
END move_idx; 
 
-------------------------------------------------------------------------------- 
PROCEDURE rebuild_idx 
( 
   i_idx_nm             IN VARCHAR2, 
   i_new_tablespace     IN VARCHAR2 DEFAULT NULL, 
   i_part_nm            IN VARCHAR2 DEFAULT NULL, 
   i_subpart_nm         IN VARCHAR2 DEFAULT NULL, 
   i_compute_statistics IN BOOLEAN DEFAULT TRUE, 
   i_online             IN BOOLEAN DEFAULT FALSE 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'rebuild_idx'; 
   l_obj_nm  user_objects.object_name%TYPE; 
 
   CURSOR cur_ip IS 
      SELECT index_name, 
             partition_name 
        FROM user_ind_partitions 
       WHERE index_name = l_obj_nm 
       ORDER BY partition_position; 
 
   CURSOR cur_isp IS 
      SELECT ip.index_name, 
             ip.partition_name, 
             isp.subpartition_name 
        FROM user_ind_partitions    ip, 
             user_ind_subpartitions isp 
       WHERE ip.index_name = l_obj_nm 
         AND ip.partition_name = isp.partition_name 
         AND isp.index_name = ip.index_name 
       ORDER BY ip.partition_position, 
                isp.subpartition_position; 
 
BEGIN 
   IF (get_db_version = 9) THEN 
      assert((i_online IS NOT NULL AND i_compute_statistics IS NULL) OR 
             (i_online IS NULL AND i_compute_statistics IS NOT NULL) OR 
             (i_online = TRUE AND i_compute_statistics = FALSE) OR 
             (i_online = FALSE AND i_compute_statistics = TRUE), 
             'ONLINE and COMPUTE STATISTICS cannot be used together on 9i'); 
   END IF; 
 
   l_obj_nm := UPPER(i_idx_nm); 
 
   assert(obj_exists(l_obj_nm, gc_index), 
          l_proc_nm || g_sep_char || 'Index ' || l_obj_nm || 
          ' does not exist.'); 
 
   IF (i_new_tablespace IS NOT NULL) THEN 
      assert(tablespace_exists(i_new_tablespace), 
             l_proc_nm || g_sep_char || UPPER(i_new_tablespace) || 
             ' is not a valid tablespace.'); 
   END IF; 
 
   -- In case this is being called recursively, this check ensures that we are 
   -- only looking up partitioning info if we haven't already done so.    
   IF (i_part_nm IS NULL AND i_subpart_nm IS NULL) THEN 
      -- Call myself recursively for each [sub]partition if this rebuild request is 
      -- for a partitioned index. 
      IF (is_idx_partitioned(l_obj_nm)) THEN 
         -- Determine if it is also subpartitioned 
         IF (is_idx_subpartitioned(l_obj_nm)) THEN 
            -- Call myself for each subpartition 
            p('Rebuilding subpartitioned index ' || l_obj_nm ||  
              ifnn(i_new_tablespace,' in '||UPPER(i_new_tablespace),NULL)||'...'); 
            FOR lr IN cur_isp LOOP 
               tag_session(pkgc_pkg_nm, l_proc_nm, lr.index_name || g_sep_char || lr.partition_name||'.'||lr.subpartition_name); 
               rebuild_idx(lr.index_name, i_new_tablespace, lr.partition_name, lr.subpartition_name); 
               untag_session; 
            END LOOP; 
         ELSE 
            -- Call myself for each partition 
            p('Rebuilding partitioned index ' || l_obj_nm || 
              ifnn(i_new_tablespace,' in '||UPPER(i_new_tablespace),NULL)||'...'); 
            FOR lr IN cur_ip LOOP 
               tag_session(pkgc_pkg_nm, l_proc_nm, lr.index_name || g_sep_char || lr.partition_name); 
               rebuild_idx(lr.index_name, i_new_tablespace, lr.partition_name); 
               untag_session; 
            END LOOP; 
         END IF; 
      ELSE 
         p('Rebuilding index ' || l_obj_nm ||  
              ifnn(i_new_tablespace,' in '||UPPER(i_new_tablespace),NULL)||'...'); 
         EXECUTE IMMEDIATE 'ALTER INDEX ' || l_obj_nm || ' REBUILD ' || 
                           ifnn(i_new_tablespace,'TABLESPACE ' || i_new_tablespace,NULL) --|| 
                           --ifnn(bool_to_str(i_online), ' ONLINE', NULL) || 
                           --ifnn(bool_to_str(i_compute_statistics),' COMPUTE STATISTICS',NULL) 
                           ; 
      END IF; 
   ELSE 
      -- either part or subpart was passed in, figure out which one and perform accordingly 
      IF (i_part_nm IS NOT NULL AND i_subpart_nm IS NOT NULL) THEN 
         p('Rebuilding subpartition ' || l_obj_nm || '.' || 
           UPPER(i_part_nm) || '.' || UPPER(i_subpart_nm) || '...'); 
         EXECUTE IMMEDIATE 'ALTER INDEX ' || l_obj_nm || 
                           ' REBUILD SUBPARTITION ' || i_subpart_nm || 
                           ifnn(i_new_tablespace,' TABLESPACE ' || i_new_tablespace,NULL)-- || 
                           --ifnn(bool_to_str(i_online), ' ONLINE', NULL) 
                           ; 
         -- compute statistics not allowed for subpartitions, and actually it 
         -- seems that statistics are being computed automatically anyway. 
      ELSIF (i_part_nm IS NOT NULL) THEN 
         assert(is_idx_subpartitioned(l_obj_nm) = FALSE, 
            l_proc_nm || g_sep_char || l_obj_nm || 
            ' is subpartitioned. You will need to rebuild each subpartition individually.'); 
         p('Rebuilding partition ' || l_obj_nm || '.' || UPPER(i_part_nm) ||'...'); 
         EXECUTE IMMEDIATE 'ALTER INDEX ' || l_obj_nm || 
                           ' REBUILD PARTITION ' || i_part_nm || 
                           ifnn(i_new_tablespace,' TABLESPACE ' || i_new_tablespace,NULL)-- || 
                           --ifnn(bool_to_str(i_online), ' ONLINE', NULL) 
                           ; 
         -- compute statistics not allowed for subpartitions, and actually it 
         -- seems that statistics are being computed automatically anyway. 
      ELSE 
         err(l_proc_nm || g_sep_char || 'The manner in which you have called ' || l_proc_nm || 
             ' is not supported.'); 
      END IF; 
   END IF; 
 
END rebuild_idx; 
 
-------------------------------------------------------------------------------- 
PROCEDURE purge_dropped_objects 
IS 
BEGIN 
   IF (get_db_version >= 10) THEN 
      p('Purging the RECYCLEBIN...'); 
      EXECUTE IMMEDIATE ('PURGE RECYCLEBIN'); 
   END IF; 
END purge_dropped_objects; 
 
-------------------------------------------------------------------------------- 
-- See the public declaration for documentation on the other parameters. This is  
-- the private version of tag_session. This version is only meant to be used by  
-- routines inside the ddl_utils package body. 
--  
-- %param i_num_rows If given, will only tag the session if the number of rows is 
--          greater than a package constant (currently set to 500K rows). 
--          This parameter is really meant to be called by routines private to  
--          ddl_utils which take a count for a table operation before calling  
--          tag_session. External callers of tag_session should pretend this  
--          parameter doesn't exist. If not given (as it will not be when called 
--          publicly), it will ensure the session is tagged. 
-------------------------------------------------------------------------------- 
PROCEDURE tag_session 
( 
   i_module   IN VARCHAR2, 
   i_action   IN VARCHAR2, 
   i_info     IN VARCHAR2, 
   i_num_rows IN NUMBER 
) IS 
BEGIN 
   IF (NVL(i_num_rows, pkgc_large_op_rowsize) >= pkgc_large_op_rowsize) THEN 
      dbms_application_info.set_module(i_module, i_action); 
      dbms_application_info.set_client_info(SUBSTR(i_info, 1, 64)); 
   END IF; 
END tag_session; 
 
-------------------------------------------------------------------------------- 
-- Public version of tag_session. 
-------------------------------------------------------------------------------- 
PROCEDURE tag_session 
( 
   i_module   IN VARCHAR2, 
   i_action   IN VARCHAR2, 
   i_info     IN VARCHAR2 
) IS 
BEGIN 
   tag_session(i_module, i_action, i_info, NULL); 
END tag_session; 
 
-------------------------------------------------------------------------------- 
PROCEDURE untag_session IS 
BEGIN 
   dbms_application_info.set_client_info(NULL); 
   dbms_application_info.set_module(NULL, NULL); 
END untag_session; 
 
-------------------------------------------------------------------------------- 
PROCEDURE print_dep_fks(i_obj_nm IN VARCHAR2) 
IS 
   l_proc_nm  user_objects.object_name%TYPE := 'print_dep_fks'; 
   l_obj_nm   user_objects.object_name%TYPE; 
   l_dep_fk_names  type_obj_nm_arr; 
   l_arr_idx user_objects.object_name%TYPE; 
BEGIN 
   l_obj_nm := UPPER(i_obj_nm); 
    
   assert(obj_exists(l_obj_nm), 
          l_proc_nm || g_sep_char || l_obj_nm || ' does not exist.'); 
    
   assert(get_obj_type(l_obj_nm) IN (gc_table, gc_index, gc_constraint), 
          l_proc_nm || g_sep_char || l_obj_nm || ' must be a Table, PK, UK or Index.'); 
           
   l_dep_fk_names  := get_dep_fks(l_obj_nm); 
    
--   IF (l_dep_fk_names IS NOT NULL AND l_dep_fk_names.COUNT > 0) THEN 
   IF (l_dep_fk_names.COUNT > 0) THEN 
      p('The foreign keys dependent on '||l_obj_nm||' are:'); 
      l_arr_idx := l_dep_fk_names.FIRST; 
      WHILE l_arr_idx IS NOT NULL 
      LOOP 
        p(l_arr_idx);      
        -- move to next element 
        l_arr_idx := l_dep_fk_names.NEXT(l_arr_idx); 
      END LOOP; 
       
--      FOR i IN l_dep_fk_names.FIRST..l_dep_fk_names.LAST LOOP 
--         p(l_dep_fk_names(i)); 
--      END LOOP; 
   END IF; 
END print_dep_fks; 
 
-------------------------------------------------------------------------------- 
PROCEDURE recreate_dep_fks 
IS 
   l_proc_nm  user_objects.object_name%TYPE := 'recreate_dep_fks'; 
BEGIN 
 
   IF (g_dep_fks IS NOT NULL AND g_dep_fks.COUNT > 0) THEN 
      process_constraint_list(g_dep_fks); 
      g_dep_fks := empty_dep_fks;       
   ELSE 
      warn(l_proc_nm || g_sep_char || 'There are no foreign key specs stored in DDL_UTILS.G_DEP_FKS.'); 
      p('If you expected some to be here, there must have been a session drop '|| 
        'and reconnect in between the time that G_DEP_FKS was filled and now. '|| 
        'You are in a pickle unless you have a Log file of the CR where '|| 
        'you dropped the parent table. This Log file will show the FK names dropped.'); 
   END IF; 
END recreate_dep_fks; 
 
-------------------------------------------------------------------------------- 
PROCEDURE process_constraint_list(i_cons_recarr IN type_constraint_recarr) 
IS 
   l_proc_nm  user_objects.object_name%TYPE := 'process_constraint_list'; 
--   lx_cannot_drop EXCEPTION; PRAGMA EXCEPTION_INIT(lx_cannot_drop,-02443); 
--   lx_cannot_rename EXCEPTION; PRAGMA EXCEPTION_INIT(lx_cannot_rename,-23292); 
   lx_pk_already_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_pk_already_there,-02260); 
   lx_uk_already_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_uk_already_there,-02261); 
   lx_fk_already_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_fk_already_there,-02275); 
   lx_chk_already_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_chk_already_there,-02264); 
    
   l_ddl VARCHAR2(2000); 
BEGIN 
   FOR i IN i_cons_recarr.FIRST..i_cons_recarr.LAST  LOOP 
      IF (i_cons_recarr(i).old_constraint_name IS NOT NULL AND 
          i_cons_recarr(i).constraint_name IS NULL) THEN 
          
         drop_cons(i_cons_recarr(i).old_constraint_name, 
                   i_cons_recarr(i).constraint_type, 
                   i_cons_recarr(i).table_name 
                   -- made judgement call to not worry about keeping index 
         );              
 
      ELSIF ((i_cons_recarr(i).old_constraint_name IS NOT NULL AND 
              i_cons_recarr(i).constraint_name IS NOT NULL) 
             AND 
             (i_cons_recarr(i).old_constraint_name <> i_cons_recarr(i).constraint_name) 
            ) THEN 
 
         rename_cons(i_cons_recarr(i).old_constraint_name, 
                     i_cons_recarr(i).constraint_name);             
 
      ELSIF (i_cons_recarr(i).old_constraint_name IS NULL AND 
             i_cons_recarr(i).constraint_name IS NOT NULL) THEN 
              
         p('Creating constraint '||i_cons_recarr(i).constraint_name||'...'); 
         l_ddl := 'ALTER TABLE '||i_cons_recarr(i).table_name|| 
                  '  ADD CONSTRAINT '||i_cons_recarr(i).constraint_name||' '; 
 
         IF (i_cons_recarr(i).constraint_type = 'R') THEN 
            l_ddl := l_ddl|| 
                     '  FOREIGN KEY '||i_cons_recarr(i).constraint_columns|| 
                     '  REFERENCES '||i_cons_recarr(i).ref_table_name|| 
                     '  '||i_cons_recarr(i).ref_constraint_columns|| 
                     '  '||i_cons_recarr(i).delete_rule|| 
                     '  '||i_cons_recarr(i).status|| 
                     '  '||i_cons_recarr(i).validated; 
         ELSIF (i_cons_recarr(i).constraint_type = 'P') THEN 
            l_ddl := l_ddl|| 
                    '  PRIMARY KEY '||i_cons_recarr(i).constraint_columns|| 
                    '  USING INDEX '||i_cons_recarr(i).index_name|| 
                    '  TABLESPACE '||i_cons_recarr(i).tablespace_name|| 
                    '  '||i_cons_recarr(i).status|| 
                    '  '||i_cons_recarr(i).validated; 
         ELSIF (i_cons_recarr(i).constraint_type = 'U') THEN 
            l_ddl := l_ddl|| 
                    '  UNIQUE '||i_cons_recarr(i).constraint_columns|| 
                    '  USING INDEX '||i_cons_recarr(i).index_name|| 
                    '  TABLESPACE '||i_cons_recarr(i).tablespace_name|| 
                    '  '||i_cons_recarr(i).status|| 
                    '  '||i_cons_recarr(i).validated; 
         ELSIF (i_cons_recarr(i).constraint_type = 'C') THEN 
            l_ddl := l_ddl|| 
                    '  CHECK '||i_cons_recarr(i).check_condition|| 
                    '  '||i_cons_recarr(i).status|| 
                    '  '||i_cons_recarr(i).validated; 
         END IF; 
          
         BEGIN 
            EXECUTE IMMEDIATE l_ddl; 
         EXCEPTION 
            WHEN lx_pk_already_there  OR 
                 lx_uk_already_there  OR  
                 lx_fk_already_there  OR  
                 lx_chk_already_there THEN 
                  
               inf(l_proc_nm || g_sep_char ||i_cons_recarr(i).constraint_name || 
                   ' already exists.'); 
         END; 
          
      ELSE 
         err(l_proc_nm || g_sep_char || 'Cannot operate on record '||i|| 
             '. Please see the notes for this routine in the package spec.'); 
      END IF; 
       
   END LOOP; 
END process_constraint_list; 
 
-------------------------------------------------------------------------------- 
PROCEDURE remove_parallel(i_obj_nm IN VARCHAR2) IS 
   l_proc_nm  user_objects.object_name%TYPE := 'remove_parallel'; 
   l_obj_nm   user_objects.object_name%TYPE; 
   l_obj_type user_objects.object_type%TYPE; 
BEGIN 
   l_obj_nm := UPPER(i_obj_nm); 
 
   assert(obj_exists(l_obj_nm), 
          l_proc_nm || g_sep_char || l_obj_nm || ' does not exist.'); 
 
   l_obj_type := get_obj_type(l_obj_nm); 
 
   assert(l_obj_type IN (gc_table, gc_index), 
          l_proc_nm || g_sep_char || l_obj_type || 
          ' is not a supported object type.'); 
 
   p('Removing PARALLEL attributes from ' || LOWER(l_obj_type) || ' ' || 
     l_obj_nm || '...'); 
   EXECUTE IMMEDIATE 'ALTER ' || l_obj_type || ' ' || l_obj_nm || ' NOPARALLEL'; 
 
END remove_parallel; 
 
-------------------------------------------------------------------------------- 
PROCEDURE remove_parallel_all IS 
   l_45813_index_name user_indexes.index_name%TYPE := 'NM_STTLITMDTL_STTLID_IDX'; 
    
   CURSOR cur_parallel_items IS 
      SELECT gc_table   AS object_type, 
             table_name AS object_name 
        FROM user_tables 
       WHERE (TRIM(DEGREE) <> '1' OR TRIM(INSTANCES) <> '1') 
         AND table_name NOT LIKE 'SYS%' 
         AND table_name NOT LIKE 'BIN$%' 
      UNION ALL 
      SELECT gc_index   AS object_type, 
             index_name AS object_name 
        FROM user_indexes 
       WHERE (TRIM(DEGREE) <> '1' OR TRIM(INSTANCES) <> '1') 
         AND index_type = 'NORMAL' 
         AND index_name NOT LIKE 'SYS%' 
         AND index_name NOT LIKE 'BIN$%' 
         AND index_name <> l_45813_index_name -- 45813 
         ; 
 
BEGIN 
   FOR lr_item IN cur_parallel_items LOOP 
      p('Setting ' || LOWER(lr_item.object_type) || ' ' || lr_item.object_name || 
        ' to NOPARALLEL...'); 
      EXECUTE IMMEDIATE 'ALTER ' || lr_item.object_type || ' ' || 
                        lr_item.object_name || ' NOPARALLEL'; 
   END LOOP; 
    
   -- CR45813 demands PARALLEL 4 for NM_STTLITMDTL_STTLID_IDX 
   IF (obj_exists(l_45813_index_name, gc_index)) THEN 
      -- We had a period of time where our scripts were removing parallel from 
      -- everything. This little addition ensures this one index gets parallel 
      -- until we determine it no longer needs it. 
      p('Setting INDEX '|| l_45813_index_name || 
        ' back to PARALLEL...'); 
      EXECUTE IMMEDIATE 'ALTER INDEX '||l_45813_index_name||' PARALLEL 4'; 
   END IF; 
 
END remove_parallel_all; 
 
-------------------------------------------------------------------------------- 
PROCEDURE add_logging_all 
IS 
   -- Cursors for tables 
   CURSOR cur_nolog_tables IS 
      SELECT table_name 
        FROM user_tables 
       WHERE TEMPORARY = 'N' 
         AND logging IN ('NO', 'NONE'); -- avoids temporary, partitioned and IOT's where logging is NULL 
 
   CURSOR cur_nolog_parts9i IS 
      SELECT DISTINCT table_name, 
                      partition_name 
        FROM user_tab_subpartitions 
       WHERE logging IN ('NO', 'NONE'); 
 
   -- Cursors for indexes 
   CURSOR cur_nolog_indexes IS 
      SELECT table_name, 
             index_name, 
             index_type 
        FROM user_indexes 
       WHERE temporary = 'N' -- temporary indexes show a logging attribute that can't be altered 
         AND logging IN ('NO', 'NONE'); -- eliminates partitioned indexes whose logging attribute is NULL 
 
   CURSOR cur_nolog_indparts9i IS 
      SELECT DISTINCT index_name, 
                      partition_name 
        FROM user_ind_subpartitions 
       WHERE logging IN ('NO', 'NONE'); 
 
   l_cv SYS_REFCURSOR; 
   l_obj_name VARCHAR2(30); 
   l_part_name VARCHAR2(30); 
    
   l_version INTEGER := 0; 
 
BEGIN 
 
   l_version := get_db_version; 
 
   FOR lr IN cur_nolog_tables LOOP 
      p('ALTER TABLE ' || lr.table_name || ' LOGGING'); 
      EXECUTE IMMEDIATE 'ALTER TABLE ' || lr.table_name || ' LOGGING'; 
   END LOOP; 
 
   FOR lr IN cur_nolog_indexes LOOP 
      IF (lr.index_type LIKE 'IOT%') THEN 
         p('ALTER TABLE ' || lr.table_name || ' LOGGING'); 
         EXECUTE IMMEDIATE 'ALTER TABLE ' || lr.table_name || ' LOGGING'; 
      ELSE 
         p('ALTER INDEX ' || lr.index_name || ' LOGGING'); 
         EXECUTE IMMEDIATE 'ALTER INDEX ' || lr.index_name || ' LOGGING'; 
      END IF; 
   END LOOP; 
 
   -- For some reason, new partitioned tables show logging as NONE at the partition level, 
   -- and YES at the subpartition level. So we determine which partitions to modify based 
   -- on the subpartitions' LOGGING attribute. 
   IF (l_version = 9) THEN 
    
      FOR lr IN cur_nolog_parts9i LOOP 
         p('ALTER TABLE ' || lr.table_name ||' MODIFY PARTITION ' || lr.partition_name ||' LOGGING'); 
         EXECUTE IMMEDIATE 'ALTER TABLE ' || lr.table_name ||' MODIFY PARTITION ' || lr.partition_name ||' LOGGING'; 
      END LOOP; 
    
      FOR lr IN cur_nolog_indparts9i LOOP 
         p('ALTER INDEX ' || lr.index_name ||' MODIFY PARTITION ' || lr.partition_name ||' LOGGING'); 
         EXECUTE IMMEDIATE 'ALTER INDEX ' || lr.index_name ||' MODIFY PARTITION ' || lr.partition_name ||' LOGGING'; 
      END LOOP; 
    
   -- this anonymous block won't compile on a 9i database with references to the recyclebin, so we have 
   -- to bury these two cursors in dynamic SQL 
   ELSIF (l_version >= 10) THEN 
      OPEN l_cv FOR ' 
      SELECT DISTINCT table_name, 
                      partition_name 
        FROM user_tab_subpartitions 
       WHERE table_name NOT IN (SELECT DISTINCT object_name 
                                  FROM user_recyclebin) 
         AND logging IN (''NO'', ''NONE'')'; 
       
      LOOP 
         FETCH l_cv INTO l_obj_name, l_part_name; 
         EXIT WHEN l_cv%NOTFOUND; 
 
         p('ALTER TABLE ' || l_obj_name ||' MODIFY PARTITION ' || l_part_name ||' LOGGING'); 
         EXECUTE IMMEDIATE 'ALTER TABLE ' || l_obj_name ||' MODIFY PARTITION ' || l_part_name ||' LOGGING'; 
 
      END LOOP;    
    
      l_obj_name := NULL; 
      l_part_name := NULL; 
       
      OPEN l_cv FOR ' 
      SELECT DISTINCT index_name, 
                      partition_name 
        FROM user_ind_subpartitions 
       WHERE index_name NOT IN (SELECT object_name 
                                  FROM user_recyclebin) 
         AND logging IN (''NO'', ''NONE'')'; 
          
      LOOP 
         FETCH l_cv INTO l_obj_name, l_part_name; 
         EXIT WHEN l_cv%NOTFOUND; 
 
         p('ALTER INDEX ' || l_obj_name ||' MODIFY PARTITION ' || l_part_name ||' LOGGING'); 
         EXECUTE IMMEDIATE 'ALTER INDEX ' || l_obj_name ||' MODIFY PARTITION ' || l_part_name ||' LOGGING'; 
 
      END LOOP; 
    
   ELSE 
      p('ERROR: ' || TO_CHAR(l_version) ||' is an unsupported db version.'); 
   END IF; 
 
END add_logging_all; 
 
-------------------------------------------------------------------------------- 
PROCEDURE enable_row_movement_all 
IS 
   CURSOR cur_rm_disabled IS 
   SELECT table_name FROM user_tables 
   WHERE partitioned = 'YES' 
   AND row_movement = 'DISABLED'; 
    
   l_count INTEGER := 0; 
BEGIN 
   FOR lr IN cur_rm_disabled LOOP 
      -- This loop ignores our internal "P" printing procedures, and instead 
      -- uses the DBMS_OUTPUT "put" routine so that subsequent "put" calls will 
      -- go on the same line.  
      DBMS_OUTPUT.put('Enabling ROW MOVEMENT for '||lr.table_name||'...'); 
      EXECUTE IMMEDIATE 'ALTER TABLE '||lr.table_name||' ENABLE ROW MOVEMENT'; 
      DBMS_OUTPUT.put('Done.'); 
      DBMS_OUTPUT.new_line; 
       
      l_count := l_count + 1; 
       
   END LOOP; 
    
   IF (l_count = 0) THEN 
      p('All partitioned tables have ROW MOVEMENT enabled.'); 
   END IF; 
END; 
 
-------------------------------------------------------------------------------- 
PROCEDURE remove_default 
( 
   i_tbl_nm       IN VARCHAR2, 
   i_col_nm       IN VARCHAR2, 
   i_perm_removal IN BOOLEAN DEFAULT FALSE 
) IS 
   l_proc_nm  user_objects.object_name%TYPE := 'remove_default'; 
   l_tbl_nm   user_tables.table_name%TYPE; 
   l_col_nm   user_tab_columns.column_name%TYPE; 
   l_nullable user_tab_columns.nullable%TYPE; 
 
   lx_column_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_column_not_there, -00904); 
BEGIN 
   l_tbl_nm := UPPER(i_tbl_nm); 
   assert(obj_exists(l_tbl_nm, gc_table), 
          l_proc_nm || g_sep_char || l_tbl_nm || ' does not exist.'); 
    
   l_col_nm := UPPER(i_col_nm); 
   SELECT nullable 
     INTO l_nullable 
     FROM user_tab_columns 
    WHERE table_name = l_tbl_nm 
      AND column_name = l_col_nm; 
 
   IF (i_perm_removal = FALSE) THEN 
      IF (l_nullable = 'Y') THEN 
         p('Changing DEFAULT on column ' || l_tbl_nm || '.' || l_col_nm || 
           ' to NULL...'); 
         EXECUTE IMMEDIATE 'ALTER TABLE ' || l_tbl_nm || '  MODIFY ' || l_col_nm || 
                           ' DEFAULT NULL'; 
      ELSE 
         err(l_proc_nm || g_sep_char || 'Should not change DEFAULT on ' || l_tbl_nm || '.' || l_col_nm || 
             ' to NULL until the NOT NULL constraint on this column is removed.'); 
      END IF; 
   ELSE 
      DECLARE 
         l_col_spec VARCHAR2(500); 
         l_count INTEGER := 0; 
      BEGIN 
         -- Error out if there are any other dependencies like check 
         -- constraints or indexes. It is do-able to capture all of that  
         -- before dropping, but not worth the effort due to the rarity of 
         -- calls to this routine. 
         SELECT SUM(num_col_deps) 
           INTO l_count 
           FROM (SELECT COUNT(*) num_col_deps 
                   FROM user_cons_columns 
                  WHERE table_name = l_tbl_nm 
                    AND column_name = l_col_nm 
                    AND constraint_name NOT LIKE 'SYS%' 
                 UNION ALL 
                 SELECT COUNT(*) num_col_deps 
                   FROM user_ind_columns 
                  WHERE table_name = l_tbl_nm 
                    AND column_name = l_col_nm); 
                     
         IF (l_count > 0) THEN 
            err(l_proc_nm || g_sep_char || 'Should not remove DEFAULT on ' || l_tbl_nm || '.' || l_col_nm || 
                ' automatically since it has constraints and/or indexes that '|| 
                'should be manually handled.'); 
         ELSE 
            -- save column specs 
            SELECT data_type || DECODE(col_length, '(*,*)', NULL, col_length) || 
                   DECODE(nullable, 'N', ' NOT NULL ', NULL) col_spec 
              INTO l_col_spec 
              FROM (SELECT column_name, 
                           data_type, 
                           DECODE(data_type, 
                                  'NUMBER', 
                                  '(' || DECODE(data_precision, NULL, '*', data_precision) || ',' || 
                                  DECODE(data_scale, NULL, '*', data_scale) || ')', 
                                  'VARCHAR2', 
                                  '(' || data_length || ')') col_length, 
                           nullable 
                      FROM user_tab_columns 
                      WHERE table_name = l_tbl_nm 
                      AND   column_name = l_col_nm); 
                    
            -- create backup copy of the column 
            EXECUTE IMMEDIATE 
               'ALTER TABLE '||l_tbl_nm|| 
               '  ADD '||l_col_nm||'_BKP'||' '||l_col_spec; 
                
            -- move values into backup column 
            EXECUTE IMMEDIATE 
               'UPDATE '||l_tbl_nm|| 
               '  SET '||l_col_nm||'_BKP = '||l_col_nm; 
                
            -- drop old column 
            EXECUTE IMMEDIATE  
               'ALTER TABLE '||l_tbl_nm|| 
               '  DROP COLUMN '||l_col_nm; 
                
            -- create new column from old 
            EXECUTE IMMEDIATE 
               'ALTER TABLE '||l_tbl_nm|| 
               '  ADD '||l_col_nm||' '|| l_col_spec; -- no DEFAULT this time 
                
            -- move old values back to new column 
            EXECUTE IMMEDIATE 
               'UPDATE '||l_tbl_nm|| 
               '  SET '||l_col_nm||' = '||l_col_nm||'_BKP'; 
 
            -- drop backup column 
            EXECUTE IMMEDIATE 
               'ALTER TABLE '||l_tbl_nm|| 
               '  DROP COLUMN '||l_col_nm||'_BKP'; 
         END IF; -- if column has constraints or indexes 
      END; 
   END IF; -- if permanent removal was requested 
 
EXCEPTION 
   WHEN lx_column_not_there THEN 
      err(l_proc_nm || g_sep_char || 'Column ' || l_col_nm || ' is not found in table ' || l_tbl_nm || '.'); 
END remove_default; 
 
-------------------------------------------------------------------------------- 
PROCEDURE change_col 
( 
   i_tbl_nm       IN VARCHAR2, 
   i_col_nm       IN VARCHAR2, 
   i_new_datatype IN VARCHAR2 DEFAULT NULL, 
   i_new_length   IN VARCHAR2 DEFAULT NULL 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'change_col'; 
   l_tbl_nm user_tables.table_name%TYPE; 
   l_col_nm user_tab_columns.column_name%TYPE; 
   l_old_col_type user_tab_columns.data_type%TYPE; 
   l_new_col_type user_tab_columns.data_type%TYPE; 
   l_new_col_len VARCHAR2(10); 
   l_nullable CHAR(1); 
BEGIN 
   l_tbl_nm := UPPER(i_tbl_nm); 
   l_col_nm := UPPER(i_col_nm); 
   l_new_col_type := UPPER(i_new_datatype); 
    
   assert(obj_exists(l_tbl_nm, gc_table), 
          l_proc_nm || g_sep_char || 'Table '|| l_tbl_nm || ' does not exist.'); 
   assert(attr_exists(l_tbl_nm, l_col_nm, gc_column), 
          l_proc_nm || g_sep_char || 'Column '|| l_tbl_nm ||'.'||l_col_nm||' does not exist.'); 
   assert((i_new_datatype IS NOT NULL OR i_new_length IS NOT NULL), 
          l_proc_nm || g_sep_char || 'Change parameters are empty. Please pass in a new datatype, or new length or both.'); 
 
   IF (l_new_col_type IS NOT NULL) THEN 
      assert(l_new_col_type IN ('VARCHAR2','NUMBER','DATE','CHAR'), 
             l_proc_nm || g_sep_char || i_new_datatype ||' is an unsupported datatype. You will have to do this manually.'); 
   END IF; 
    
   IF (l_new_col_type IN ('VARCHAR2','CHAR')) THEN 
      assert(i_new_length IS NOT NULL, 
             l_proc_nm || g_sep_char || 'If you would like to change this column to a '|| 
             l_new_col_type ||', you must provide a length.'); 
   END IF; 
              
   -- I had error checking to ensure lengths were within Oracle bounds, but it's 
   -- not really worth the effort. If they don't know VARCHAR2 or NUMBER limits 
   -- by now, they deserve an Oracle error. 
   IF (i_new_length IS NOT NULL) THEN 
      IF (INSTR(i_new_length,'(') = 0 OR INSTR(i_new_length,')') = 0) THEN 
         -- strip any parenthesis that might be there, then add them back to 
         -- ensure completeness 
         l_new_col_len := '('||REPLACE(REPLACE(i_new_length,'(',NULL),')',NULL)||')'; 
      ELSE 
         l_new_col_len := i_new_length; 
      END IF; 
   END IF; 
 
   -- TO-DO: Someday add code here to determine if there are histograms on the 
   -- column. If so, determine what the sample size was and re-analyze the column 
   -- after re-creation. 
 
   -- Get nullable indicator 
   SELECT data_type, nullable 
     INTO l_old_col_type, l_nullable 
     FROM user_tab_columns 
    WHERE table_name = l_tbl_nm 
      AND column_name = l_col_nm; 
       
   IF (l_new_col_type IS NULL) THEN 
      -- use existing datatype if caller is not changing it 
      l_new_col_type := l_old_col_type; 
   END IF; 
    
   -- Create backup copy of the column using the new specifications. If the  
   -- data doesn't fit or convert, then an error will be raised on the update. 
   EXECUTE IMMEDIATE 
      'ALTER TABLE '||l_tbl_nm|| 
      '  ADD '||l_col_nm||'_BKP'||' '||l_new_col_type||' '||l_new_col_len; 
       
   -- move values into backup column 
   EXECUTE IMMEDIATE 
      'UPDATE '||l_tbl_nm|| 
      '  SET '||l_col_nm||'_BKP = '||l_col_nm; 
       
   -- empty old column 
   IF (l_nullable = 'N') THEN 
      -- drop NOT NULL constraint before emptying 
      EXECUTE IMMEDIATE 'ALTER TABLE '||l_tbl_nm||' MODIFY '||l_col_nm||' NULL'; 
   END IF; 
 
   EXECUTE IMMEDIATE 
      'UPDATE '||l_tbl_nm|| 
      '  SET '||l_col_nm||' = NULL'; 
       
   -- create new column from old 
   EXECUTE IMMEDIATE 
      'ALTER TABLE '||l_tbl_nm|| 
      '  MODIFY '||l_col_nm||' '|| l_new_col_type || l_new_col_len; 
       
   -- move old values back to new column 
   EXECUTE IMMEDIATE 
      'UPDATE '||l_tbl_nm|| 
      '  SET '||l_col_nm||' = '||l_col_nm||'_BKP'; 
    
   -- Now re-apply the NOT NULL constraint if any 
   IF (l_nullable = 'N') THEN 
      EXECUTE IMMEDIATE   
         'ALTER TABLE '||l_tbl_nm||' MODIFY '||l_col_nm||' NOT NULL'; 
   END IF; 
    
   -- drop backup column 
   EXECUTE IMMEDIATE 
      'ALTER TABLE '||l_tbl_nm|| 
      '  DROP COLUMN '||l_col_nm||'_BKP'; 
    
    
END change_col; 
 
-------------------------------------------------------------------------------- 
PROCEDURE rebuild_unusable 
( 
   i_compute_statistics IN BOOLEAN DEFAULT TRUE, 
   i_online             IN BOOLEAN DEFAULT FALSE 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'rebuild_unusable'; 
 
   CURSOR cur_unusable_i IS 
      SELECT index_name, 
             NVL(num_rows, 0) num_rows 
        FROM user_indexes 
       WHERE status = 'UNUSABLE'; 
 
   CURSOR cur_unusable_ip IS 
      SELECT index_name, 
             partition_name, 
             NVL(num_rows, 0) num_rows 
        FROM user_ind_partitions 
       WHERE status = 'UNUSABLE'; 
 
   CURSOR cur_unusable_isp IS 
      SELECT index_name, 
             partition_name, 
             subpartition_name, 
             NVL(num_rows, 0) num_rows 
        FROM user_ind_subpartitions 
       WHERE status = 'UNUSABLE'; 
 
BEGIN 
 
   FOR lr IN cur_unusable_i LOOP 
      tag_session(pkgc_pkg_nm, l_proc_nm, lr.index_name, lr.num_rows); 
      rebuild_idx(lr.index_name, 
                  NULL, --tablespace 
                  NULL, --part 
                  NULL, --subpart 
                  i_compute_statistics, 
                  i_online); 
      untag_session; 
   END LOOP; 
 
   FOR lr IN cur_unusable_ip LOOP 
      tag_session(pkgc_pkg_nm, 
                  l_proc_nm, 
                  lr.index_name || g_sep_char || lr.partition_name, 
                  lr.num_rows); 
      rebuild_idx(lr.index_name, 
                  NULL, --tablespace 
                  lr.partition_name, 
                  NULL, --subpart 
                  i_compute_statistics, 
                  i_online); 
      untag_session; 
   END LOOP; 
 
   FOR lr IN cur_unusable_isp LOOP 
      tag_session(pkgc_pkg_nm, 
                  l_proc_nm, 
                  lr.index_name || g_sep_char || lr.subpartition_name, 
                  lr.num_rows); 
      rebuild_idx(lr.index_name, 
                  NULL, --tablespace 
                  lr.partition_name, 
                  lr.subpartition_name, 
                  i_compute_statistics, 
                  i_online); 
      untag_session; 
   END LOOP; 
 
END rebuild_unusable; 
 
-------------------------------------------------------------------------------- 
PROCEDURE reset_seq 
( 
   i_seq_nm   IN VARCHAR2, 
   i_tbl_nm   IN VARCHAR2 DEFAULT NULL,
   i_col_nm   IN VARCHAR2 DEFAULT NULL,
   i_recreate IN BOOLEAN  DEFAULT FALSE
) IS 

   l_proc_nm        user_objects.object_name%TYPE := 'reset_seq'; 
   l_seq_nm         user_sequences.sequence_name%TYPE; 
   l_table_nm       user_tables.table_name%TYPE; 
   l_seq_rec        user_sequences%ROWTYPE; 
   l_gap            INTEGER := 0; 
   l_nextval        INTEGER := 0; 
   l_maxval         INTEGER := 0; 
   l_col_nm         VARCHAR2(30); 
   l_dump           INTEGER := 0; 
   l_action_msg     VARCHAR2(250);
   
BEGIN 
   l_seq_nm := UPPER(i_seq_nm); 
    
   assert(obj_exists(l_seq_nm, gc_sequence), 
          l_proc_nm || g_sep_char || 'Sequence ' || l_seq_nm || ' does not exist.'); 
    
   -- get sequence metadata
   SELECT * 
     INTO l_seq_rec 
     FROM user_sequences 
    WHERE sequence_name = l_seq_nm; 
       
   assert(l_seq_rec.increment_by > 0,
          l_proc_nm || g_sep_char || l_seq_nm||
          ' is a descending sequence, which '||l_proc_nm||' does not support.');
    
   IF (i_tbl_nm IS NULL) THEN 
      -- Attempt to get table name from sequence name. Most sequence 
      -- naming standards will either be S[E]Q_table_name, table_name_S[E]Q,  
      -- table_name_PK_S[E]Q, or table_name_ID_S[E]Q.
      -- So we will try to extract TABLE_NAME given those patterns. 
      l_table_nm := REPLACE( 
                        REPLACE( 
                          REPLACE( 
                            REPLACE( 
                              REPLACE( 
                                REPLACE( 
                                  REPLACE(l_seq_nm,'_PK_SQ') 
                                ,'_PK_SEQ') 
                              ,'SEQ_',NULL) 
                            ,'_SEQ',NULL) 
                          ,'_ID',NULL) 
                        ,'_SQ',NULL) 
                      ,'SQ_',NULL); 
       
      assert(obj_exists(l_table_nm, gc_table), 
          l_proc_nm || g_sep_char || 'Cannot extract table name from ' || l_seq_nm); 
   ELSE 
      l_table_nm := UPPER(i_tbl_nm); 
      assert(obj_exists(l_table_nm, gc_table), 
          l_proc_nm || g_sep_char || 'Table ' || l_table_nm ||' does not exist.'); 
   END IF; 
 
   IF (i_col_nm IS NULL) THEN
      BEGIN 
         SELECT column_name 
           INTO l_col_nm 
           FROM user_cons_columns 
          WHERE constraint_name = (SELECT constraint_name 
                                     FROM user_constraints 
                                    WHERE table_name = l_table_nm 
                                      AND constraint_type = 'P'); 
      EXCEPTION 
         WHEN NO_DATA_FOUND THEN 
            err(l_proc_nm || g_sep_char || 'No PK found for table '||l_table_nm); 
      END; 
   ELSE
      l_col_nm := UPPER(i_col_nm);
      assert(attr_exists(l_table_nm,l_col_nm,gc_column),l_proc_nm||g_sep_char||'Column '||l_table_nm||'.'||l_col_nm||' does not exist.');
   END IF;
       
   -- See what the next value would be; unfortunately, this uses up a number. 
   -- Cannot use user_sequences.last_number because it is the current sequence 
   -- number + cache. No way to find out where the sequence is really at except 
   -- by selecting from it. 
   EXECUTE IMMEDIATE 'SELECT '||l_seq_nm||'.NEXTVAL FROM DUAL' INTO l_nextval; 
   -- Now find out where the ID is currently at in the target table. 
   BEGIN
      EXECUTE IMMEDIATE 'SELECT MAX(' || l_col_nm || ') AS max FROM ' || l_table_nm INTO l_maxval;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_maxval := NULL; -- tell the truth, table has no max value in the given column
   END;
 
   -- Only attempt refresh if current value of sequence is out of sync with 
   -- greatest value in sequence-supported column.
   -- Unfortunately, the select from NEXTVAL above will cause sequences that 
   -- _were_ in sync to now be one greater than they should be. So just by peeking 
   -- into the sequence, we've caused it to get out of sync in many instances.
   -- Sorry. Can't be helped until we can call CURRVAL without having to call NEXTVAL first.
   IF ((l_maxval IS NULL AND l_nextval > l_seq_rec.min_value) OR -- test this first to short-circuit NULL errors if used in comparisons below
       l_nextval < l_maxval OR -- data has been manually entered and seq is behind
       l_nextval > l_maxval+1 OR -- data has been deleted and seq if too far forward
       l_nextval = l_maxval+1) THEN -- seq was in sync, but by pulling NEXTVAL it is now one off
      
      -- Determine positive or negative gap
      l_gap := NVL(l_maxval,0) - l_nextval;
      
      -- If gap is negative and falls below the minimum, adjust gap
      IF (l_gap < 0 AND (l_nextval + l_gap) < l_seq_rec.min_value) THEN
         l_gap := (NVL(l_maxval,0) + l_seq_rec.min_value) - l_nextval;
      END IF;

      l_action_msg := l_proc_nm || g_sep_char || l_seq_nm || ' is at ' || TO_CHAR(l_nextval) || ', but ' ||
                      l_table_nm||'.'||l_col_nm || ' is ' ||
                      CASE WHEN l_maxval IS NULL THEN 'empty' ELSE 'at '||TO_CHAR(l_maxval) END ||'.';
                      

      IF (l_gap = 0 OR (l_nextval + l_gap) < l_seq_rec.min_value) THEN
         l_action_msg := l_action_msg || CHR(10) || 'Unable to adjust sequence because gap is 0 or adjustment falls below MINVALUE';
         inf(l_action_msg);
      ELSE
         l_action_msg := l_action_msg || CHR(10) || 'Adjusting sequence by '||l_gap||'...';
         inf(l_action_msg);

         IF (i_recreate = FALSE) THEN
            -- Bump the sequence by the gap. We do this instead of recreating it so we don't invalidate existing code.
      EXECUTE IMMEDIATE 'ALTER SEQUENCE '||l_seq_nm||' INCREMENT BY '||l_gap||' NOCACHE'; 
      EXECUTE IMMEDIATE 'SELECT '||l_seq_nm||'.NEXTVAL FROM dual' INTO l_dump;
            -- Since we messed with the increment and cache, these need to be set back to the original values. 
      EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || l_seq_nm || 
                        ' INCREMENT BY '||l_seq_rec.increment_by|| 
                        CASE l_seq_rec.cache_size 
                           WHEN 0 THEN 
                              ' NOCACHE' 
                           ELSE     
                              ' CACHE ' || l_seq_rec.cache_size 
                        END;
         ELSIF (i_recreate = TRUE) THEN
            EXECUTE IMMEDIATE 'DROP SEQUENCE '||l_seq_nm;
            EXECUTE IMMEDIATE 'CREATE SEQUENCE '||l_seq_nm||
                              ' START WITH '||l_seq_rec.min_value||
                              ' INCREMENT BY '||l_seq_rec.increment_by|| 
                              ' MINVALUE '||l_seq_rec.min_value||
                              ' MAXVALUE '||l_seq_rec.max_value||
                              CASE l_seq_rec.cycle_flag WHEN 'Y' THEN ' CYCLE ' ELSE ' NOCYCLE ' END||
                              CASE l_seq_rec.order_flag WHEN 'Y' THEN ' ORDER ' ELSE ' NOORDER ' END||
                              CASE l_seq_rec.cache_size WHEN 0 THEN ' NOCACHE' ELSE ' CACHE ' || l_seq_rec.cache_size END;
   END IF;
   
      END IF;
   END IF;   
 
END reset_seq; 
 
-------------------------------------------------------------------------------- 
PROCEDURE mod_seq_cache 
( 
   i_seq_nm        IN VARCHAR2, 
   i_new_cache_num IN NUMBER 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'mod_seq_cache'; 
   l_obj_nm  user_objects.object_name%TYPE; 
BEGIN 
   l_obj_nm := UPPER(i_seq_nm); 
 
   assert(obj_exists(l_obj_nm, gc_sequence), 
          l_proc_nm || g_sep_char || 'Sequence ' || l_obj_nm || 
          ' does not exist.'); 
 
   assert(i_new_cache_num = 0 OR i_new_cache_num >= 2, 
          l_proc_nm || g_sep_char || 'New cache size for ' || l_obj_nm || 
          ' must be 0 (NOCACHE) or 2 and higher'); 
 
   IF (i_new_cache_num = 0) THEN 
      p('Setting sequence '||l_obj_nm||' to NOCACHE...'); 
      EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || i_seq_nm || ' NOCACHE '; 
   ELSE 
      p('Setting sequence '||l_obj_nm||' to CACHE '||TO_CHAR(i_new_cache_num)||'...'); 
      EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || i_seq_nm || ' CACHE ' || 
                        i_new_cache_num; 
   END IF; 
END mod_seq_cache; 
 
-------------------------------------------------------------------------------- 
-- 2007Feb26 bcoulam: Commented out because it required that SYS grant explicit 
-- SELECT access to DBA_SCHEDULER_JOBS, a habit I and the DBAs didn't want to  
-- start (granting access to DBA_* views). 
 
--PROCEDURE check_stats_setup 
--IS 
--   l_proc_nm user_objects.object_name%TYPE := 'check_stats_setup'; 
--   l_parm      VARCHAR2(512); 
--   l_enabled   VARCHAR2(5); 
--   l_setup_ok  BOOLEAN := TRUE; 
--BEGIN 
--   IF (get_db_version >= 10) THEN 
--      BEGIN 
--         EXECUTE IMMEDIATE ' 
--         SELECT value 
--           FROM v$parameter 
--          WHERE NAME = ''statistics_level''' 
--         INTO l_parm; 
--      EXCEPTION 
--         WHEN NO_DATA_FOUND THEN 
--            err(l_proc_nm || g_sep_char ||  
--               'Could not determine STATISTICS_LEVEL setting. Please set this '|| 
--               'initialization parameter to TYPICAL.'); 
--      END; 
--       
--      IF (l_parm = 'BASIC') THEN 
--         l_setup_ok := FALSE; 
--         warn(l_proc_nm || g_sep_char || 
--            'STATISTICS_LEVEL is BASIC, disabling various automated features. '|| 
--            'Please set to TYPICAL or ALL'); 
--      END IF; 
--       
--      BEGIN 
--         EXECUTE IMMEDIATE ' 
--         SELECT enabled 
--           FROM dba_scheduler_jobs 
--          WHERE job_name = ''GATHER_STATS_JOB''' 
--         INTO l_enabled; 
--      EXCEPTION 
--         WHEN NO_DATA_FOUND THEN 
--            err(l_proc_nm || g_sep_char ||  
--               'Could not determine GATHER_STATS_JOB status. Ensure the job has not been disabled or dropped.'); 
--      END; 
-- 
--      IF (l_enabled <> 'TRUE') THEN 
--         l_setup_ok := FALSE; 
--         warn(l_proc_nm || g_sep_char ||  
--            'The automatic GATHER_STATS_JOB is disabled. Please enable it.'); 
--      END IF; 
--       
--      IF (l_setup_ok) THEN 
--         inf('10g automatic statistics monitoring and gathering is configured correctly.'); 
--      ELSE 
--         warn('10g automatic statistics monitoring and gathering is not configured per recommendations.'); 
--         warn('You must either run statistics manually on a regular basis, or correct the above setting(s).'); 
--      END IF; 
--   ELSE 
--      inf('9i database detected. No automated/recommended statistics setup to check.');    
--   END IF; 
-- 
--END check_stats_setup; 
 
 
-------------------------------------------------------------------------------- 
PROCEDURE refresh_grants 
( 
   i_grantee IN VARCHAR2 DEFAULT NULL, 
   i_read_only   IN BOOLEAN DEFAULT FALSE,  
   i_gen_script IN BOOLEAN DEFAULT FALSE, 
   i_exclude_arr IN type_obj_nm_arr DEFAULT empty_obj_nm_arr 
) 
IS 
 
   l_table_privs VARCHAR2(60);  
   l_user all_users.username%TYPE; 
   l_grantee user_role_privs.granted_role%TYPE; 
   l_prompt VARCHAR2(10); 
 
   lx_role_not_there EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_role_not_there, -01917); 
 
   CURSOR cur_tables IS 
      WITH subq AS 
      ( 
          -- construct ordered list of the existing privileges  
          SELECT utp.table_name 
                ,utp.grantee 
                ,utp.privilege 
                ,ROW_NUMBER() OVER(PARTITION BY utp.table_name 
                                       ORDER BY utp.table_name, 
                                                CASE utp.privilege 
                                                   WHEN 'SELECT' THEN 1 
                                                   WHEN 'INSERT' THEN 2 
                                                   WHEN 'UPDATE' THEN 3 
                                                   WHEN 'DELETE' THEN 4 
                                                   ELSE 5 
                                                END) rn  
                ,COUNT(*) OVER(PARTITION BY utp.table_name) cnt 
            FROM user_tab_privs_made utp 
                ,user_tables    t 
           WHERE grantee = l_grantee 
             AND utp.table_name = t.table_name 
             AND t.nested = 'NO' 
             AND NOT EXISTS (SELECT NULL FROM user_mviews WHERE mview_name = t.table_name)
             AND NOT EXISTS (SELECT NULl FROM user_external_tables WHERE table_name = t.table_name)
             AND (t.iot_type <> 'IOT_OVERFLOW' OR t.iot_type IS NULL) 
      ) 
      -- method of getting comma-delimited list of privs using SQL 
      SELECT table_name obj_name, 
             'GRANT '||l_table_privs||' ON ' || table_name || ' TO ' || l_grantee AS stmt  
        FROM user_tables t  
       WHERE t.nested = 'NO'  
         AND NOT EXISTS (SELECT NULL FROM user_mviews WHERE mview_name = t.table_name)
         AND NOT EXISTS (SELECT NULl FROM user_external_tables WHERE table_name = t.table_name)
         AND (t.iot_type <> 'IOT_OVERFLOW' OR t.iot_type IS NULL)
       MINUS   
       SELECT table_name obj_name, 'GRANT '||LTRIM(LTRIM(SYS_CONNECT_BY_PATH(privilege,', '),','))|| 
                                   ' ON '||table_name||' TO '||l_grantee AS stmt 
         FROM subq 
        WHERE rn = cnt 
        START WITH rn = 1 
      CONNECT BY table_name = PRIOR table_name AND PRIOR rn = (rn - 1) 
        ORDER BY obj_name;     

   CURSOR cur_ext_tabs IS
    SELECT table_name obj_name
          ,'GRANT SELECT ON '|| table_name||' TO '|| l_grantee AS stmt
      FROM user_external_tables xt
     MINUS      
    SELECT utpm.table_name obj_name
          ,'GRANT SELECT ON ' || utpm.table_name || ' TO ' || l_grantee AS stmt
      FROM user_tab_privs_made utpm
          ,user_external_tables xt
     WHERE utpm.grantee = l_grantee
       AND utpm.table_name = xt.table_name
       AND utpm.privilege = 'SELECT'
     ORDER BY obj_name;

   CURSOR cur_mviews IS 
    SELECT mview_name obj_name
          ,'GRANT SELECT ON ' || mview_name || ' TO ' || l_grantee AS stmt
      FROM user_mviews
    MINUS
    SELECT table_name obj_name
          ,'GRANT SELECT ON ' || table_name || ' TO ' || l_grantee AS stmt
      FROM user_tab_privs_made
          ,user_mviews um
     WHERE grantee = l_grantee
       AND table_name = um.mview_name
       AND privilege = 'SELECT'
     ORDER BY obj_name;
 
   CURSOR cur_sequences IS 
    SELECT sequence_name obj_name
          ,'GRANT SELECT ON ' || sequence_name || ' TO ' || l_grantee AS stmt
      FROM user_sequences
    MINUS
    SELECT table_name obj_name
          ,'GRANT SELECT ON ' || table_name || ' TO ' || l_grantee AS stmt
      FROM user_tab_privs_made
          ,user_sequences us
     WHERE grantee = l_grantee
       AND table_name = us.sequence_name
       AND privilege = 'SELECT'
     ORDER BY obj_name;
       
   CURSOR cur_packages IS 
    SELECT object_name obj_name
          ,'GRANT EXECUTE ON ' || object_name || ' TO ' || l_grantee AS stmt
      FROM user_objects
     WHERE object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE')
       AND object_name NOT IN ('DDL_UTILS') -- default items to exclude  
    MINUS
    SELECT table_name obj_name
          ,'GRANT EXECUTE ON ' || table_name || ' TO ' || l_grantee AS stmt
      FROM user_tab_privs_made
          ,user_objects uo
     WHERE grantee = l_grantee
       AND table_name = uo.object_name
       AND uo.object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE')
       AND object_name NOT IN ('DDL_UTILS') -- default items to exclude  
       AND privilege = 'EXECUTE'
     ORDER BY obj_name;
       
   CURSOR cur_types IS  
    SELECT type_name obj_name,  
           'GRANT EXECUTE ON ' || type_name || ' TO ' || l_grantee AS stmt  
      FROM user_types  
     WHERE type_name NOT LIKE 'SYS%=='  
      MINUS  
     SELECT table_name obj_name,  
           'GRANT EXECUTE ON ' || table_name || ' TO ' || l_grantee AS stmt  
      FROM user_tab_privs_made, user_types uty  
     WHERE grantee = l_grantee  
     AND   table_name = uty.type_name  
     AND   privilege = 'EXECUTE'  
       AND type_name NOT LIKE 'SYS%=='  
     ORDER BY obj_name;  
       
   CURSOR cur_views IS 
    SELECT view_name obj_name
          ,'GRANT SELECT ON ' || view_name || ' to ' || l_grantee AS stmt
      FROM user_views
    MINUS
    SELECT table_name obj_name
          ,'GRANT SELECT ON ' || table_name || ' TO ' || l_grantee AS stmt
      FROM user_tab_privs_made
          ,user_views uv
     WHERE grantee = l_grantee
       AND table_name = uv.view_name
       AND privilege = 'SELECT'
     ORDER BY obj_name;
  
   -- Compartmentalizes the concatenating of the PROMPT variable  
   PROCEDURE handle_str(i_str IN VARCHAR2)  
   IS  
   BEGIN  
      p(l_prompt||i_str);  
   END handle_str;  
 
   -- Compartmentalized the actions which depend on whether we are generating 
   -- a script to be saved in a SQL file, or whether we are just bulldozing 
   -- ahead with actually granting the privs. 
   PROCEDURE handle_stmt(i_obj_nm IN VARCHAR2, i_stmt IN VARCHAR2) 
   IS 
   BEGIN 
      IF (i_exclude_arr.exists(i_obj_nm) OR i_exclude_arr.exists(LOWER(i_obj_nm))) THEN 
         NULL; -- exclude match from any grants 
      ELSE 
         IF (i_gen_script = TRUE) THEN 
            handle_str(i_stmt||';');  
         ELSE 
            EXECUTE IMMEDIATE i_stmt; 
         END IF; 
      END IF; 
       
   EXCEPTION 
      -- This provides info on the failed grant, but allows the routine to  
      -- keep attempting the remaining grants. 
      WHEN OTHERS THEN 
         p('ERROR: Attempt to '||CHR(10)||i_stmt); 
         p('Failed with '||SQLERRM); 
 
   END handle_stmt; 
             
BEGIN 
   l_user := sys_context('userenv','session_user'); 
    
   -- Determine grantee  
   IF (i_grantee IS NULL) THEN 
      l_grantee := l_user||'_FULL'; 
   ELSE 
      l_grantee := TRIM(UPPER(i_grantee)); 
   END IF; 
 
   -- Determine if outputting PROMPT  
   IF (i_gen_script = TRUE) THEN 
      l_prompt := 'PROMPT '; 
   ELSE 
      l_prompt := NULL; 
   END IF; 
    
   -- Determine privs to use for tables  
   IF (i_read_only) THEN  
      l_table_privs := 'SELECT';  
   ELSE  
      l_table_privs := 'SELECT, INSERT, UPDATE, DELETE';  
   END IF;  
     
   handle_str('Adding privileges to '||l_grantee||' for '||l_user||' packages...');  
   FOR lr IN cur_packages LOOP 
      handle_stmt(lr.obj_name, lr.stmt); 
   END LOOP; 
    
     
   handle_str('Adding privileges to '||l_grantee||' for '||l_user||' sequences...');  
   FOR lr IN cur_sequences LOOP 
      handle_stmt(lr.obj_name, lr.stmt); 
   END LOOP; 

   handle_str('Adding privileges to '||l_grantee||' for '||l_user||' tables...');  
   FOR lr IN cur_tables LOOP 
      handle_stmt(lr.obj_name, lr.stmt); 
   END LOOP; 
    
   handle_str('Adding privileges to '||l_grantee||' for '||l_user||' external tables...');  
   FOR lr IN cur_ext_tabs LOOP 
      handle_stmt(lr.obj_name, lr.stmt); 
   END LOOP; 

   handle_str('Adding privileges to '||l_grantee||' for '||l_user||' materialized views...');  
   FOR lr IN cur_mviews LOOP 
      handle_stmt(lr.obj_name, lr.stmt); 
   END LOOP; 
    
   handle_str('Adding privileges to '||l_grantee||' for '||l_user||' types...'); 
   FOR lr IN cur_types LOOP 
      handle_stmt(lr.obj_name, lr.stmt); 
   END LOOP; 
    
   handle_str('Adding privileges to '||l_grantee||' for '||l_user||' views...');  
   FOR lr IN cur_views LOOP 
      handle_stmt(lr.obj_name, lr.stmt); 
   END LOOP; 
    
EXCEPTION 
   WHEN lx_role_not_there THEN 
      p('Role/User '||l_grantee||' does not exist. Cannot grant anything to it.'); 
          
END refresh_grants; 
 
--------------------------------------------------------------------------------   
PROCEDURE set_table_monitoring(i_tbl_nm IN VARCHAR2 DEFAULT NULL)
IS   
   l_proc_nm user_objects.object_name%TYPE := 'set_table_monitoring';   
   
   CURSOR cur_nomon IS   
      SELECT ut.table_name   
        FROM user_tables ut  
        LEFT JOIN user_external_tables uet ON uet.table_name = ut.table_name  
       WHERE TEMPORARY = 'N'   
         AND MONITORING = 'NO'  
         AND uet.table_name IS NULL;   
   
   l_tbl_nm  user_tables.table_name%TYPE; 

   lx_table_busy EXCEPTION;   
   PRAGMA EXCEPTION_INIT(lx_table_busy, -54);   
BEGIN
      	
   IF (i_tbl_nm is NOT NULL) THEN
      l_tbl_nm := UPPER(i_tbl_nm); 
      assert(obj_exists(l_tbl_nm, gc_table), 
                l_proc_nm || g_sep_char || l_tbl_nm || ' does not exist.'); 
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE '||i_tbl_nm||' MONITORING';
      EXCEPTION
         WHEN lx_table_busy THEN   
            p(l_proc_nm||': Cannot set MONITORING. Table ['||i_tbl_nm||'] locked by another process.');   
      END;
   ELSE
      -- tackle all the tables in the schema   
      FOR lr IN cur_nomon LOOP   
         BEGIN   
            EXECUTE IMMEDIATE 'ALTER TABLE '||lr.table_name||' MONITORING';   
         EXCEPTION   
            WHEN lx_table_busy THEN   
               p(l_proc_nm||': Cannot set MONITORING. Table ['||lr.table_name||'] locked by another process.');   
         END;   
      END LOOP;
   END IF; 
END set_table_monitoring;

-------------------------------------------------------------------------------- 
PROCEDURE analyze_schema 
( 
   i_stale_only IN BOOLEAN DEFAULT FALSE 
) 
IS 
   l_proc_nm user_objects.object_name%TYPE := 'analyze_schema'; 
   l_objlist DBMS_STATS.objecttab; 
BEGIN 
   tag_session('DDL_UTILS','analyze_schema','Stale:'||bool_to_str(i_stale_only)); 
 
   -- Just in case the client locked it 
   IF (get_db_version >= 10) THEN 
      EXECUTE IMMEDIATE 'BEGIN DBMS_STATS.UNLOCK_SCHEMA_STATS(ownname => USER); END;';
   ELSE
      -- On 9i, ensure the tables have monitoring turned on
      set_table_monitoring(); 
   END IF; 
 
   p('Analyzing '||ite(i_stale_only,'stale','new')||' objects in schema '||USER||'...'); 
   DBMS_STATS.gather_schema_stats( 
      ownname          => USER, 
      estimate_percent => DBMS_STATS.auto_sample_size, 
      DEGREE           => DBMS_STATS.auto_degree,--DBMS_STATS.default_degree
      method_opt       => 'FOR ALL COLUMNS SIZE AUTO', -- the default  
      granularity      => 'ALL', 
      CASCADE          => TRUE,
      -- Metalink lists bugs related to GATHER AUTO, so we'll be specific until the bugs are all gone
      options          => 'GATHER '||ite(i_stale_only,'STALE','EMPTY'), 
      objlist          => l_objlist 
   ); 
 
   IF (l_objlist IS NOT NULL AND l_objlist.COUNT > 0) THEN 
      FOR i IN l_objlist.FIRST .. l_objlist.LAST LOOP 
         p('Analyzed ' || LOWER(l_objlist(i).objtype) ||' '||l_objlist(i).objname|| 
            ifnn(l_objlist(i).partname, 
                 ' ('||l_objlist(i).partname|| 
                    ifnn(l_objlist(i).subpartname,'.'||l_objlist(i).subpartname, NULL) || 
                 ')', 
                 NULL 
            ) 
          ); 
      END LOOP; 
   ELSE 
      inf(l_proc_nm || g_sep_char || 'Statistics are already current.'); 
   END IF; 
    
   p(USER||' analyzed.'); 
 
   untag_session; 
 
END analyze_schema; 
 
-------------------------------------------------------------------------------- 
PROCEDURE analyze_table 
( 
   i_tbl_nm IN VARCHAR2, 
   i_part_nm  IN VARCHAR2 DEFAULT NULL 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'analyze_table'; 
   l_obj_nm  user_objects.object_name%TYPE; 
   l_part_nm user_objects.object_name%TYPE; 
   lx_stats_locked EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_stats_locked, -20005);
   lx_iot_overflow EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_iot_overflow, -25191);
BEGIN 
   l_obj_nm := UPPER(i_tbl_nm); 
   l_part_nm := UPPER(i_part_nm); 
 
   assert(obj_exists(l_obj_nm, gc_table), 
          l_proc_nm || g_sep_char || 'Table '|| l_obj_nm || ' does not exist.'); 
 
   IF (i_part_nm IS NOT NULL) THEN 
      -- ensure the table is partitioned and has the named partition 
      assert(is_tbl_partitioned(l_obj_nm) = TRUE, 
         l_proc_nm || g_sep_char || 'Table '|| l_obj_nm ||  
         ' is not partitioned. Remove the second parameter and try again.'); 
 
      assert(attr_exists(l_obj_nm, l_part_nm, gc_part), 
         l_proc_nm || g_sep_char || 'Partition '|| l_obj_nm ||' ('||l_part_nm||')'|| 
         ' does not exist. Check your spelling and try again.'); 
   END IF; 
    
   tag_session('DDL_UTILS','analyze_table',l_obj_nm|| 
      ifnn(i_part_nm,' ('||UPPER(i_part_nm)||')',NULL)); 
 
   p('Analyzing table '||l_obj_nm|| 
      ifnn(i_part_nm,' ('||UPPER(i_part_nm)||')',NULL)||' and its indexes and columns...'); 
 
   -- 9i has a bug when you call pass NULL to the partname parameter 
   BEGIN 
      IF (i_part_nm IS NULL) THEN 
         DBMS_STATS.gather_table_stats( 
               ownname          => USER, 
               tabname          => l_obj_nm, 
               estimate_percent => DBMS_STATS.auto_sample_size, 
               method_opt       => 'FOR ALL COLUMNS SIZE AUTO', -- the default  
               DEGREE           => DBMS_STATS.default_degree, 
               granularity      => 'ALL', 
               CASCADE          => TRUE 
         ); 
      ELSE 
         DBMS_STATS.gather_table_stats( 
            ownname          => USER, 
            tabname          => l_obj_nm, 
            partname         => i_part_nm, 
            estimate_percent => DBMS_STATS.auto_sample_size, 
            method_opt       => 'FOR ALL COLUMNS SIZE AUTO', -- the default  
            DEGREE           => DBMS_STATS.default_degree, 
            granularity      => 'ALL', 
            CASCADE          => TRUE 
         ); 
      END IF; 
      p(i_tbl_nm||' analyzed.'); 
   EXCEPTION 
      WHEN lx_stats_locked THEN 
         p('Statistics for '||i_tbl_nm||' have been locked. Note: Queue tables should not be analyzed.');
         p('If the lock should be removed, call BEGIN DBMS_STATS.UNLOCK_TABLE_STATS(USER,'''||l_obj_nm||'''); END;');
      WHEN lx_iot_overflow THEN
         p('Oracle will not analyze the overflow segments of an IOT table, in this case: '||l_obj_nm);
   END; 
    
   untag_session; 
    
END analyze_table; 
 
-------------------------------------------------------------------------------- 
PROCEDURE analyze_index 
( 
   i_idx_nm  IN VARCHAR2, 
   i_part_nm IN VARCHAR2 DEFAULT NULL 
) IS 
   l_proc_nm user_objects.object_name%TYPE := 'analyze_index'; 
   l_obj_nm  user_objects.object_name%TYPE; 
   l_part_nm user_objects.object_name%TYPE; 
   lx_stats_locked EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_stats_locked, -20005); 
BEGIN 
   l_obj_nm := UPPER(i_idx_nm); 
   l_part_nm := UPPER(i_part_nm); 
    
   assert(obj_exists(l_obj_nm, gc_index), 
          l_proc_nm || g_sep_char || 'Index '|| l_obj_nm || ' does not exist.'); 
 
   IF (i_part_nm IS NOT NULL) THEN 
      -- ensure the index is partitioned and has the named partition 
      assert(is_idx_partitioned(l_obj_nm) = TRUE, 
         l_proc_nm || g_sep_char || 'Index '|| l_obj_nm ||  
         ' is not partitioned. Remove the second parameter and try again.'); 
 
      assert(attr_exists(l_obj_nm, l_part_nm, gc_part), 
         l_proc_nm || g_sep_char || 'Partition '|| l_obj_nm ||' ('||l_part_nm||')'||  
         ' does not exist. Check your spelling and try again.'); 
   END IF; 
    
   tag_session('DDL_UTILS','analyze_index',l_obj_nm|| 
      ifnn(i_part_nm, ' (' || l_part_nm || ')', NULL)); 
 
   p('Analyzing index ' || l_obj_nm || 
     ifnn(i_part_nm, ' (' || l_part_nm || ')', NULL) || 
     '...'); 
 
   BEGIN 
      DBMS_STATS.gather_index_stats(ownname          => USER, 
                                    indname          => l_obj_nm, 
                                    partname         => l_part_nm, 
                                    estimate_percent => DBMS_STATS.auto_sample_size, 
                                    DEGREE           => DBMS_STATS.default_degree, 
                                    granularity      => 'ALL'); 
      p(i_idx_nm||' analyzed.'); 
   EXCEPTION 
      WHEN lx_stats_locked THEN 
         p('Statistics for '||i_idx_nm||' have been locked. Note: Queue tables and their indexes should not be analyzed.'); 
         p('If the lock should be removed, call BEGIN DBMS_STATS.UNLOCK_TABLE_STATS(USER,''<indexed table>''); END;'); 
   END; 
    
 
   untag_session; 
                                  
END analyze_index; 
 
-------------------------------------------------------------------------------- 
FUNCTION recompile 
( 
   i_owner   IN VARCHAR2 DEFAULT USER, 
   i_name    IN VARCHAR2 DEFAULT '%', 
   i_type    IN VARCHAR2 DEFAULT '%', 
   i_status  IN VARCHAR2 DEFAULT 'INVALID', 
   i_verbose IN BOOLEAN DEFAULT FALSE 
) RETURN NUMBER 
 IS 
   -- Exceptions 
   lx_successwithcompile_err EXCEPTION; 
   PRAGMA EXCEPTION_INIT(lx_successwithcompile_err, -24344);
   lx_msng_invalid_option EXCEPTION;
   PRAGMA EXCEPTION_INIT(lx_msng_invalid_option, -00922); 
 
   -- Return Codes 
   lc_invalid_type   CONSTANT INTEGER := 1; 
   lc_invalid_parent CONSTANT INTEGER := 2; 
   lc_compile_errors CONSTANT INTEGER := 4; 
 
   l_cnt              NUMBER; 
   l_dyn_cur_handle   INTEGER; 
   l_type_status      INTEGER := 0; 
   l_parent_status    INTEGER := 0; 
   l_recompile_status INTEGER := 0; 
   l_obj_status       VARCHAR2(30); 
 
   CURSOR invalid_parent_cursor(oowner VARCHAR2, oname VARCHAR2, otype VARCHAR2, ostatus VARCHAR2, OID NUMBER) IS 
      SELECT 
             o.object_id 
        FROM public_dependency d, 
             all_objects       o 
       WHERE d.object_id = OID 
         AND o.object_id = d.referenced_object_id 
         AND o.status != 'VALID' 
      MINUS 
      SELECT 
             object_id 
        FROM all_objects 
       WHERE owner LIKE UPPER(oowner) 
         AND object_name LIKE UPPER(oname) 
         AND object_type LIKE UPPER(otype) 
         AND status LIKE UPPER(ostatus); 
 
   CURSOR recompile_cursor(OID NUMBER) IS 
      SELECT 'ALTER ' || DECODE(object_type
                               ,'PACKAGE BODY','PACKAGE'
                               ,'TYPE BODY','TYPE'
                               ,object_type) ||
             ' ' || owner || '.' ||
             object_name || ' COMPILE ' ||
             DECODE(object_type
                   ,'PACKAGE BODY','BODY'
                   ,'TYPE BODY','BODY'
                   ,'TYPE','SPECIFICATION'
                   ,'') ||
             DECODE(object_type
                   ,'MATERIALIZED VIEW',NULL
                   ,'VIEW',NULL
                   ,' REUSE SETTINGS') stmt
            ,object_type
            ,owner
            ,object_name
        FROM all_objects
       WHERE OBJECT_ID = OID;
 
   l_recompile_rec recompile_cursor%ROWTYPE; 
 
   CURSOR obj_cursor(oowner VARCHAR2, oname VARCHAR2, otype VARCHAR2, ostatus VARCHAR2) IS 
      SELECT MAX(LEVEL) dlevel, 
             object_id 
        FROM public_dependency 
       START WITH object_id IN (SELECT object_id 
                                  FROM all_objects 
                                 WHERE owner LIKE UPPER(oowner) 
                                   AND object_name LIKE UPPER(oname) 
                                   AND (object_type LIKE UPPER(otype) AND object_type != 'SYNONYM') 
                                   AND status LIKE UPPER(ostatus)) 
      CONNECT BY object_id = PRIOR referenced_object_id 
       GROUP BY object_id 
      HAVING MIN(LEVEL) = 1 
      -- 
      UNION ALL 
      -- 
      SELECT 1 dlevel, 
             object_id 
        FROM all_objects o 
       WHERE owner LIKE UPPER(oowner) 
         AND object_name LIKE UPPER(oname) 
         AND (object_type LIKE UPPER(otype) AND object_type != 'SYNONYM') 
         AND status LIKE UPPER(ostatus) 
         AND NOT EXISTS (SELECT 1 
                FROM public_dependency d 
               WHERE d.object_id = o.object_id) 
       ORDER BY 1 DESC; 
 
   TYPE type_int_numarr IS TABLE OF PLS_INTEGER INDEX BY BINARY_INTEGER; 
 
   l_dlevel    type_int_numarr; 
   l_object_id type_int_numarr; 
 
   CURSOR status_cursor(OID NUMBER) IS 
      SELECT status 
        FROM all_objects 
       WHERE object_id = OID; 
 
BEGIN 
   -- Recompile requested objects based on their dependency levels. 
   p('RECOMPILING INVALID OBJECTS...'); 
 
   IF (i_verbose) THEN 
      p(CHR(0)); 
      p('Target Object Owner  : ' ||i_owner); 
      p('Target Object Name   : ' ||REPLACE(i_name,'%','ALL')); 
      p('Target Object Type   : ' ||REPLACE(i_type,'%','ALL')); 
      p('Target Object Status : ' ||REPLACE(i_status,'%','ALL')); 
      p(CHR(0)); 
   END IF; 
 
   l_dyn_cur_handle := DBMS_SQL.open_cursor; 
 
   OPEN obj_cursor(i_owner, i_name, i_type, i_status); 
 
   FETCH obj_cursor BULK COLLECT 
      INTO l_dlevel, l_object_id; 
 
   FOR indx IN 1 .. l_dlevel.COUNT LOOP 
      OPEN recompile_cursor(l_object_id(indx)); 
    
      FETCH recompile_cursor 
         INTO l_recompile_rec; 
    
      CLOSE recompile_cursor; 
    
      -- We can recompile only Functions, Packages, Package Bodies, 
      -- Procedures, Triggers, Views, Types and Type Bodies. 
      IF l_recompile_rec.object_type IN 
         ('FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'TRIGGER', 'VIEW', 
          'TYPE', 'TYPE BODY', 'MATERIALIZED VIEW') THEN 
         -- There is no sense to recompile an object that depends on 
         -- invalid objects outside of the current recompile request. 
         OPEN invalid_parent_cursor(i_owner, 
                                    i_name, 
                                    i_type, 
                                    i_status, 
                                    l_object_id(indx)); 
       
         FETCH invalid_parent_cursor 
            INTO l_cnt; 
       
         IF (invalid_parent_cursor%NOTFOUND) THEN 
            -- Recompile object. 
            BEGIN 
               DBMS_SQL.parse(l_dyn_cur_handle, 
                              l_recompile_rec.stmt, 
                              DBMS_SQL.NATIVE); 
            EXCEPTION 
               WHEN lx_successwithcompile_err THEN -- oddity in Oracle 8 
                  NULL;
               WHEN lx_msng_invalid_option THEN
                  p('Invalid SQL: '||l_recompile_rec.stmt);
                  RAISE;
            END; 
          
            OPEN status_cursor(l_object_id(indx)); 
          
            FETCH status_cursor 
               INTO l_obj_status; 
          
            CLOSE status_cursor; 
          
            IF (l_obj_status <> 'VALID') THEN 
               l_recompile_status := lc_compile_errors; 
 
               -- We want to see the names of everything that won't compile 
               p('Unable to compile ' || 
                 l_recompile_rec.owner || '.' || 
                 RPAD(l_recompile_rec.object_name,30)|| ' ('|| 
                 l_recompile_rec.object_type||')'); 
            ELSE 
               IF (i_verbose) THEN 
                  p(l_recompile_rec.object_type || ' ' || 
                    l_recompile_rec.owner || '.' || 
                    l_recompile_rec.object_name || 
                    ' was attempted. Object status is now ' || l_obj_status || '.'); 
               END IF; 
            END IF; 
         ELSE 
            IF (i_verbose) THEN 
               p(l_recompile_rec.object_type || ' ' || 
                 l_recompile_rec.owner || '.' || 
                 l_recompile_rec.object_name || 
                 ' references invalid object(s) outside of this request.'); 
            END IF; 
          
            l_parent_status := lc_invalid_parent; 
         END IF; 
       
         CLOSE invalid_parent_cursor; 
      ELSE 
         IF (i_verbose) THEN 
            p(l_recompile_rec.owner || '.' || 
              l_recompile_rec.object_name || ' is a ' || 
              l_recompile_rec.object_type || ' and can not be recompiled.'); 
         END IF; 
       
         l_type_status := lc_invalid_type; 
      END IF; 
   END LOOP; 
 
   DBMS_SQL.close_cursor(l_dyn_cur_handle); 
    
   RETURN (l_type_status + l_parent_status + l_recompile_status); 
    
EXCEPTION 
   WHEN OTHERS THEN 
      IF (obj_cursor%ISOPEN) THEN 
         CLOSE obj_cursor; 
      END IF; 
 
      IF (recompile_cursor%ISOPEN) THEN 
         CLOSE recompile_cursor; 
      END IF; 
    
      IF (invalid_parent_cursor%ISOPEN) THEN 
         CLOSE invalid_parent_cursor; 
      END IF; 
    
      IF (status_cursor%ISOPEN) THEN 
         CLOSE status_cursor; 
      END IF; 
    
      IF (DBMS_SQL.is_open(l_dyn_cur_handle)) THEN 
         DBMS_SQL.close_cursor(l_dyn_cur_handle); 
      END IF; 
    
      RAISE; 
END recompile; 
 
-------------------------------------------------------------------------------- 
PROCEDURE show_version 
IS 
BEGIN 
   p(TO_CHAR(pkgc_version_num)); 
END show_version; 
 
-------------------------------------------------------------------------------- 
FUNCTION get_version RETURN NUMBER 
IS 
BEGIN 
   RETURN pkgc_version_num; 
END get_version; 
 
-------------------------------------------------------------------------------- 
PROCEDURE echo IS 
BEGIN 
   p('Echo!'); 
END echo; 
 
-------------------------------------------------------------------------------- 
--                         PACKAGE INITIALIZATIONS 
-------------------------------------------------------------------------------- 
BEGIN 
   g_line_len  := 120; 
   g_sep_char  := ': '; 
   g_delimiter := '|'; 
 
END ddl_utils;
/
