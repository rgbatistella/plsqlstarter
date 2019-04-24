CREATE OR REPLACE PACKAGE BODY num
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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'num';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Generic cursor for comparing two nested tables of number.
-- Will return any number in set one that doesn't appear in set two.
CURSOR cur_get_set_diff
(
   i_ntab1 IN num_tt
,  i_ntab2 IN num_tt
)
IS
SELECT o.column_value val
FROM   TABLE(CAST(i_ntab1 AS num_tt)) o
MINUS
SELECT n.column_value val
FROM   TABLE(CAST(i_ntab2 AS num_tt)) n;

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_set_diff
(
   i_ntab1 IN num_tt
,  i_ntab2 IN num_tt
) RETURN num_tt
IS
   lnt num_tt := num_tt();
BEGIN
   FOR lr IN cur_get_set_diff (i_ntab1, i_ntab2) LOOP
      lnt.EXTEND;
      lnt(lnt.COUNT) := lr.val;
   END LOOP;
   RETURN lnt;
END get_set_diff;

--------------------------------------------------------------------------------
--FUNCTION parse_list
--(
--   i_list IN VARCHAR2
--  ,i_delimiter IN VARCHAR2 DEFAULT ','
--) RETURN num_tt
--IS
--   lnt_tokens num_tt := num_tt();
--   l_remains VARCHAR2(32767) := i_list;
--BEGIN
--   WHILE (l_remains IS NOT NULL) LOOP
--      lnt_tokens.EXTEND;
--      SELECT
--         SUBSTR(l_remains,1,
--            DECODE(INSTR(l_remains,i_delimiter)
--            ,0,LENGTH(l_remains)+1,
--            INSTR(l_remains,i_delimiter)
--            )-1)
--        ,SUBSTR(l_remains,
--           DECODE(INSTR(l_remains,i_delimiter)
--           ,0,LENGTH(l_remains),
--           INSTR(l_remains,i_delimiter)
--           )+1)
--      INTO
--         lnt_tokens(lnt_tokens.COUNT)
--        ,l_remains
--      FROM dual;
--   END LOOP;
--   RETURN lnt_tokens;
--END parse_list;

--------------------------------------------------------------------------------
FUNCTION parse_list
(
   i_string    IN VARCHAR2,
   i_delimiter IN VARCHAR2 DEFAULT ',',
   i_ignore_nulls IN VARCHAR2 DEFAULT 'Y'
) RETURN num_tt
IS
   l_ntab       num_tt;
   l_cur_pos    INTEGER;
   l_next_pos   INTEGER;
  -- l_num_values INTEGER;
   l_consecutive_delimiters INTEGER;
   l_string     VARCHAR2(32767);
BEGIN
   l_ntab := num_tt();

   IF (i_string IS NOT NULL) THEN
      --l_num_values := 0;
      l_cur_pos    := 1;

      -- trim leading and trailing delimiters from the string
      -- Note: TRIM does not allow a trim set longer than one character, so we
      -- had to use LTRIM and RTRIM.
      l_string := LTRIM(RTRIM(i_string,i_delimiter),i_delimiter);

      IF (i_ignore_nulls = 'Y') THEN
         -- clean string of any consecutive delimiters
         l_consecutive_delimiters := INSTR(l_string,i_delimiter||i_delimiter);
         WHILE (l_consecutive_delimiters <> 0) LOOP
            l_string := REPLACE(l_string,i_delimiter||i_delimiter,i_delimiter);
            l_consecutive_delimiters := INSTR(l_string,i_delimiter||i_delimiter);
         END LOOP;
         --dbms_output.put_line(l_string); 
      END IF;
      
      l_next_pos := INSTR(l_string, i_delimiter);
      WHILE (l_next_pos <> 0) LOOP
         --l_num_values := l_num_values + 1;
         l_ntab.extend;
         l_ntab(l_ntab.COUNT) := TO_NUMBER(TRIM(SUBSTR(l_string,
                                            l_cur_pos,
                                            l_next_pos - l_cur_pos)));
                                             
         l_cur_pos  := l_next_pos + LENGTH(i_delimiter);
         
         WHILE (SUBSTR(l_string,l_cur_pos,LENGTH(i_delimiter)) = i_delimiter) LOOP
            -- Found consecutive delimiters. this is only possible if the caller
            -- passed in i_ignore_nulls = N above. Therefore, we will be assigning
            -- a NULL to the next position in the OUT array on purpose.
            l_ntab.extend;
            l_ntab(l_ntab.COUNT) := NULL;
            --l_num_values := l_num_values + 1;
            l_cur_pos := l_cur_pos + LENGTH(i_delimiter);
         END LOOP;
         
         l_next_pos := INSTR(l_string, i_delimiter, l_cur_pos);
         
      END LOOP;
         
      l_ntab.extend;
      l_ntab(l_ntab.COUNT) := TO_NUMBER(TRIM(SUBSTR(l_string, l_cur_pos)));
      -- Just in case the very last character was a space or non-printing
      IF (l_ntab(l_ntab.COUNT) IS NULL) THEN
         l_ntab.DELETE(l_ntab.COUNT);
      END IF;
   END IF;
   
   RETURN l_ntab;
   
END parse_list;

--------------------------------------------------------------------------------
FUNCTION make_list
(
   i_coll IN num_tt
  ,i_delimiter IN VARCHAR2 DEFAULT ','
) RETURN VARCHAR2
IS
   l_str typ.t_maxvc2;
BEGIN
   IF (i_coll.COUNT > 0) THEN
      FOR i IN i_coll.first..i_coll.last LOOP
         BEGIN
            IF (i > 1) THEN
              l_str := l_str || i_delimiter || TO_CHAR(i_coll(i));
            ELSE -- only hit on first item
               l_str := TO_CHAR(i_coll(i));
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN --for deleted entries in nested table
               NULL; -- move on to next entry (if any)
         END;
      END LOOP;
   END IF;
   RETURN l_str;
END make_list;

--------------------------------------------------------------------------------
FUNCTION IaNb (i_val IN VARCHAR2) RETURN BOOLEAN
IS
BEGIN
   IF ( TO_NUMBER(REPLACE(i_val,',',NULL)) IS NOT NULL) THEN
      RETURN TRUE;
   ELSE
      RAISE VALUE_ERROR;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RETURN FALSE;
END IaNb;

--------------------------------------------------------------------------------
FUNCTION IaN (i_val IN VARCHAR2) RETURN INTEGER
IS
BEGIN
   IF ( TO_NUMBER(REPLACE(i_val,',',NULL)) IS NOT NULL) THEN
      RETURN cnst.TRUE;
   ELSE
      RAISE VALUE_ERROR;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RETURN cnst.FALSE;
END IaN;

--------------------------------------------------------------------------------
FUNCTION is_oddb (
 i_num	IN NUMBER  
)  RETURN BOOLEAN
IS
BEGIN
	RETURN (MOD(i_num,2) = 1);
END is_oddb;

--------------------------------------------------------------------------------
FUNCTION is_evenb (
 i_num	IN NUMBER  
)  RETURN BOOLEAN
IS
BEGIN
	RETURN (MOD (i_num,2) = 0);
END is_evenb;

--------------------------------------------------------------------------------
FUNCTION is_odd (
 i_num	IN NUMBER  
)  RETURN NUMBER
IS
   l_bool BOOLEAN;
BEGIN
   l_bool := is_oddb(i_num);
   IF (l_bool IS NULL) THEN
      RETURN NULL;
   ELSIF (l_bool = TRUE) THEN
      RETURN 1;
   ELSIF (l_bool = FALSE) THEN
      RETURN 0;
   END IF;
END is_odd;

--------------------------------------------------------------------------------
FUNCTION is_even (
 i_num	IN NUMBER  
)  RETURN NUMBER
IS
   l_bool BOOLEAN;
BEGIN
   l_bool := is_evenb(i_num);
   IF (l_bool IS NULL) THEN
      RETURN NULL;
   ELSIF (l_bool = TRUE) THEN
      RETURN 1;
   ELSIF (l_bool = FALSE) THEN
      RETURN 0;
   END IF;
END is_even;

END num;
/
