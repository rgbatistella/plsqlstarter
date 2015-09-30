CREATE OR REPLACE PACKAGE BODY locks
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
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'locks';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
Inserts record of lock info into APP_LOCK table.
------------------------------------------------------------------------------*/
PROCEDURE ins(ir_app_lock IN app_lock%ROWTYPE) IS
   lr_lock   app_lock%ROWTYPE;
BEGIN
   -- place incoming record in temp area for validation
   lr_lock := ir_app_lock;
   
   -- ensure critical fields are filled
   IF (lr_lock.app_id IS NULL) THEN
      lr_lock.app_id := env.get_app_id;
   END IF;
   IF (lr_lock.lock_id IS NULL) THEN
      SELECT app_lock_seq.NEXTVAL INTO lr_lock.lock_id FROM dual;
   END IF;
   IF (lr_lock.locker_id is NULL) THEN
      lr_lock.locker_id := env.get_client_id;
   END IF;
   IF (lr_lock.locker_ip IS NULL) THEN
      lr_lock.locker_ip := env.get_client_ip;
   END IF;
   IF (lr_lock.locked_dtm IS NULL) THEN
      lr_lock.locked_dtm := dt.get_sysdtm;
   END IF;
   
   -- This syntax only works on 9iR2 and above.
   INSERT INTO app_lock
   VALUES lr_lock;
   
END ins;



--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_lock
(
   i_lock_nm   IN app_lock.lock_nm%TYPE,
   i_locker_id IN app_lock.locker_id%TYPE DEFAULT NULL
) RETURN INTEGER
IS
   lr_lock   app_lock%ROWTYPE;
   l_rc    typ.t_rc;
BEGIN

   lr_lock := read_lock(i_lock_nm);
   
   IF (lr_lock.lock_id IS NULL) THEN
   
      lr_lock.lock_nm := i_lock_nm;
      
      ins(lr_lock);
      
      l_rc := LOCK_GRANTED;
      
   ELSE -- existing lock on record found
      IF (lr_lock.locker_id = i_locker_id) THEN
         -- lock requester and holder are the same, so return success
         l_rc := LOCK_GRANTED;
      ELSE
         excp.throw(msgs.get_msg_id('Logical Lock Held'),
                    'Lock on '||i_lock_nm||' already held by '||lr_lock.locker_id||
                    ' within the '||lr_lock.app_id||' application. Try again later.');
         l_rc := LOCK_DENIED;
      END IF;
   END IF;
   
   RETURN l_rc;
   
END get_lock;

--------------------------------------------------------------------------------
FUNCTION get_lock
(
   i_lock_nm   IN app_lock.lock_nm%TYPE,
   i_obj_id    IN app_lock.locked_obj_id%TYPE,
   i_locker_id IN app_lock.locker_id%TYPE DEFAULT NULL
) RETURN INTEGER
IS
   lr_lock   app_lock%ROWTYPE;
   l_rc    typ.t_rc;
BEGIN

   lr_lock := read_lock(i_lock_nm, i_obj_id);
   
   IF (lr_lock.lock_id IS NULL) THEN
   
      lr_lock.lock_nm := i_lock_nm;
      lr_lock.locked_obj_id := i_obj_id;
      
      ins(lr_lock);
      
      l_rc := LOCK_GRANTED;
      
   ELSE -- existing lock on record found
      IF (lr_lock.locker_id = i_locker_id) THEN
         -- lock requester and holder are the same, so return success
         l_rc := LOCK_GRANTED;
      ELSE
         excp.throw(msgs.get_msg_id('Logical Lock Held'),
                    'Lock on '||i_lock_nm||'.'||i_obj_id||' already held by '||lr_lock.locker_id||
                    ' within the '||lr_lock.app_id||' application. Try again later.');
         l_rc := LOCK_DENIED;
      END IF;
   END IF;
   
   RETURN l_rc;
   
END get_lock;

--------------------------------------------------------------------------------
FUNCTION get_lock
(
   i_lock_nm   IN app_lock.lock_nm%TYPE,
   i_obj_rid   IN app_lock.locked_obj_rid%TYPE,
   i_locker_id IN app_lock.locker_id%TYPE DEFAULT NULL
) RETURN INTEGER
IS
   lr_lock   app_lock%ROWTYPE;
   l_rc    typ.t_rc;
BEGIN

   lr_lock := read_lock(i_lock_nm, i_obj_rid);
   
   IF (lr_lock.lock_id IS NULL) THEN
   
      lr_lock.lock_nm := i_lock_nm;
      lr_lock.locked_obj_rid := i_obj_rid;
      
      ins(lr_lock);
      
      l_rc := LOCK_GRANTED;
      
   ELSE -- existing lock on record found
      IF (lr_lock.locker_id = i_locker_id) THEN
         -- lock requester and holder are the same, so return success
         l_rc := LOCK_GRANTED;
      ELSE
         excp.throw(msgs.get_msg_id('Logical Lock Held'),
                    'Lock on '||i_lock_nm||'.'||i_obj_rid||' already held by '||lr_lock.locker_id||
                    ' within the '||lr_lock.app_id||' application. Try again later.');
         l_rc := LOCK_DENIED;
      END IF;
   END IF;
   
   RETURN l_rc;
   
END get_lock;



--------------------------------------------------------------------------------
PROCEDURE del_lock (
   i_lock_nm IN app_lock.lock_nm%TYPE
)
IS
   l_lock_id app_lock.lock_id%TYPE;
BEGIN
   
   -- Convert given values into the surrogate key used as PK for APP_LOCK   
   SELECT lock_id
     INTO l_lock_id
     FROM app_lock
    WHERE lock_nm = i_lock_nm
      FOR UPDATE NOWAIT;

   -- Attempt to delete
   DELETE FROM app_lock
    WHERE lock_id = l_lock_id;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL; -- it's OK if the lock isn't there anymore, but would be nice to know why
   WHEN TOO_MANY_ROWS THEN
      excp.throw(SQLCODE,'More than one '||i_lock_nm||' lock found. Cannot release any without further detail.');
   WHEN excp.gx_row_locked THEN
      excp.throw(msgs.get_msg_id('Row Lock Held'),
                 'Unable to remove lock '||i_lock_nm||' as it is already held FOR UPDATE NOWAIT by another process. Try again later.');
END del_lock;

--------------------------------------------------------------------------------
PROCEDURE del_lock (
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_id  IN app_lock.locked_obj_id%TYPE
)
IS
   l_lock_id app_lock.lock_id%TYPE;
BEGIN
   
   -- Convert given values into the surrogate key used as PK for APP_LOCK   
   SELECT lock_id
     INTO l_lock_id
     FROM app_lock
    WHERE lock_nm = i_lock_nm
      AND locked_obj_id = i_obj_id
      FOR UPDATE NOWAIT;

   -- Attempt to delete
   DELETE FROM app_lock
    WHERE lock_id = l_lock_id;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL; -- it's OK if the lock isn't there anymore, but would be nice to know why
   WHEN excp.gx_row_locked THEN
      excp.throw(msgs.get_msg_id('Row Lock Held'),
                 'Unable to remove lock '||i_lock_nm||'.'||i_obj_id||' as it is already held FOR UPDATE NOWAIT by another process. Try again later.');
END del_lock;

--------------------------------------------------------------------------------
PROCEDURE del_lock (
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_rid IN app_lock.locked_obj_rid%TYPE
)IS
   l_lock_id app_lock.lock_id%TYPE;
BEGIN
   
   -- Convert given values into the surrogate key used as PK for APP_LOCK   
   SELECT lock_id
     INTO l_lock_id
     FROM app_lock
    WHERE lock_nm = i_lock_nm
      AND locked_obj_rid = i_obj_rid
      FOR UPDATE NOWAIT;

   -- Attempt to delete
   DELETE FROM app_lock
    WHERE lock_id = l_lock_id;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL; -- it's OK if the lock isn't there anymore, but would be nice to know why
   WHEN excp.gx_row_locked THEN
      excp.throw(msgs.get_msg_id('Row Lock Held'),
                 'Unable to remove lock '||i_lock_nm||'.'||i_obj_rid||' as it is already held FOR UPDATE NOWAIT by another process. Try again later.');
END del_lock;


--------------------------------------------------------------------------------
FUNCTION read_lock
(
   i_lock_nm IN app_lock.lock_nm%TYPE
) RETURN app_lock%ROWTYPE
IS
   lr_lock app_lock%ROWTYPE;
BEGIN
   SELECT *
     INTO lr_lock
     FROM app_lock
    WHERE lock_nm = i_lock_nm
      AND locked_obj_id IS NULL
      AND locked_obj_rid IS NULL;

   RETURN lr_lock; 
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL; -- will be empty if lock wasn't found
   -- Let error bubble up if more than one match was found. This is possible
   -- with large-grained locks. But the error should point out where the large-
   -- grained lock is being used incorrectly.
END read_lock;

--------------------------------------------------------------------------------
FUNCTION read_lock
(
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_id  IN app_lock.locked_obj_id%TYPE
) RETURN app_lock%ROWTYPE
IS
   lr_lock app_lock%ROWTYPE;
BEGIN
   SELECT *
     INTO lr_lock
     FROM app_lock
    WHERE lock_nm = i_lock_nm
      AND locked_obj_id = i_obj_id;

   RETURN lr_lock; 
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL; -- will be empty if lock wasn't found
   -- Let error bubble up if more than one match was found. This should not be
   -- possible when dealing with fine-grained locks.
END read_lock;

--------------------------------------------------------------------------------
FUNCTION read_lock
(
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_rid IN app_lock.locked_obj_rid%TYPE
) RETURN app_lock%ROWTYPE
IS
   lr_lock app_lock%ROWTYPE;
BEGIN
   SELECT *
     INTO lr_lock
     FROM app_lock
    WHERE lock_nm = i_lock_nm
      AND locked_obj_rid = i_obj_rid;

   RETURN lr_lock; 
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL; -- will be empty if lock wasn't found
   -- Let error bubble up if more than one match was found. This should not be
   -- possible when dealing with fine-grained locks.
END read_lock;



END locks;
/
