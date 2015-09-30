CREATE OR REPLACE PACKAGE BODY codes
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
gc_pkg_nm CONSTANT user_source.name%TYPE := 'codes';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_code_defn
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE
,  i_code_val IN app_code.code_val%TYPE
)  RETURN app_code.code_defn%TYPE
IS
   l_code_defn  app_code.code_defn%TYPE;
BEGIN
   SELECT code_defn
   INTO   l_code_defn
   FROM   app_code_vw
   WHERE  codeset_nm = i_codeset_nm
   AND    code_val = i_code_val;
   
   RETURN l_code_defn;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL; 
END get_code_defn;

--------------------------------------------------------------------------------
FUNCTION get_code_defn
(
   i_code_id IN app_code.code_id%TYPE
)  RETURN app_code.code_defn%TYPE
IS
   l_code_defn  app_code.code_defn%TYPE;
BEGIN
   SELECT code_defn
   INTO   l_code_defn
   FROM   app_code_vw
   WHERE  code_id = i_code_id;
   
   RETURN l_code_defn;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL; 
END get_code_defn;

--------------------------------------------------------------------------------
FUNCTION get_code_id
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE
,  i_code_val IN app_code.code_val%TYPE
)  RETURN app_code.code_id%TYPE
IS
   l_code_id  app_code.code_id%TYPE;
BEGIN
   SELECT code_id
   INTO   l_code_id
   FROM   app_code_vw
   WHERE  codeset_nm = i_codeset_nm
   AND    code_val = i_code_val;
   
   RETURN l_code_id;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL; 
END get_code_id;

--------------------------------------------------------------------------------
FUNCTION get_code_val
(
   i_code_id IN app_code.code_id%TYPE
)  RETURN app_code.code_val%TYPE
IS
   l_code_val  app_code.code_val%TYPE;
BEGIN
   SELECT code_val
   INTO   l_code_val
   FROM   app_code_vw
   WHERE  code_id = i_code_id;
   
   RETURN l_code_val;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
END get_code_val;

--------------------------------------------------------------------------------
FUNCTION get_codeset_id
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE
) RETURN app_codeset.codeset_id%TYPE
IS
   l_codeset_id  app_codeset.codeset_id%TYPE;
BEGIN
   SELECT DISTINCT codeset_id
   INTO   l_codeset_id
   FROM   app_codeset_vw
   WHERE  codeset_nm = i_codeset_nm;
   
   RETURN l_codeset_id;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
END get_codeset_id;

--------------------------------------------------------------------------------
FUNCTION get_codeset_nm
(
   i_codeset_id IN app_codeset.codeset_id%TYPE
) RETURN app_codeset.codeset_nm%TYPE
IS
   l_codeset_nm  app_codeset.codeset_nm%TYPE;
BEGIN
   SELECT codeset_nm
   INTO   l_codeset_nm
   FROM   app_codeset_vw
   WHERE  codeset_id = i_codeset_id;
   
   RETURN l_codeset_nm;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
END get_codeset_nm;

--------------------------------------------------------------------------------
FUNCTION get_parent_codeset_id
(
   i_codeset_id IN app_codeset.codeset_id%TYPE
) RETURN app_codeset.parent_codeset_id%TYPE
IS
   l_parent_codeset_id  app_codeset.parent_codeset_id%TYPE;
BEGIN
   SELECT parent_codeset_id
   INTO   l_parent_codeset_id
   FROM   app_codeset_vw
   WHERE  codeset_id = i_codeset_id;
   
   RETURN l_parent_codeset_id;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
END get_parent_codeset_id;

--------------------------------------------------------------------------------
FUNCTION get_codeset_cur
(
   i_codeset_nm IN app_codeset.codeset_nm%TYPE,
   i_return_defn IN BOOLEAN DEFAULT FALSE
) RETURN SYS_REFCURSOR
IS
   l_rc SYS_REFCURSOR;
BEGIN
   IF (i_return_defn) THEN
      OPEN l_rc FOR
        SELECT code_val, code_id, code_defn
        FROM   app_code_vw
        WHERE  codeset_nm = i_codeset_nm
        ORDER BY display_order;
   ELSE
      OPEN l_rc FOR
        SELECT code_val, code_id
        FROM   app_code_vw
        WHERE  codeset_nm = i_codeset_nm
        ORDER BY display_order;
   END IF;
      
   RETURN l_rc;
     
END get_codeset_cur;

END codes;
/
