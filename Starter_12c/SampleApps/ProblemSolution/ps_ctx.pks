CREATE OR REPLACE PACKAGE ps_ctx
AS
/*******************************************************************************
ps_ctx 
 Routines for use with Oracle Text.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar20 Initial Creation
</pre>

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


--------------------------------------------------------------------------------
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------
/**-----------------------------------------------------------------------------
concat_columns:
 Used by Oracle Text. Concatenates the contents of text columns across tables 
 into a single string that Oracle Text can index.
 
 Caveats: Not meant to be called by anything other than Oracle Text.
------------------------------------------------------------------------------*/
PROCEDURE concat_columns
(
   i_rowid IN ROWID,
   io_text IN OUT NOCOPY VARCHAR2
);

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------


END ps_ctx;
/
