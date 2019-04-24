CREATE OR REPLACE PACKAGE BODY msgs
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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'msgs';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_msg(i_msg_cd IN app_msg.msg_cd%TYPE) RETURN VARCHAR2 IS
   l_message app_msg.msg%TYPE;
BEGIN

   SELECT msg
     INTO l_message
     FROM app_msg
    WHERE msg_cd = i_msg_cd;

   RETURN l_message;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- Could have recursively called get_msg(MISSING_MSG_CD) here,
      -- however, previous problems with this method due to missing data was
      -- an infinite loop that took a day to debug.
      RETURN('Unable to retrieve message text for message code: ' || i_msg_cd);
   
END get_msg;

--------------------------------------------------------------------------------
FUNCTION get_msg(i_msg_id IN app_msg.msg_id%TYPE) RETURN VARCHAR2 IS
   l_message app_msg.msg%TYPE;
BEGIN

   SELECT msg
     INTO l_message
     FROM app_msg
    WHERE msg_id = i_msg_id;

   RETURN l_message;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- Could have recursively called get_msg(MISSING_MSG_CD) here,
      -- however, previous problems with this method due to missing data was
      -- an infinite loop that took a day to debug.
      RETURN('Unable to retrieve message text for message number: ' || i_msg_id);
   
END get_msg;

--------------------------------------------------------------------------------
FUNCTION get_msg_id(i_msg_cd IN app_msg.msg_cd%TYPE) RETURN NUMBER IS
   l_message_id app_msg.msg_id%TYPE;
BEGIN

   SELECT msg_id
     INTO l_message_id
     FROM app_msg
    WHERE msg_cd = i_msg_cd;

   RETURN l_message_id;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- This can cause an infinite loop if the Ad-Hoc Msg row is not
      -- populated in APP_MSG.
      RETURN get_msg_id(DEFAULT_MSG_CD);
   
END get_msg_id;

--------------------------------------------------------------------------------
FUNCTION get_msg_cd(i_msg_id IN app_msg.msg_id%TYPE) RETURN VARCHAR2 IS
   l_message_cd app_msg.msg_cd%TYPE;
BEGIN

   SELECT msg_cd
     INTO l_message_cd
     FROM app_msg
    WHERE msg_id = i_msg_id;

   RETURN l_message_cd;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN MISSING_MSG_CD;
   
END get_msg_cd;

--------------------------------------------------------------------------------
FUNCTION fill_msg
(
   i_msg_cd    IN app_msg.msg_cd%TYPE,
   ias_fill    IN typ.tas_medium,
   i_wrap_char IN VARCHAR2 DEFAULT cnst.subchar
) RETURN VARCHAR2 IS
   l_msg app_msg.msg%TYPE;
BEGIN

   BEGIN
      SELECT msg
        INTO l_msg
        FROM app_msg
       WHERE msg_cd = i_msg_cd;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_msg := 'Unable to retrieve message text for message code: ' || i_msg_cd;
   END;
   
   IF (l_msg IS NOT NULL AND ias_fill.COUNT > 0) THEN
      FOR i IN ias_fill.FIRST .. ias_fill.LAST LOOP
         -- Given the index "i" find the related placeholder in the message and
         -- replace the placeholder with the array's value at index "i".
         l_msg := REPLACE(l_msg,
                          i_wrap_char || TO_CHAR(i) || i_wrap_char,
                          ias_fill(i));
      END LOOP;
   END IF;

   RETURN l_msg;

END fill_msg;

--------------------------------------------------------------------------------
FUNCTION fill_msg
(
   i_msg_id    IN app_msg.msg_id%TYPE,
   ias_fill    IN typ.tas_medium,
   i_wrap_char IN VARCHAR2 DEFAULT cnst.subchar
) RETURN VARCHAR2 IS
BEGIN
   RETURN fill_msg(get_msg_cd(i_msg_id), ias_fill, i_wrap_char);
END fill_msg;

--------------------------------------------------------------------------------
FUNCTION fill_msg
(
   i_msg_cd    IN app_msg.msg_cd%TYPE,
   i_field1    IN VARCHAR2 DEFAULT NULL,
   i_field2    IN VARCHAR2 DEFAULT NULL,
   i_field3    IN VARCHAR2 DEFAULT NULL,
   i_field4    IN VARCHAR2 DEFAULT NULL,
   i_field5    IN VARCHAR2 DEFAULT NULL,
   i_wrap_char IN VARCHAR2 DEFAULT cnst.subchar
) RETURN VARCHAR2 IS
   las_context typ.tas_medium;
BEGIN
   IF (i_field1 IS NOT NULL) THEN
      las_context(1) := i_field1;
   END IF;
   IF (i_field2 IS NOT NULL) THEN
      las_context(2) := i_field2;
   END IF;
   IF (i_field3 IS NOT NULL) THEN
      las_context(3) := i_field3;
   END IF;
   IF (i_field4 IS NOT NULL) THEN
      las_context(4) := i_field4;
   END IF;
   IF (i_field5 IS NOT NULL) THEN
      las_context(5) := i_field5;
   END IF;

   RETURN fill_msg(i_msg_cd, las_context, NVL(i_wrap_char, cnst.subchar));

END fill_msg;
   
END msgs;
/
