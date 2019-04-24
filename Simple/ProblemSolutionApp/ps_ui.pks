CREATE OR REPLACE PACKAGE ps_ui
AS
/*******************************************************************************
ps_ui
 Collection of routines that present the public web interface for the Problem-
 Solution application.

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
-- record used for web page drop-down lists
TYPE tr_select_option IS RECORD
(
   label   VARCHAR2(100),
   value   VARCHAR2(100)
);

TYPE tar_select_vals IS TABLE OF tr_select_option INDEX BY BINARY_INTEGER;

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
main:
 Multi-purpose page that changes its output based on the parameters passed to it,
 in particular the Submit button's value, making this routine a controller of
 sorts.
------------------------------------------------------------------------------*/
PROCEDURE main
(
   i_msg          IN VARCHAR2 DEFAULT NULL,
   i_prob_id      IN VARCHAR2 DEFAULT NULL,
   i_prob_key     IN VARCHAR2 DEFAULT NULL,
   i_prob_src_id  IN VARCHAR2 DEFAULT NULL,
   i_prob_key_txt IN VARCHAR2 DEFAULT NULL,
   i_prob_notes   IN VARCHAR2 DEFAULT NULL,
   i_sol_notes    IN VARCHAR2 DEFAULT NULL,
   i_submit       IN VARCHAR2 DEFAULT NULL
);

/**-----------------------------------------------------------------------------
search:
 Searches the Oracle Text multi-table, multi-column index to find any entries
 where the error ID, error name/text, or notes, context or resolution contain
 all or part of the search term. Then produces a web page based on the results.
------------------------------------------------------------------------------*/
PROCEDURE search(i_search_str IN VARCHAR2);


END ps_ui;
/
