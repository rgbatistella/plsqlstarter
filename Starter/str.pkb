CREATE OR REPLACE PACKAGE BODY str
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation
bcoulam      2012May22 Added TRIM to last element assignment in parse_list()

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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'str';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_diacritic_list RETURN VARCHAR2
IS
BEGIN
   RETURN '–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ¿¡¬√ƒ≈∆«»… ÀÃÕŒœ';
END get_diacritic_list;

--------------------------------------------------------------------------------
FUNCTION get_diacritic_map RETURN VARCHAR2
IS
BEGIN
   RETURN 'DNOOOOOxOUUUUYPBaaaaaaaceeeeiiiionooooo-ouuuuypyAAAAAAACEEEEIIII';
END get_diacritic_map;

--------------------------------------------------------------------------------
FUNCTION foreign_to_ascii (
   i_str   IN VARCHAR2
)  RETURN   VARCHAR2
IS
BEGIN
   IF (i_str IS NULL) THEN
      RETURN NULL;
   END IF;
   
   RETURN TRANSLATE(i_str, get_diacritic_list, get_diacritic_map);
END foreign_to_ascii;

--------------------------------------------------------------------------------
FUNCTION nonascii_to_ascii (
   i_str   IN VARCHAR2
) RETURN VARCHAR2
IS
BEGIN
   RETURN ASCIISTR(i_str);
END nonascii_to_ascii;

--------------------------------------------------------------------------------
FUNCTION format_to_width
(
   i_str        IN VARCHAR2,
   i_width      IN INTEGER DEFAULT cnst.pagewidth,
   i_allow_wrap IN VARCHAR2 DEFAULT 'Y'
) RETURN VARCHAR2
IS
   l_ostr VARCHAR2(32767); -- o[riginal]str[ing]
   l_nstr VARCHAR2(32767); -- n[ew]str[ing]
   l_piece VARCHAR2(32767);
   l_length PLS_INTEGER := 0;
   l_curr_pos PLS_INTEGER := 1; -- current position
   l_width PLS_INTEGER := 0;
   l_next_para PLS_INTEGER := 0;
   l_next_space PLS_INTEGER := 0;
   l_next_dash PLS_INTEGER := 0;
   DASH CHAR(1) := CHR(45);
   PARA  CHAR(1) := CHR(126);
BEGIN
   -- Check odd conditions first where the string needs no processing
   IF (i_str IS NULL) THEN
      RETURN NULL;
   END IF;
   
   l_length := LENGTH(i_str);
   
   -- convert paragraphs so they can be turned back into paragraphs after
   -- LF and CR replacement.
   l_ostr := REPLACE(
                REPLACE(
                   REPLACE(
                      REPLACE(
                         REPLACE(i_str, LF||LF, PARA)
                      , CR||LF, PARA)
                   , LF||CR, PARA)
                , LF, SP)
             , CR, SP);
   
   WHILE (l_curr_pos < l_length AND l_length > i_width) LOOP
      -- if there is a paragraph placeholder beyond the current pointer in the
      -- string, the SUBSTR chunk will be limited to its position, instead of
      -- the full requested width.
      l_next_para := INSTR(SUBSTR(l_ostr,l_curr_pos), PARA);
      IF (l_next_para = 0) THEN
         l_width := i_width;
      ELSE
         l_width := LEAST(i_width, l_next_para);
      END IF;
      
      -- We don't need to worry about disallowing wrap if not requested, or
      -- if the line is already predestined to be shortened due to the presence
      -- of a paragraph marker within the requested width.
      IF (l_width = i_width AND UPPER(i_allow_wrap) = 'N') THEN
         l_piece := SUBSTR(l_ostr, l_curr_pos, l_width);
         IF (LENGTH(l_piece) < l_width) THEN
            NULL; -- at end of string, take all that is left
         ELSE
            -- find last whitespace or dash before requested width
            l_next_space := INSTR(SUBSTR(l_piece,1),SP,-1);
            l_next_dash := INSTR(SUBSTR(l_piece,1),DASH,-1);
            IF (l_next_space > 0 OR l_next_dash > 0) THEN
               l_width := GREATEST(l_next_space,l_next_dash);
            ELSE
               --no whitespace or dashes whatsoever, so artificially chop the string
               -- at the requested width
               NULL;
            END IF;
         END IF;
      END IF;
      
      l_nstr := l_nstr || REPLACE(
                             LTRIM(SUBSTR(l_ostr, l_curr_pos, l_width))
                          ,PARA,LF) -- replace paragraph markers with extra line break
                          ||LF; -- add new line break
      l_curr_pos := l_curr_pos + l_width;
   END LOOP;
   
   IF (l_nstr IS NULL AND l_ostr IS NOT NULL AND l_length <= i_width) THEN
      -- Using TRIM and REPLACE for those strings shorter than the requested 
      -- width (which means they missed the operations of the WHILE loop above,
      -- evidenced by the fact that l_nstr has nothing in it).
      RETURN REPLACE(TRIM(l_ostr),PARA,LF||LF);
   ELSE
      RETURN l_nstr;
   END IF;
   
END format_to_width;

--------------------------------------------------------------------------------
FUNCTION ewc (
   i_str  IN VARCHAR2 DEFAULT NULL
,  i_colsize IN  PLS_INTEGER DEFAULT 1
)  RETURN VARCHAR2
IS
   s VARCHAR2 (2000) := NVL(i_str,'');
   slen PLS_INTEGER := NVL(length(i_str),0);
   diff  PLS_INTEGER := 0;
BEGIN
   IF (slen < i_colsize) THEN
      diff := i_colsize - slen;
      
      FOR i IN 1..diff LOOP
         s := s || ' ';
      END LOOP;
   ELSIF (slen > i_colsize) THEN
      s := substr(s,1,i_colsize);
   END IF;
   
   RETURN s;
END ewc;

--------------------------------------------------------------------------------
FUNCTION parse_list
(
   i_string    IN VARCHAR2,
   i_delimiter IN VARCHAR2 DEFAULT cnst.DELIMITER,
   i_ignore_nulls IN VARCHAR2 DEFAULT 'Y'
) RETURN str_tt
IS
   l_curr_pos    INTEGER;
   l_next_pos   INTEGER;
   -- l_num_values INTEGER;
   l_consecutive_delimiters INTEGER;
   l_string     VARCHAR2(32767);
   l_str_nt     str_tt;
BEGIN
   l_str_nt := str_tt();

   IF (i_string IS NOT NULL) THEN
   
      --l_num_values := 0;
      l_curr_pos    := 1;

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
         l_str_nt.extend;
         l_str_nt(l_str_nt.COUNT) := TRIM(SUBSTR(l_string,
                                            l_curr_pos,
                                            l_next_pos - l_curr_pos));
                                             
         l_curr_pos  := l_next_pos + LENGTH(i_delimiter);
         
         WHILE (SUBSTR(l_string,l_curr_pos,LENGTH(i_delimiter)) = i_delimiter) LOOP
            -- Found consecutive delimiters. this is only possible if the caller
            -- passed in i_ignore_nulls = N above. Therefore, we will be assigning
            -- a NULL to the next position in the OUT array on purpose.
            l_str_nt.extend;
            l_str_nt(l_str_nt.COUNT) := NULL;
            --l_num_values := l_num_values + 1;
            l_curr_pos := l_curr_pos + LENGTH(i_delimiter);
         END LOOP;
         
         l_next_pos := INSTR(l_string, i_delimiter, l_curr_pos);
         
      END LOOP;
         
      l_str_nt.extend;
      l_str_nt(l_str_nt.COUNT) := TRIM(SUBSTR(l_string, l_curr_pos));
   END IF;
   
   RETURN l_str_nt;
   
END parse_list;

--------------------------------------------------------------------------------
FUNCTION make_list (
   i_coll IN str_tt
,  i_delimiter IN VARCHAR2 DEFAULT cnst.DELIMITER
) RETURN VARCHAR2
IS
   l_str typ.t_maxvc2;
BEGIN
   IF (i_coll.COUNT > 0) THEN
      FOR i IN i_coll.first..i_coll.last LOOP
         BEGIN
            IF (i > 1) THEN
              l_str := l_str || i_delimiter || i_coll(i);
            ELSE -- only hit on first item
               l_str := i_coll(i);
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
FUNCTION trim_str (
   i_str   IN VARCHAR2
)  RETURN   VARCHAR2
IS
   l_char CHAR(1);
   l_str_len PLS_INTEGER:= LENGTH(i_str);
   l_idx PLS_INTEGER := 1;
   l_left_pos PLS_INTEGER := 0;
   l_right_pos PLS_INTEGER := 0;
   
BEGIN
   
   IF (i_str IS NULL) THEN
      RETURN NULL;
   ELSE
      l_char := SUBSTR(i_str, l_idx, 1);
   END IF;
   
   <<clean_left>>
   LOOP
      EXIT clean_left WHEN ( -- exits when first printing character is found
                 l_char > SP -- no spaces or non-printing
                 AND
                 l_char < DEL -- no delete char
                )
                OR
                (l_idx > l_str_len);
      l_idx := l_idx + 1;
      l_char := SUBSTR(i_str, l_idx, 1);
   END LOOP;
   
   IF (l_idx > l_str_len) THEN
      -- means we went through every character and didn't find a single
      -- one that was printable
      RETURN NULL;
      
   ELSE
   
      l_left_pos := l_idx; -- store position of first printing character
      
      l_idx := l_str_len;
      l_char := SUBSTR(i_str, l_idx, 1); --re-init starting at far right
      
      <<clean_right>>
      LOOP
         EXIT clean_right WHEN ( -- exits when first printing character is found
                    l_char > SP -- no spaces or non-printing
                    AND
                    l_char < DEL -- no delete char
                   );
         l_idx := l_idx - 1;
         l_char := SUBSTR(i_str, l_idx, 1);
      END LOOP;
      
      l_right_pos := l_idx;  -- store position of last printing character
   
      RETURN SUBSTR(i_str, l_left_pos, (l_right_pos - l_left_pos)+1);

   END IF;
   
END trim_str;

--------------------------------------------------------------------------------
FUNCTION purge_str (
   i_str                      IN VARCHAR2,
   i_preserve_tabs            IN VARCHAR2 DEFAULT 'N',
   i_preserve_linebreaks      IN VARCHAR2 DEFAULT 'N',
   i_convert_diacritics       IN VARCHAR2 DEFAULT 'N',
   i_convert_nonascii_to_ascii IN VARCHAR2 DEFAULT 'N'
)  RETURN   VARCHAR2
IS

   l_char NVARCHAR2(1);
   l_idx  PLS_INTEGER := 1;
   l_str_len PLS_INTEGER;
   l_ostr VARCHAR2(32767);
   l_nstr VARCHAR2(32767);
   
BEGIN
   
   IF (i_str IS NULL) THEN
      RETURN NULL;
   END IF;
   
   l_ostr := i_str;
   
   -- The order of these flag checks is important. If the user wants diacritics
   -- converted to something readable, it has to happen before the call to
   -- ASCIISTR, which would convert all multi-byte AND upper ASCII characters
   -- to the escaped Unicode sequence.
   IF (UPPER(i_convert_diacritics) = 'Y') THEN
      l_ostr := foreign_to_ascii(l_ostr);
   END IF;
   
   IF (UPPER(i_convert_nonascii_to_ascii) = 'Y') THEN
      l_ostr := ASCIISTR(l_ostr);
   END IF;
   
   -- Get rid of non-printing chars on either side
   l_ostr := trim_str(l_ostr);
   
   -- NOW we can finally determine how many characters we'll be processing
   l_str_len := LENGTH(l_ostr);

   WHILE l_idx <= l_str_len LOOP
      l_char := SUBSTR(l_ostr, l_idx, 1);
      
      -- Copy into new string buffer only those characters that are lower ASCII,
      -- printing characters.
      IF ((l_char >= SP AND l_char < DEL) OR
          (UPPER(i_preserve_tabs) = 'Y' AND l_char = TAB) OR
          (UPPER(i_preserve_linebreaks) = 'Y' AND l_char IN (LF,CR))) THEN
         l_nstr := l_nstr||l_char;
      END IF;
      l_idx := l_idx + 1;
   END LOOP;

   RETURN l_nstr;   

END purge_str;

--------------------------------------------------------------------------------
FUNCTION get_token (
   i_str IN VARCHAR2
,  i_delimiter IN VARCHAR2 DEFAULT cnst.DELIMITER
,  i_token_idx IN PLS_INTEGER DEFAULT 1
,  i_ignore_blanks IN VARCHAR2 DEFAULT 'Y'
)  RETURN VARCHAR2
IS
   las_tokens str_tt;
   l_tokens_found PLS_INTEGER := 0;
   l_token_desired VARCHAR2(2000);
BEGIN
   -- Call the procedure
   las_tokens := parse_list(i_str,i_delimiter,i_ignore_blanks);

   IF (las_tokens.COUNT > 0 AND i_token_idx <= las_tokens.COUNT) THEN
      <<array_traverse>>
      FOR i IN las_tokens.FIRST..las_tokens.LAST LOOP

         l_tokens_found := l_tokens_found + 1;
         
         IF (l_tokens_found = i_token_idx) THEN
            l_token_desired := trim_str(las_tokens(i));
            EXIT array_traverse;
         END IF;
         
      END LOOP;
      
      RETURN l_token_desired;

   ELSE
      RETURN NULL;
   END IF;
   
END get_token;

--------------------------------------------------------------------------------
FUNCTION contains_num (i_str IN VARCHAR2) RETURN INTEGER
IS
   l_result INTEGER := cnst.false;
BEGIN
   -- Replace any existing asterisks with a blank space, 
   -- then map any numbers found to an asterisk,
   -- then check for any asterisks, which would indicate the presence of a number
   IF INSTR(TRANSLATE(REPLACE(i_str,'*',' '),'0123456789','**********'),'*') > 0 THEN
      l_result := cnst.true;
   ELSE
      l_result := cnst.false;
   END IF;
   
   RETURN l_result;
   
END contains_num;

--------------------------------------------------------------------------------
FUNCTION ctr
(
   i_str        IN VARCHAR2,
   i_char       IN VARCHAR2 DEFAULT SP,
   i_page_width IN INTEGER DEFAULT cnst.PAGEWIDTH
) RETURN VARCHAR2
IS
   l_str_len INTEGER := LENGTH(i_str);
   l_width INTEGER := NVL(i_page_width,cnst.PAGEWIDTH);
   l_char VARCHAR2(1) := NVL(i_char,SP);
   l_space_left INTEGER := 0;
BEGIN
   l_space_left := l_width - l_str_len;
   
   IF (l_space_left <= 0) THEN
      -- Can't do anything with is, already longer than page width
      RETURN i_str;
   ELSE
      RETURN LPAD(RPAD(i_str,l_str_len+(l_space_left/2),l_char),l_width,l_char);
   END IF;
END ctr;

--------------------------------------------------------------------------------
PROCEDURE split_str (
  i_string     IN  VARCHAR2,
  i_splitchar  IN  VARCHAR2,
  oas_results   OUT typ.tas_large
)
IS
  l_curr_pos    NUMBER;
  l_next_pos   NUMBER;
  l_num_values NUMBER;
BEGIN
  l_num_values := 0;
  l_curr_pos    := 1;

  l_next_pos   := INSTR( i_string, i_splitchar );
  WHILE ( l_next_pos <> 0 ) LOOP
    l_num_values := l_num_values + 1;
    oas_results(l_num_values) := SUBSTR( i_string, l_curr_pos,
                                          l_next_pos - l_curr_pos );

    l_curr_pos := l_next_pos + LENGTH( i_splitchar );
    l_next_pos := INSTR( i_string, i_splitchar, l_curr_pos );

  END LOOP;

  oas_results(l_num_values + 1) := SUBSTR( i_string, l_curr_pos );

END split_str;



END str;
/
