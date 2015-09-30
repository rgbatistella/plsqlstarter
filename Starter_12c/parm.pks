CREATE OR REPLACE PACKAGE parm
  AUTHID CURRENT_USER
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Contains simple functions that retrieve the values for named application-specific
 parameters.

%design
 The parameters are derived from the APP_PARM_VW view, which will not work 
 unless the values in APP_ENV, APP_ENV_PARM and APP_DB are set up properly.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Jan13 Creation

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

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_val:
 Given a unique key/parameter name (the app_id is determined transparently), this
 returns the  key's string value. The value returned could be either a number, 
 date or string, but it will always be returned as a string. The caller must be 
 aware of what type it expects to get back and perform any necessary explicit 
 conversions.

%note
 If the desired value is a date string, then the caller must also be aware of
 the format to use to convert it. This sounds hard, but isn't. Just look at
 the value in the APP_ENV_PARM table!
-----------------------------------------------------------------------*/
FUNCTION get_val
(
   i_parm_nm IN app_parm.parm_nm%TYPE
)  RETURN app_env_parm.parm_val%TYPE;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------


END parm;
/
