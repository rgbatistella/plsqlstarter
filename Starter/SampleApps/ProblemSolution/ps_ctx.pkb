CREATE OR REPLACE PACKAGE BODY ps_ctx
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

--------------------------------------------------------------------------------
PROCEDURE concat_columns
(
   i_rowid IN ROWID,
   io_text IN OUT NOCOPY VARCHAR2
) AS

   lr_prob ps_prob%ROWTYPE;

   CURSOR cur_sol(i_prob_id IN ps_prob.prob_id%TYPE) IS
      SELECT sol_notes
        FROM ps_sol
       WHERE prob_id = i_prob_id;

   PROCEDURE add_piece(i_add_str IN VARCHAR2) IS
      lx_too_big EXCEPTION;
      PRAGMA EXCEPTION_INIT(lx_too_big, -6502);
   BEGIN
      io_text := io_text || ' ' || i_add_str;
   EXCEPTION
      WHEN lx_too_big THEN
         NULL; -- silently don't add the string. Should add error logging here
   END add_piece;

BEGIN
   -- Get PK of incident
   BEGIN
      SELECT *
        INTO lr_prob
        FROM ps_prob
       WHERE ROWID = i_rowid;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN;
   END;

   -- Add text to the CLOB
   add_piece('<PROB_KEY>' || lr_prob.prob_key || '</PROB_KEY>');
   add_piece('<PROB_KEY_TXT>' || lr_prob.prob_key_txt || '</PROB_KEY_TXT>');
   add_piece('<PROB_NOTES>' || lr_prob.prob_notes || '</PROB_NOTES>');

   -- Now collect the text fields from solutions
   FOR lrp IN cur_sol(lr_prob.prob_id) LOOP
      add_piece('<SOL_NOTES>' || lrp.sol_notes || '</SOL_NOTES>');
   END LOOP;

END concat_columns;

END ps_ctx;
/
