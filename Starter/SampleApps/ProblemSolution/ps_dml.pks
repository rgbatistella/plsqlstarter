CREATE OR REPLACE PACKAGE ps_dml
AS
/*******************************************************************************
ps_dml 
 Collection of routines to manage the modification of data in the Problem/Solution
 database tables.

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
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

-- Basic cursor used to populate search screen and view/edit screen. Uses the
-- Oracle Text custom index to search all the string fields with a single
-- query. There is much more to the "contains" grammar than this; it is much
-- richer. But this use is sufficient for this app.
CURSOR gcur_ps(i_search_str IN VARCHAR2) IS
SELECT p.prob_id,
       p.prob_key,
       p.prob_key_txt,
       p.prob_notes,
       p.prob_src_id,
       s.sol_id,
       s.sol_notes
  FROM ps_prob p,
       ps_sol  s
 WHERE p.prob_id = s.prob_id
   AND CONTAINS(otx_sync_col, REPLACE(REPLACE(i_search_str,'_','\_'),'-','\-')) > 0;

-- Cursor used by sample report   
CURSOR cur_read_ps_db IS
   SELECT prob_src_nm
         ,prob_key
         ,prob_key_txt
         ,prob_notes
         ,sol_notes
         ,seq
     FROM (SELECT ps.prob_src_id
                 ,ps.prob_src_nm
                 ,p.prob_key
                 ,p.prob_key_txt
                 ,p.prob_notes
                 ,ROW_NUMBER() OVER(PARTITION BY s.prob_id ORDER BY s.sol_id) AS seq
                 ,s.sol_notes
             FROM ps_prob p
             JOIN ps_prob_src ps
               ON ps.prob_src_id = p.prob_src_id
             JOIN ps_sol s
               ON s.prob_id = p.prob_id)
    ORDER BY prob_src_id
            ,prob_key
            ,seq;   

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------
FUNCTION get_prob_sol(i_prob_id IN ps_prob.prob_id%TYPE) RETURN gcur_ps%ROWTYPE;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------
PROCEDURE ins_prob
(
   io_prob_id     IN OUT ps_prob.prob_id%TYPE,
   i_prob_key     IN ps_prob.prob_key%TYPE,
   i_prob_key_txt IN ps_prob.prob_key_txt%TYPE DEFAULT NULL,
   i_prob_notes   IN ps_prob.prob_notes%TYPE DEFAULT NULL,
   i_prob_src_id  IN ps_prob.prob_src_id%TYPE DEFAULT NULL
);
PROCEDURE ins_sol
(
   i_prob_id   IN ps_sol.prob_id%TYPE,
   i_sol_notes IN ps_sol.sol_notes%TYPE
);
PROCEDURE upd_prob
(
   i_prob_id      IN ps_prob.prob_id%TYPE,
   i_prob_key     IN ps_prob.prob_key%TYPE,
   i_prob_key_txt IN ps_prob.prob_key_txt%TYPE DEFAULT NULL,
   i_prob_notes   IN ps_prob.prob_notes%TYPE DEFAULT NULL,
   i_prob_src_id  IN ps_prob.prob_src_id%TYPE DEFAULT NULL
);
PROCEDURE upd_sol
(
   i_sol_id    IN ps_sol.sol_id%TYPE,
   i_prob_id   IN ps_sol.prob_id%TYPE,
   i_sol_notes IN ps_sol.sol_notes%TYPE
);
PROCEDURE del_prob(i_prob_id IN ps_prob.prob_id%TYPE);
PROCEDURE del_sol(i_sol_id IN ps_sol.sol_id%TYPE);

END ps_dml;
/
