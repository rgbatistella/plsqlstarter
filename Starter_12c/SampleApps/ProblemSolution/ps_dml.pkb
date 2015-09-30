CREATE OR REPLACE PACKAGE BODY ps_dml
AS
/*******************************************************************************
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
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------
FUNCTION get_prob_sol(i_prob_id IN ps_prob.prob_id%TYPE) RETURN gcur_ps%ROWTYPE
IS
   l_ps_data gcur_ps%ROWTYPE;
BEGIN
   logs.dbg('Retrieving data for problem ['||i_prob_id||']');
   SELECT p.prob_id,
          p.prob_key,
          p.prob_key_txt,
          p.prob_notes,
          p.prob_src_id,
          s.sol_id,
          s.sol_notes
     INTO l_ps_data
     FROM ps_prob p,
          ps_sol  s
    WHERE p.prob_id = i_prob_id
      AND p.prob_id = s.prob_id;

   RETURN l_ps_data;

END get_prob_sol;

--------------------------------------------------------------------------------
PROCEDURE ins_prob
(
   io_prob_id     IN OUT ps_prob.prob_id%TYPE,
   i_prob_key     IN ps_prob.prob_key%TYPE,
   i_prob_key_txt IN ps_prob.prob_key_txt%TYPE DEFAULT NULL,
   i_prob_notes   IN ps_prob.prob_notes%TYPE DEFAULT NULL,
   i_prob_src_id  IN ps_prob.prob_src_id%TYPE DEFAULT NULL
)
IS
   lr_prob ps_prob%ROWTYPE;
BEGIN
   IF (io_prob_id IS NULL) THEN
      io_prob_id := ps_prob_seq.NEXTVAL;
   END IF;
   lr_prob.prob_id := io_prob_id;
   lr_prob.otx_sync_col := 'Y';
   lr_prob.prob_key := i_prob_key;
   lr_prob.prob_key_txt := i_prob_key_txt;
   lr_prob.prob_notes := i_prob_notes;
   lr_prob.prob_src_id := i_prob_src_id;
   
   logs.dbg('Inserting problem ['||io_prob_id||'] with '||CHR(10)||
      'i_prob_key ['||i_prob_key||'] '||CHR(10)||
      'i_prob_key_txt ['||i_prob_key_txt||'] '||CHR(10)||
      'i_prob_notes ['||i_prob_notes||'] '||CHR(10)||
      'i_prob_src_id ['||i_prob_src_id||']'
   );
   INSERT INTO ps_prob VALUES lr_prob;
END ins_prob;

--------------------------------------------------------------------------------
PROCEDURE ins_sol
(
   i_prob_id   IN ps_sol.prob_id%TYPE,
   i_sol_notes IN ps_sol.sol_notes%TYPE
)
IS
   lr_sol ps_sol%ROWTYPE;
BEGIN
   lr_sol.sol_id := ps_sol_seq.NEXTVAL;
   lr_sol.prob_id := i_prob_id;
   lr_sol.sol_notes := i_sol_notes;

   logs.dbg('Insert new solution ['||lr_sol.sol_id||'] for problem ['||
      i_prob_id||']');
   INSERT INTO ps_sol VALUES lr_sol;
END ins_sol;

--------------------------------------------------------------------------------
PROCEDURE upd_prob
(
   i_prob_id      IN ps_prob.prob_id%TYPE,
   i_prob_key     IN ps_prob.prob_key%TYPE,
   i_prob_key_txt IN ps_prob.prob_key_txt%TYPE DEFAULT NULL,
   i_prob_notes   IN ps_prob.prob_notes%TYPE DEFAULT NULL,
   i_prob_src_id  IN ps_prob.prob_src_id%TYPE DEFAULT NULL
)
IS
BEGIN
   logs.dbg('Updating problem ['||i_prob_id||'] with '||CHR(10)||
      'i_prob_key ['||i_prob_key||'] '||CHR(10)||
      'i_prob_key_txt ['||i_prob_key_txt||'] '||CHR(10)||
      'i_prob_notes ['||i_prob_notes||'] '||CHR(10)||
      'i_prob_src_id ['||i_prob_src_id||']'
   );
  UPDATE ps_prob
     SET prob_key     = NVL(i_prob_key, prob_key),
         prob_key_txt = NVL(i_prob_key_txt, prob_key_txt),
         prob_notes   = NVL(i_prob_notes, prob_notes),
         prob_src_id  = i_prob_src_id
   WHERE prob_id = i_prob_id;
END upd_prob;

--------------------------------------------------------------------------------
PROCEDURE upd_sol
(
   i_sol_id    IN ps_sol.sol_id%TYPE,
   i_prob_id   IN ps_sol.prob_id%TYPE,
   i_sol_notes IN ps_sol.sol_notes%TYPE
)
IS
BEGIN
   logs.dbg('Updating solution ['||i_sol_id||']');
   UPDATE ps_sol
      SET prob_id   = NVL(i_prob_id, prob_id),
          sol_notes = NVL(i_sol_notes, sol_notes)
    WHERE sol_id = i_sol_id;
END upd_sol;

--------------------------------------------------------------------------------
PROCEDURE del_prob(i_prob_id IN ps_prob.prob_id%TYPE)
IS
   l_rows_deleted INTEGER := 0;
BEGIN
   logs.dbg('Deleting solutions for problem ['||i_prob_id||']');
   DELETE FROM ps_sol WHERE prob_id = i_prob_id;
   -- Not checking results of deleting from ps_sol, since it is possible to have
   -- problems with no solutions.
   
   logs.dbg('Deleting problem ['||i_prob_id||']');
   DELETE FROM ps_prob WHERE prob_id = i_prob_id;
   l_rows_deleted := SQL%ROWCOUNT;
   excp.assert(l_rows_deleted > 0,'Could not delete. Problem ID '||i_prob_id||' not found.',FALSE);
END del_prob;

--------------------------------------------------------------------------------
PROCEDURE del_sol(i_sol_id IN ps_sol.sol_id%TYPE)
IS
   l_rows_deleted INTEGER := 0;
BEGIN
   logs.dbg('Deleting solution ['||i_sol_id||']');
   excp.assert(i_sol_id IS NOT NULL, 'Cannot delete a solution without a solution ID');
   DELETE FROM ps_sol WHERE sol_id = i_sol_id;
   l_rows_deleted := SQL%ROWCOUNT;
   excp.assert(l_rows_deleted > 0, 'No rows were deleted.',FALSE);
END del_sol;

END ps_dml;
/
