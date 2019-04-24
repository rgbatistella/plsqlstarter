CREATE OR REPLACE PACKAGE locks
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 DML controller for pessimistic locks held in the object-locking table.

%design
 Built-in locking capabilities in Oracle are probably a better choice. So this
 package is not compiled by the Core library compiler by default. Consider all
 the details of custom locking before using this package.

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
LOCK_GRANTED   CONSTANT PLS_INTEGER := cnst.TRUE;
LOCK_DENIED   CONSTANT PLS_INTEGER := cnst.FALSE;

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_lock:
Takes a lock request for a given object and optionally its unique ID (usually a 
table name and PK) and sees if a logical lock exists already. If it does, it 
returns LOCK_DENIED to the caller. Otherwise, if no lock is found, it goes ahead
and creates a new row in APP_LOCK and returns LOCK_GRANTED.

The caller must decide what to do with the return code. A recommended approach
if the lock is denied is to call read_lock. The caller can then use the info to 
let the lock requestor know who currently owns the existing lock, what machine 
they're on, how long it's been since the lock was obtained, etc.

The first version is for large-grained, name-only locks. The second version is 
for fine-grained locks on single PK-identified rows or single identifier items 
within a lock namespace. The third version is for fine-grained locks on rows in 
tables with multi-column PKs or rows from IOT tables.

%param i_lock_nm  Fixed name upon which parties involved in lock coordination 
                  have agreed. This could be the name of the screen, process,
                  module, or simply the name of a table. This, combined with the
                  ID or RID, provides the unique key to any given lock.
 
%param i_obj_id  Real PK or temporary unique ID for the row, process, item, etc.
 
%param i_obj_rid ROWID or UROWID for the row being serially locked.
 
%param i_locker_id Usually the user id or name which was used to 
                   authenticate to the application which uses this framework. 
                   The implication is that either the calling layer, or this 
                   PL/SQL layer must be able to obtain the login credentials.
                    
------------------------------------------------------------------------------*/
FUNCTION get_lock
(
   i_lock_nm   IN app_lock.lock_nm%TYPE,
   i_locker_id IN app_lock.locker_id%TYPE DEFAULT NULL
) RETURN INTEGER;

FUNCTION get_lock
(
   i_lock_nm   IN app_lock.lock_nm%TYPE,
   i_obj_id    IN app_lock.locked_obj_id%TYPE,
   i_locker_id IN app_lock.locker_id%TYPE DEFAULT NULL
) RETURN INTEGER;

FUNCTION get_lock
(
   i_lock_nm   IN app_lock.lock_nm%TYPE,
   i_obj_rid   IN app_lock.locked_obj_rid%TYPE,
   i_locker_id IN app_lock.locker_id%TYPE DEFAULT NULL
) RETURN INTEGER;

/**-----------------------------------------------------------------------------
read_lock:
 The following three routines return all known information about a lock. The 
 returned record will be empty if the lock wasn't found. The first version is for
 large-grained, name-only locks. The second version is for fine-grained locks on 
 single PK-identified rows or single identifier items within a lock namespace.
 The third version is for fine-grained locks on rows in tables with multi-column
 PKs or rows from IOT tables.

%param i_lock_nm  Fixed name upon which parties involved in lock coordination 
                  have agreed. This could be the name of the screen, process,
                  module, or simply the name of a table. This, combined with the
                  ID or RID, provides the unique key to any given lock.
 
%param i_obj_id  Real PK or temporary unique ID for the row, process, item, etc.
 
%param i_obj_rid ROWID or UROWID for the locked item.
------------------------------------------------------------------------------*/
FUNCTION read_lock
(
   i_lock_nm IN app_lock.lock_nm%TYPE
) RETURN app_lock%ROWTYPE;

FUNCTION read_lock
(
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_id  IN app_lock.locked_obj_id%TYPE
) RETURN app_lock%ROWTYPE;

FUNCTION read_lock
(
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_rid IN app_lock.locked_obj_rid%TYPE
) RETURN app_lock%ROWTYPE;


--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
del_lock:
 Removes logical lock for given lock name and optional fine-grained ID. Again, 
 like read_lock, there are three versions for the different ways of identifying
 a unique, held lock: large-grained object name; object name + (PK or item ID);
 object_name + UROWID.

%param i_lock_nm  Fixed name upon which parties involved in lock coordination 
                  have agreed. This could be the name of the screen, process,
                  module, or simply the name of a table. This, combined with the
                  ID or RID, provides the unique key to any given lock.
 
%param i_obj_id  Real PK or temporary unique ID for the row, process, item, etc.
 
%param i_obj_rid ROWID or UROWID for the locked item.
------------------------------------------------------------------------------*/
PROCEDURE del_lock (
   i_lock_nm IN app_lock.lock_nm%TYPE
);
PROCEDURE del_lock (
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_id  IN app_lock.locked_obj_id%TYPE
);
PROCEDURE del_lock (
   i_lock_nm IN app_lock.lock_nm%TYPE,
   i_obj_rid IN app_lock.locked_obj_rid%TYPE
);

END locks;
/
