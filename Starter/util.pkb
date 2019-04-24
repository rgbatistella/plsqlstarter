CREATE OR REPLACE PACKAGE BODY util
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

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
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_obj_type:
 Find the type of the object, given only the object name. Since there can be
 duplicate types for a given name (like the two entries for PACKAGE and PACKAGE
 BODY, for example, we have to filter the results on a set of limited types).
 
%warn
 This routine has a known flaw. If the constraint and the index match in
 name, the index will be found first and the returned type will be INDEX. Since
 this is the case 99% of the time with UK/PK constraints, the caller should call
 get_cons_by_idx() after get_obj_type to get the name of the constraint as well.
 
%param i_obj_nm The name of the object whose type is not known.
------------------------------------------------------------------------------*/
FUNCTION get_obj_type(i_obj_nm IN VARCHAR2) RETURN VARCHAR2 IS
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
              gc_trigger, gc_view, gc_type, gc_synonym);
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
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
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
FUNCTION bool_to_num(i_bool_val IN BOOLEAN) RETURN VARCHAR2
IS
BEGIN
   IF (i_bool_val) THEN
      RETURN 1;
   ELSIF (i_bool_val IS NULL) THEN
      RETURN NULL;
   ELSE
      RETURN 0;
   END IF;
END bool_to_num;

--------------------------------------------------------------------------------
FUNCTION str_to_bool(i_str IN VARCHAR2) RETURN BOOLEAN
IS
BEGIN
   IF (LOWER(i_str) IN ('true','y','yes','t','1')) THEN
      RETURN TRUE;
   ELSIF (LOWER(i_str) IN ('false','n','no','f','0')) THEN
      RETURN FALSE;
   ELSIF (i_str IS NULL) THEN
      RETURN NULL;
   ELSE
      logs.err('str_to_bool does not support ['||i_str||']');
   END IF;
END str_to_bool;

--------------------------------------------------------------------------------
FUNCTION num_to_bool(i_num IN NUMBER) RETURN BOOLEAN
IS
BEGIN
   IF (i_num = 0) THEN
      RETURN FALSE;
   ELSIF (i_num <> 0) THEN
      RETURN TRUE;
   ELSIF (i_num IS NULL) THEN
      RETURN NULL;
   ELSE
      logs.err('num_to_bool does not support ['||i_num||']');
   END IF;
END num_to_bool;

--------------------------------------------------------------------------------
FUNCTION ifnn (
 i_if   IN VARCHAR2
,i_then IN VARCHAR2
,i_else IN VARCHAR2 DEFAULT NULL
) RETURN VARCHAR2 IS
BEGIN
   RETURN(ite((i_if IS NOT NULL), i_then, i_else));
END ifnn;

FUNCTION ifnn (
 i_if		IN DATE
,i_then	IN DATE
,i_else	IN DATE DEFAULT NULL
)	RETURN DATE
IS
BEGIN
	RETURN (ite((i_if IS NOT NULL), i_then, i_else));
END ifnn;

FUNCTION ifnn (
 i_if		IN NUMBER
,i_then	IN NUMBER
,i_else	IN NUMBER DEFAULT NULL
)	RETURN NUMBER
IS
BEGIN
	RETURN (ite((i_if IS NOT NULL), i_then, i_else));
END ifnn;

--------------------------------------------------------------------------------
FUNCTION ifnull (
 i_if		IN VARCHAR2
,i_then	IN VARCHAR2
,i_else	IN VARCHAR2 DEFAULT NULL
)
	RETURN VARCHAR2
IS
BEGIN
	RETURN (ite(i_if IS NULL, i_then, i_else));
END ifnull;

FUNCTION ifnull (
 i_if		IN DATE
,i_then	IN DATE
,i_else	IN DATE DEFAULT NULL
)	RETURN DATE
IS
BEGIN
	RETURN (ite(i_if IS NULL, i_then, i_else));
END ifnull;

FUNCTION ifnull (
 i_if		IN NUMBER
,i_then	IN NUMBER
,i_else	IN NUMBER DEFAULT NULL
)	RETURN NUMBER
IS
BEGIN
	RETURN (ite(i_if IS NULL, i_then, i_else));
END ifnull;

--------------------------------------------------------------------------------
FUNCTION ite (
 i_if		IN BOOLEAN
,i_then	IN VARCHAR2
,i_else	IN VARCHAR2 DEFAULT NULL
)	RETURN VARCHAR2
IS
BEGIN
	IF (i_if) THEN
		RETURN (i_then);
	ELSE
		RETURN (i_else);
	END IF;
END ite;

FUNCTION ite (
 i_if		IN BOOLEAN
,i_then	IN DATE
,i_else	IN DATE DEFAULT NULL
)	RETURN DATE
IS
BEGIN
	IF (i_if) THEN
		RETURN (i_then);
	ELSE
		RETURN (i_else);
	END IF;
END ite;

FUNCTION ite (
 i_if		IN BOOLEAN
,i_then	IN NUMBER
,i_else	IN NUMBER DEFAULT NULL
)	RETURN NUMBER
IS
BEGIN
	IF (i_if) THEN
		RETURN (i_then);
	ELSE
		RETURN (i_else);
	END IF;
END ite;

--------------------------------------------------------------------------------
FUNCTION get_mime_type
(
   i_file_nm  IN VARCHAR2
) RETURN VARCHAR2
IS
   l_mime_type   typ.t_mime_type;
   -- most file extensions are 1-3 chars, but then there are .properties files...
   l_ext         VARCHAR2(10);
BEGIN
   -- If there is no file name given, or no extension on the file then return a 
   -- NULL, allowing the caller to decide the attachment's MIME type or default
   -- to text/plain if it doesn't want to bother.
   IF (i_file_nm IS NULL OR (INSTR(i_file_nm,'.') = 0)) THEN
      l_mime_type := NULL;
   ELSE
      -- Get extension (passing -1 to INSTR searches backwards from end of str)
      l_ext := SUBSTR(i_file_nm, INSTR(i_file_nm,'.',-1)+1);
         
      IF (l_ext IN ('txt','log','ora','lst','sql','out','bat','ini') ) THEN
         l_mime_type := 'text/plain';
      ELSIF (l_ext IN ('xls','csv','prn','dif','tsv') ) THEN
         l_mime_type := 'application/vnd.ms-excel';
      ELSIF (l_ext IN ('docx')) THEN
         l_mime_type := 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      ELSIF (l_ext IN ('ppsx')) THEN
         l_mime_type := 'application/vnd.openxmlformats-officedocument.presentationml.slideshow';
      ELSIF (l_ext IN ('pptx')) THEN
         l_mime_type := 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      ELSIF (l_ext IN ('xlsx')) THEN
         l_mime_type := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      ELSIF (l_ext IN ('htm','html') ) THEN
         l_mime_type := 'text/html';
      ELSIF (l_ext = 'xml') THEN
         l_mime_type := 'text/xml';
      ELSIF (l_ext IN ('doc','asc','ans') ) THEN
         l_mime_type := 'application/msword';
      ELSIF (l_ext = ('rtf') ) THEN
         l_mime_type := 'text/rtf';
      ELSIF (l_ext = ('zip') ) THEN
         l_mime_type := 'application/zip';
      ELSIF (l_ext = ('gif') ) THEN
         l_mime_type := 'image/gif';
      ELSIF (l_ext IN ('jpeg','jpg') ) THEN
         l_mime_type := 'image/jpeg';
      ELSIF (l_ext = 'pdf') THEN
         l_mime_type := 'application/pdf';
      -- below are less frequently used as attachments
      ELSIF (l_ext = 'css') THEN
         l_mime_type := 'text/css';
      ELSIF (l_ext = 'gtar') THEN
         l_mime_type := 'application/x-gtar';
      ELSIF (l_ext = 'gz') THEN
         l_mime_type := 'application/x-gzip';
      ELSIF (l_ext = 'js') THEN
         l_mime_type := 'application/x-javascript';
      ELSIF (l_ext = 'png') THEN
         l_mime_type := 'image/png';
      ELSIF (l_ext = 'tar') THEN
         l_mime_type := 'application/x-tar';
      ELSIF (l_ext IN ('tif','tiff') ) THEN
         l_mime_type := 'image/tiff';
      ELSIF (l_ext = 'svg') THEN
         l_mime_type := 'image/svg+xml';   
      ELSIF (l_ext = 'dat') THEN
         l_mime_type := 'application/octet-stream';
      ELSIF (l_ext = 'mdb') THEN
         l_mime_type := 'application/x-msaccess';
      ELSIF (l_ext = 'sxw') THEN
         l_mime_type := 'application/vnd.sun.xml.writer';
      ELSIF (l_ext = 'sxc') THEN
         l_mime_type := 'application/vnd.sun.xml.calc';
      ELSIF (l_ext = 'sxi') THEN
         l_mime_type := 'application/vnd.sun.xml.impress';
      ELSIF (l_ext = 'sxd') THEN
         l_mime_type := 'application/vnd.sun.xml.draw';
      ELSIF (l_ext = 'sxm') THEN
         l_mime_type := 'application/vnd.sun.xml.math';
      ELSIF (l_ext = 'odt') THEN
         l_mime_type := 'application/vnd.oasis.opendocument.text';
      ELSIF (l_ext = 'oth') THEN
         l_mime_type := 'application/vnd.oasis.opendocument.text-web';
      ELSIF (l_ext = 'odg') THEN
         l_mime_type := 'application/vnd.oasis.opendocument.graphics';
      ELSIF (l_ext = 'odp') THEN
         l_mime_type := 'application/vnd.oasis.opendocument.presentation';
      ELSIF (l_ext = 'ods') THEN
         l_mime_type := 'application/vnd.oasis.opendocument.spreadsheet';
      ELSIF (l_ext = 'odb') THEN
         l_mime_type := 'application/vnd.oasis.opendocument.database';
      ELSIF (l_ext = 'odi') THEN
         l_mime_type := 'application/vnd.oasis.opendocument.image';
      ELSE
         l_mime_type := 'application/octet-stream';
      END IF;
   END IF;
   
   RETURN l_mime_type;

END get_mime_type;

--------------------------------------------------------------------------------
FUNCTION get_otx_doc_type(i_mime_type IN typ.t_mime_type) RETURN VARCHAR2
IS
   l_otx_doc_type app_email_doc.otx_doc_type%TYPE;
BEGIN
   IF (i_mime_type IS NULL OR i_mime_type IN ('image/jpeg','image/gif',
       'application/x-gtar','application/x-gzip','image/png','image/svg+xml',
       'image/tiff','application/x-tar','application/vnd.sun.xml.draw',
       'application/vnd.oasis.opendocument.graphics',
       'application/vnd.oasis.opendocument.image')) THEN

      l_otx_doc_type := 'IGNORE';

   ELSIF (i_mime_type IN ('text/rtf','text/html','text/plain','text/xml',
          'text/css','application/x-javascript','application/vnd.oasis.opendocument.text',
          'application/vnd.oasis.opendocument.text-web')) THEN

      l_otx_doc_type := 'TEXT';

   ELSIF (i_mime_type IN ('application/zip','application/msword','application/pdf',
          'application/vnd.ms-excel','application/octet-stream',
          'application/x-msaccess','application/vnd.sun.xml.writer',
          'application/vnd.sun.xml.calc','application/vnd.sun.xml.impress',
          'application/vnd.sun.xml.math','application/vnd.oasis.opendocument.presentation',
          'application/vnd.oasis.opendocument.spreadsheet',
          'application/vnd.oasis.opendocument.database',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')) THEN

      l_otx_doc_type := 'BINARY';

   END IF;

   RETURN l_otx_doc_type;

END get_otx_doc_type;

--------------------------------------------------------------------------------
FUNCTION convert_clob_to_blob (i_clob IN CLOB) RETURN BLOB
AS
   ln_cloblen  INTEGER := 0;
   l_blob   BLOB;
   
   -- vars for loop and conversion
   ln_offset NUMBER := 1;
   ln_num_chars NUMBER := 2000;
   l_rawchunk RAW(4000);
   ls_buffer typ.t_maxvc2;
BEGIN
   IF (i_clob IS NULL) THEN
      RETURN NULL;
   END IF;
   
   -- get input length   
   ln_cloblen := dbms_lob.getlength(i_clob);
     
   IF (ln_cloblen = 0) THEN
      RETURN EMPTY_BLOB();
   END IF;
   
   dbms_lob.createtemporary(l_blob, TRUE);

   LOOP
      EXIT WHEN ln_offset > ln_cloblen;

      -- get buffer
      ls_buffer := dbms_lob.substr(i_clob, ln_num_chars, ln_offset);
         
      -- convert to raw
      l_rawchunk := utl_raw.cast_to_raw(ls_buffer);
         
      -- write the converted data to the blob column
      dbms_lob.write(l_blob, utl_raw.length(l_rawchunk), ln_offset, l_rawchunk);
         
      ln_offset := ln_offset + ln_num_chars;
   END LOOP;
   
   RETURN l_blob;

END convert_clob_to_blob;

--------------------------------------------------------------------------------
FUNCTION convert_blob_to_clob(i_blob IN BLOB) RETURN CLOB AS
   ln_bloblen INTEGER := 0;
   l_clob     CLOB;

   ln_src_offset    NUMBER := 1;
   ln_dest_offset   NUMBER := 1;
   --ln_num_chars     NUMBER := 32767;
   --l_buffer         typ.t_maxvc2;
   l_lang_context   INTEGER := dbms_lob.default_lang_ctx;
   l_warning        INTEGER;
BEGIN
   IF (i_blob IS NULL) THEN
      RETURN NULL;
   END IF;

   -- get input length   
   ln_bloblen := dbms_lob.getlength(i_blob);

   IF (ln_bloblen = 0) THEN
      RETURN EMPTY_CLOB();
   END IF;

   dbms_lob.createtemporary(l_clob, TRUE);

--   FOR i IN 1 .. CEIL(ln_bloblen / ln_num_chars) LOOP
--   
--      l_buffer := utl_raw.cast_to_varchar2(dbms_lob.substr(i_blob, ln_num_chars, ln_src_offset));
--   
--      dbms_lob.writeappend(l_clob, LENGTH(l_buffer), l_buffer);
--   
--      ln_src_offset := ln_src_offset + ln_num_chars;
--   END LOOP;

   dbms_lob.converttoclob(dest_lob     => l_clob
                         ,src_blob     => i_blob
                         ,amount       => dbms_lob.lobmaxsize
                         ,dest_offset  => ln_dest_offset
                         ,src_offset   => ln_src_offset
                         ,blob_csid    => dbms_lob.default_csid
                         ,lang_context => l_lang_context
                         ,warning      => l_warning);

   RETURN l_clob;
   
END convert_blob_to_clob;

--------------------------------------------------------------------------------
FUNCTION obj_exists
(
   i_obj_nm   IN VARCHAR2,
   i_obj_type IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN IS
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
      excp.assert(
         i_expr => l_obj_type IN (gc_table, gc_index, gc_package, gc_sequence, 
                                  gc_trigger, gc_view, gc_type, gc_synonym, gc_constraint),
         i_msg => i_obj_type ||' is not a supported object type.');
   
      IF (l_obj_type IN (gc_table, gc_index, gc_package, gc_sequence,
          gc_trigger, gc_view, gc_type, gc_synonym)) THEN
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
) RETURN BOOLEAN IS
   l_proc_nm   user_objects.object_name%TYPE := 'attr_exists';
   l_obj_nm    user_objects.object_name%TYPE;
   l_obj_type  user_objects.object_type%TYPE;
   l_attr_nm   VARCHAR2(30);
   l_attr_type VARCHAR2(20);
   l_count     INTEGER := 0;
BEGIN
   l_obj_nm := upper(i_obj_nm);
   excp.assert(
      i_expr => obj_exists(l_obj_nm),
      i_msg => l_obj_nm || ' does not exist.');

   l_obj_type := get_obj_type(l_obj_nm);

   l_attr_type := upper(i_attr_type);
   excp.assert(
      i_expr => l_attr_type IN (gc_column, gc_attribute, gc_method, gc_routine, 
                                gc_part, gc_subpart),
      i_msg => l_attr_type || ' is not a supported attribute type.');

   l_attr_nm := upper(i_attr_nm);
   -- Based on attribute type, pull count from data dictionary
   CASE
      WHEN (l_attr_type = gc_column AND l_obj_type = gc_table) THEN
         SELECT COUNT(*)
           INTO l_count
           FROM user_tab_columns
          WHERE table_name = l_obj_nm
            AND column_name = l_attr_nm;
      
      WHEN (l_attr_type = gc_attribute AND l_obj_type = gc_type) THEN
         SELECT COUNT(*)
           INTO l_count
           FROM user_type_attrs
          WHERE type_name = l_obj_nm
            AND attr_name = l_attr_nm;
      
      WHEN (l_attr_type = gc_method AND l_obj_type = gc_type) THEN
         SELECT COUNT(*)
           INTO l_count
           FROM user_type_methods
          WHERE type_name = l_obj_nm
            AND method_name = l_attr_nm;
      
      WHEN (l_attr_type = gc_routine AND l_obj_type = gc_package) THEN
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
               AND partition_name = l_attr_nm;
         ELSIF (l_obj_type = gc_index) THEN
            SELECT COUNT(*)
              INTO l_count
              FROM user_ind_partitions
             WHERE index_name = l_obj_nm
               AND partition_name = l_attr_nm;
         END IF;
      WHEN (l_attr_type = gc_subpart AND l_obj_type IN (gc_table, gc_index)) THEN
         IF (l_obj_type = gc_table) THEN
            SELECT COUNT(*)
              INTO l_count
              FROM user_tab_subpartitions
             WHERE table_name = l_obj_nm
               AND subpartition_name = l_attr_nm;
         ELSIF (l_obj_type = gc_index) THEN
            SELECT COUNT(*)
              INTO l_count
              FROM user_ind_subpartitions
             WHERE index_name = l_obj_nm
               AND subpartition_name = l_attr_nm;
         END IF;
      ELSE
         logs.err('You have asked for the existence of a(n) ' ||
             l_attr_type || ' on a ' || l_obj_type ||
             '. This is not a supported combination for' || ' ' || l_proc_nm ||
             '().');
   END CASE;

   IF (l_count = 0) THEN
      RETURN FALSE;
   ELSE
      RETURN TRUE;
   END IF;
END attr_exists;

--------------------------------------------------------------------------------
FUNCTION get_max_pk_val(i_table_nm IN VARCHAR2) RETURN INTEGER IS
   l_pk_col_nm  user_cons_columns.column_name%TYPE;
   l_table_nm   user_tables.table_name%TYPE;
   l_max_pk_val INTEGER := 0;
BEGIN

   l_table_nm := UPPER(i_table_nm);

   excp.assert(
      i_expr => obj_exists(l_table_nm, gc_table),
      i_msg => ' Cannot find table ' || l_table_nm);

   BEGIN
      -- This SQL assumes the table has a single-column surrogate PK. The 
      -- exception section handles those tables that don't conform to this scheme.
      SELECT column_name
        INTO l_pk_col_nm
        FROM user_cons_columns
       WHERE table_name = l_table_nm
         AND constraint_name =
             (SELECT constraint_name
                FROM user_constraints
               WHERE constraint_type = 'P'
                 AND table_name = l_table_nm);
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logs.err('There is no primary key for table ' ||l_table_nm);
      WHEN TOO_MANY_ROWS THEN
         logs.err('Table ' || l_table_nm ||
             ' has a primary key that is composed of more than one column.');
   END;

   EXECUTE IMMEDIATE 'SELECT MAX('||l_pk_col_nm||') FROM ' || l_table_nm
      INTO l_max_pk_val;

   RETURN l_max_pk_val;

END get_max_pk_val;

--------------------------------------------------------------------------------
PROCEDURE reset_seq
(
   i_seq_nm IN VARCHAR2,
   i_tbl_nm IN VARCHAR2 DEFAULT NULL
) IS

   l_seq_nm         user_sequences.sequence_name%TYPE;
   l_table_name     user_tables.table_name%TYPE;
   l_seq_rec        user_sequences%ROWTYPE;
   l_gap            INTEGER := 0;
   l_nextval        INTEGER := 0;
   l_maxval         INTEGER := 0;
   l_pk_col         VARCHAR2(30);
   l_dump           INTEGER := 0;
BEGIN
   l_seq_nm := UPPER(i_seq_nm);
   
   excp.assert(
      i_expr => obj_exists(l_seq_nm, gc_sequence),
      i_msg => 'Sequence ' || l_seq_nm || ' does not exist.');
   
   IF (i_tbl_nm IS NULL) THEN
      -- Attempt to get table name from sequence name. Most sequence
      -- naming standards will either be SEQ_TABLE_NAME, TABLE_NAME_SEQ or
      -- TABLE_NAME_ID_SEQ. So we will try to extract TABLE_NAME given
      -- those patterns.
      l_table_name := REPLACE(REPLACE(REPLACE(l_seq_nm,'SEQ_',NULL),'_SEQ',NULL),'_ID',NULL);
      
      excp.assert(
         i_expr => obj_exists(l_table_name, gc_table),
         i_msg => 'Cannot extract table name from ' || l_seq_nm);
   ELSE
      l_table_name := UPPER(i_tbl_nm);
      excp.assert(
         i_expr => obj_exists(l_table_name, gc_table),
         i_msg => 'Table ' || l_table_name ||' does not exist.');
   END IF;

   BEGIN
      SELECT column_name
        INTO l_pk_col
        FROM user_cons_columns
       WHERE constraint_name = (SELECT constraint_name
                                  FROM user_constraints
                                 WHERE table_name = l_table_name
                                   AND constraint_type = 'P');
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logs.err('No PK found for table '||l_table_name);
   END;
   
   -- See what the next value would be; unfortunately, this uses up a number.
   -- Cannot use user_sequences.last_number because it is the current sequence
   -- number + cache. No way to find out where the sequence is really at except
   -- by selecting from it.
   EXECUTE IMMEDIATE 'SELECT '||l_seq_nm||'.NEXTVAL FROM DUAL' INTO l_nextval;
   -- Now find out where the ID is currently at in the target table.
   EXECUTE IMMEDIATE 'SELECT MAX(' || l_pk_col || ') FROM ' || l_table_name INTO l_maxval;

   IF (l_nextval <= l_maxval) THEN
   
      logs.info(l_seq_nm || ' is at ' ||
                           TO_CHAR(l_nextval) || ', but ' ||
                           l_table_name || ' is at ' || TO_CHAR(l_maxval) ||
                           '. Resetting...');
   
      -- get sequence metadata before it gets altered
      SELECT *
        INTO l_seq_rec
        FROM user_sequences
       WHERE sequence_name = l_seq_nm;
      
      l_gap := l_maxval - l_nextval;

      -- Bump up the sequence. We do this instead of recreating it so we don't
      -- invalidate existing code. At least that's the theory. I haven't tested
      -- that theory to see if it holds true.  
      EXECUTE IMMEDIATE 'ALTER SEQUENCE '||l_seq_nm||' INCREMENT BY '||l_gap||' NOCACHE';
      EXECUTE IMMEDIATE 'SELECT '||l_seq_nm||'.NEXTVAL FROM dual' INTO l_dump;
      EXECUTE IMMEDIATE 'ALTER SEQUENCE '||l_seq_nm||' INCREMENT BY 1 NOCACHE';
   
--      LOOP
--         EXECUTE IMMEDIATE 'SELECT ' || l_seq_nm || '.CURRVAL FROM dual' INTO l_dump;
--         EXIT WHEN l_dump >= l_maxval - 1;
--         EXECUTE IMMEDIATE 'SELECT ' || l_seq_nm || '.NEXTVAL FROM dual' INTO l_dump;
--      END LOOP;
   
      EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || l_seq_nm ||
                        ' INCREMENT BY '||l_seq_rec.increment_by||
                        ' CACHE ' || l_seq_rec.cache_size;
   END IF;

END reset_seq;

END util;
/
