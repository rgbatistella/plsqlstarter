CREATE OR REPLACE PACKAGE BODY parm
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

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
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------
--gc_pkg_nm CONSTANT user_source.name%TYPE := 'parm';

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
FUNCTION get_val(i_parm_nm IN app_parm.parm_nm%TYPE)
   RETURN app_env_parm.parm_val%TYPE
IS
   l_val app_env_parm.parm_val%TYPE;
BEGIN
   SELECT parm_value
     INTO l_val
     FROM app_parm_vw
    WHERE parm_nm = TRIM(i_parm_nm);

   RETURN l_val;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- Ensure the call to parms.get_parm_val actually pulled back a value 
      RAISE_APPLICATION_ERROR(-20000,
         'Parameter "'||i_parm_nm||'" is not found in APP_PARM_VW.'||CHR(10)||
         'APP_PARM_VW depends on APP_ENV_VW, which requires a valid map in APP_ENV between '||
         'client account ['||env.get_current_schema||
         '] on database ['||env.get_db_name||']'||
         ' for application ['||env.get_app_cd(env.get_app_id)||']'); 
END get_val;

END parm;
/
