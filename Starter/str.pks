CREATE OR REPLACE PACKAGE str
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Package bundling generic routines for string manipulation/handling.  

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

-- {%skip}
-- generic print control constants
NUL   CONSTANT VARCHAR2(1) := CHR(0); -- null character
TAB   CONSTANT VARCHAR2(1) := CHR(9); -- A single tab character
CR    CONSTANT VARCHAR2(1) := CHR(13); -- A single carriage return character (^M)
LF    CONSTANT VARCHAR2(1) := CHR(10); -- A single linefeed character
LFCR  CONSTANT VARCHAR2(2) := CHR(10)||CHR(13); -- Odd duck
CRLF  CONSTANT VARCHAR2(2) := CHR(13)||CHR(10); -- Common Microsoft line break
FF    CONSTANT VARCHAR2(1) := CHR(12); -- A form feed
SP    CONSTANT VARCHAR2(1) := CHR(32); -- A space
DEL   CONSTANT VARCHAR2(1) := CHR(127); -- old delete, non-printing, end of ASCII set

-- {%skip}
-- empty collections
empty_str_tab str_tt := str_tt();

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------
/**-----------------------------------------------------------------------------
get_diacritic_list:
 Returns a string of foreign characters which maps 1:1, character for character,
 the map returned by get_diacritic_map.
------------------------------------------------------------------------------*/
FUNCTION get_diacritic_list RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
get_diacritic_map:
 Returns a string of lower range ASCII characters that map character for
 character, position for position, the list of characters returned by
 get_diacritic_list;
------------------------------------------------------------------------------*/
FUNCTION get_diacritic_map RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
foreign_to_ascii:
 Reads a string and converts all "foreign" characters to plain ASCII characters.
 Foreign characters are defined as those that fall in the upper range of the 
 ISO-8859-1, or extended ASCII, character set.
 
 If there are any extended ASCII characters not mapped by the underlying
 TRANSLATE function, or any Unicode characters, they will be preserved as-is.
 If you desire these characters to also be rendered as ASCII, either wrap
 this function with a call to ASCIISTR(), or use %see nonascii_to_ascii instead.
 
%param i_str String with foreign characters which need translation to plain 
             ASCII characters.
------------------------------------------------------------------------------*/
FUNCTION foreign_to_ascii (
   i_str   IN VARCHAR2
)  RETURN   VARCHAR2;

/**-----------------------------------------------------------------------------
nonascii_to_ascii:
 Anything outside the range of the lower ASCII set (128-255) as well as Unicode
 characters, will be converted to Unicode escape codes, e.g. the Euro symbol 
 CHR(128) will be returned as \20AC.
 
 If you desire to preserve the Latin-looking foreign characters with diacritics
 as their lower ASCII equivalents,, call %foreign_to_ascii instead and wrap it
 with ASCIISTR().

%param i_str String with foreign characters which need conversion to plain 
             ASCII characters as Unicode escape codes (UTF-16 code unit).
 ------------------------------------------------------------------------------*/
FUNCTION nonascii_to_ascii (
   i_str   IN VARCHAR2
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
format_to_width:
 This function takes in a string and a width to "break" the string into 
 lines of manageable width by means of inserted linefeeds. Paragraphs will be
 preserved. Other linefeeds and carriage returns will be removed.

%param i_str Hunk of disorderly or very long text to break into manageable-width
             lines.
%param i_width Width to use in breaking up long strings. Uses default value
               if not given.
%param i_allow_wrap If Y[es] (the default) will break strings unceremoniously
                    when it reaches the requested width. If wrap is not allowed,
                    then words will not be broken unnaturally. Instead whole
                    words will be preserved; lines will only be broken at the
                    last whitespace or dash character before the requested width.
------------------------------------------------------------------------------*/
FUNCTION format_to_width
(
   i_str        IN VARCHAR2,
   i_width      IN INTEGER DEFAULT cnst.pagewidth,
   i_allow_wrap IN VARCHAR2 DEFAULT 'Y'
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
ewc:
 ewc stands for equal-width columns. When HTML tables are overkill and you've 
 got a result set you want to  display in columns, use this function to pad or 
 trim a string down to the desired column width. CAUTION: This will NOT work if
 the output isn't viewed in a fixed-width font, like Courier.

%param i_str string to fill or trim
%param i_colsize column size desired
------------------------------------------------------------------------------*/
FUNCTION ewc
(
   i_str     IN VARCHAR2 DEFAULT NULL,
   i_colsize IN PLS_INTEGER DEFAULT 1
) RETURN VARCHAR2;

/**------------------------------------------------------------------------------
parse_list:
Takes a delimited list of values and returns a collection of strings, that can
subsequently be used to join in SQL queries or used in other processing.

If your delimiter is something other than a comma, change the value of the second
parameter, i_delimiter, to the delimiter you want. It can handle multiple-character
delimiters if you need that, e.g. :: or => and other such dividers and seperators.

%param i_string The delimited list that will be broken out into individual
                strings in a nested table collection.
              
%param i_delimiter Default is ",". The delimiter used to split up the tokens.

%param i_ignore_nulls If you specify or allow the default of Y, then any 
                      consecutive delimiters in the list will be eliminated.
                      For example, 1,2,,4,5 will only return 4 integer values.
                      If you specify N, then consecutive delimiters will be
                      treated as a NULL value that is desired.
                      For example, 1,2,,4,5 will return 5 elements in the 
                      nested_table. The third value will be a NULL.

%return
 Nested table of strings.
                       
------------------------------------------------------------------------------*/
FUNCTION parse_list
(
   i_string    IN VARCHAR2,
   i_delimiter IN VARCHAR2 DEFAULT cnst.DELIMITER,
   i_ignore_nulls IN VARCHAR2 DEFAULT 'Y'
) RETURN str_tt;

/**-----------------------------------------------------------------------------
make_list:
 Takes an array of strings and returns a delimited list of the same in a single
 string. The returned string can be up to 32767 bytes long, so the receiving
 variable or column should be the same size, or the result should be truncated
 using SUBSTR.

 Obviously, if one of the strings includes a character which is the requested
 delimiter, that string will be broken up where it ought not.

%param i_coll Collection
%param i_delimiter Delimiter
------------------------------------------------------------------------------*/
FUNCTION make_list
(
   i_coll      IN str_tt,
   i_delimiter IN VARCHAR2 DEFAULT cnst.DELIMITER
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
trim_str:
 This function takes in a string and cleans off ALL non-printing characters from
 the left and right side. Any non-printing characters in the middle of the 
 string are left alone. If you need to get rid of ALL non-printing characters,
 except SPACE, call %see purge_str.

%param i_str String with garbage characters on one end, or ends, which need 
             removal.
------------------------------------------------------------------------------*/
FUNCTION trim_str (
   i_str   IN VARCHAR2
)  RETURN   VARCHAR2;

/**-----------------------------------------------------------------------------
purge_str:
 This function takes in a string and cleans out ALL non-printing characters 
 except the SPACE character. If tabs and linebreaks (ordinarily invisible) are
 still needed, alter one or both of the last two parameters to Y. Since multi-
 byte characters are also technically non-printing in many ASCII-oriented
 systems and software, the last parameter allows you to convert those to Unicode
 escape codes as well if set to Y.

%param i_str Candidate string bearing garbage characters which need removing.
%param i_preserve_tabs If Y, will leave ASCII character 9 intact.
%param i_preserve_linebreaks If Y, will leave ASCII characters 10 and 13 intact.
%param i_convert_diacritics If Y, will translate extended ASCII letter chars 
                            (128-255) to lower ASCII equivalents before applying
                            non-ascii conversion (if requested). This allows
                            Latin-looking characters to still be read or 
                            displayed, without the Unicode substitution. If left
                            as N, characters with diacritics will be removed.
%param i_convert_nonascii_to_ascii If Y, will convert non-ascii characters to
                                  the escaped Unicode equivalent. These codes
                                  can be wrapped by UNISTR to return them to
                                  the original characters. If left as N, Unicode
                                  and extended ASCII characters will be removed.
------------------------------------------------------------------------------*/
FUNCTION purge_str
(
   i_str                       IN VARCHAR2,
   i_preserve_tabs             IN VARCHAR2 DEFAULT 'N',
   i_preserve_linebreaks       IN VARCHAR2 DEFAULT 'N',
   i_convert_diacritics        IN VARCHAR2 DEFAULT 'N',
   i_convert_nonascii_to_ascii IN VARCHAR2 DEFAULT 'N'
) RETURN VARCHAR2;



/**-----------------------------------------------------------------------------
get_token:
 Takes a delimited string, uses parse_list to turn it into an array of
 tokens, then returns the desired token to the caller.
 If the caller wants the function to ignore empty tokens (tokens with nothing
 or just non-printing and space characters), the third, optional parameter is
 set to TRUE.

%param i_str Delimited string, otherwise known as a list.
%param i_delimiter Character to look for as the delimiter.
%param i_token_idx The position of the token you desire in the delimited list.
%param i_ignore_blanks Whether to ignore empty tokens when determining position.
------------------------------------------------------------------------------*/
FUNCTION get_token
(
   i_str           IN VARCHAR2,
   i_delimiter     IN VARCHAR2 DEFAULT cnst.DELIMITER,
   i_token_idx     IN PLS_INTEGER DEFAULT 1,
   i_ignore_blanks IN VARCHAR2 DEFAULT 'Y'
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
contains_num:
 Will return a 1 if the given string contains a number, 0 if no number is found.

%design
 Decided to use 1/0 instead of BOOLEAN return, so that this function could be
 used within SQL.

%param i_str The string to check for the existence of any numbers.
------------------------------------------------------------------------------*/
FUNCTION contains_num (i_str IN VARCHAR2) RETURN INTEGER;


/**-----------------------------------------------------------------------------
ctr:
 Will return the given str centered within the page width. If no page width is
 provided, the default set in CNST will be assumed.
 
%param i_str The string to check for the existence of any numbers.
%param i_char The character to use in padding the centered text, defaults to space.
%param i_page_width The width of the space within which the text must be centered.
------------------------------------------------------------------------------*/
FUNCTION ctr
(
   i_str        IN VARCHAR2,
   i_char       IN VARCHAR2 DEFAULT SP,
   i_page_width IN INTEGER DEFAULT cnst.PAGEWIDTH
) RETURN VARCHAR2;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
split_str:
 This routine shares the same purpose as parse_list. However, it is implemented
 differently. It is less robust, but does operate at twice the speed as parse_list.
 If you have a need for a speedier parser, and your lists are not sparse, but well-
 packed and delimited, you might want to use split_str instead.

%param i_string  Delimited string, otherwise known as a list.
%param i_splitchar Character to use as the delimiter. The delimiter can be multiple
                   characters, like ::, =>, etc.
%param oas_results The filled PL/SQL table of strings parsed out of the delimited
                   list.
------------------------------------------------------------------------------*/
PROCEDURE split_str (
  i_string     IN  VARCHAR2,
  i_splitchar  IN  VARCHAR2,
  oas_results   OUT typ.tas_large
);


END str;
/
