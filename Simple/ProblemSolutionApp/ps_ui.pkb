CREATE OR REPLACE PACKAGE BODY ps_ui
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
gc_lbl_add    CONSTANT VARCHAR2(20) := 'Add';
gc_lbl_view   CONSTANT VARCHAR2(20) := 'View';
gc_lbl_edit   CONSTANT VARCHAR2(20) := 'Edit';
gc_lbl_update CONSTANT VARCHAR2(20) := 'Update';
gc_lbl_return CONSTANT VARCHAR2(20) := 'Return Home';
gc_lbl_cancel CONSTANT VARCHAR2(20) := 'Cancel';
gc_lbl_search CONSTANT VARCHAR2(20) := 'Search';
gc_lbl_delete CONSTANT VARCHAR2(20) := 'Delete';


--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_page_style:
 Returns CSS style template for this basic website.
------------------------------------------------------------------------------*/
FUNCTION get_page_style RETURN VARCHAR2 IS
BEGIN
   RETURN 
   '<style>
    body {
	 padding: 0em;
	 margin: 0em;
	 color: rgb(35,75,60);
	 background: rgb(250,250,200);
	 font-family: Tahoma,Arial,Verdana,sans-serif;
	 font-size: large;
   }

   H1 { font-weight: bold; color: black; }
   H2,H3 { font-weight: bold; color: maroon; }
   H1,H2 { font-variant: small-caps; }
   H2,H3,H4,H5 { margin-top: .5em; margin-bottom: .5em; }
   H1 { font-size: 150% }
   H2 { font-size: 130% }
   H3 { font-size: 100% }
   H4 { font-size: 90% }
   P { margin-top: 1em; margin-bottom: 0; }
   </style>';
END get_page_style;


/**-----------------------------------------------------------------------------
header:
 Encapsulates standard HTML page HEAD elements used by pages in this site.
------------------------------------------------------------------------------*/
PROCEDURE header(i_title IN VARCHAR2 DEFAULT NULL)
IS
BEGIN
   htp.htmlOpen;
   htp.headOpen;
   htp.title(ctitle => i_title);
   htp.p(ps_ui.get_page_style);
   htp.headClose;
   htp.bodyOpen;
END header;

/**-----------------------------------------------------------------------------
table_3col:
------------------------------------------------------------------------------*/
PROCEDURE table_3col
(
   i_summary    IN VARCHAR2,
   i_col1_width IN INTEGER DEFAULT 10,
   i_col2_width IN INTEGER DEFAULT 60,
   i_col3_width IN INTEGER DEFAULT 30,
   i_border     IN INTEGER DEFAULT 0
) IS
BEGIN
   htp.p('<table summary="'|| i_summary ||'" border="'|| i_border ||'">');
   htp.p('<col id="left" width="'|| i_col1_width ||'%" align="left" />');
   htp.p('<col id="content" width="'|| i_col2_width ||'%" align="left" />');
   htp.p('<col id="right" width="'|| i_col3_width ||'%" align="left" />');
END table_3col;

/**-----------------------------------------------------------------------------
footer:
 Encapsulates standard elements that close HTML pages in this site.
------------------------------------------------------------------------------*/
PROCEDURE footer
IS
BEGIN
   htp.bodyClose;
   htp.htmlClose;
END footer;

--/**-----------------------------------------------------------------------------
--fm_btn:
-- Encapsulates the creation of a an HTML FORM button.
--
--%param is_name Name of the form button control.
--%param is_btntxt Text to appear on the face of the button.
--%param is_jscode Javascript code to add to the button's onClick event.
--%param ib_own_form Whether to wrap the button in it's own FORM, isolating it
--                   from the effects of the other forms and buttons on the page.
--------------------------------------------------------------------------------*/
--PROCEDURE fm_btn
--(
--   i_name IN VARCHAR2,
--   i_btntxt IN VARCHAR2 DEFAULT NULL,
--   i_action IN VARCHAR2 DEFAULT NULL,
--   i_jscode IN VARCHAR2 DEFAULT NULL,
--   i_own_form IN BOOLEAN DEFAULT FALSE
--)
--IS
--BEGIN
--   htp.p (utils.ite(i_own_form,'<FORM '||utils.ifnn(i_action,'action="'||i_action||'" METHOD="POST" TARGET="_self"')||'>','')||'<INPUT TYPE="button" NAME="' ||
--          i_name ||
--          '"' ||
--          util.ifnn (i_btntxt, ' VALUE="' || i_btntxt || '"') ||
--          util.ifnn (i_jscode,
--          ' onClick="' || i_jscode || '"'
--          ) ||
--          '>'||
--           util.ite(i_own_form,'</FORM>',''));
--END fm_btn;

/**-----------------------------------------------------------------------------
prob_type:
 Creates a drop-down list of optional problem types.
------------------------------------------------------------------------------*/
PROCEDURE prob_type_dd
(
   i_name     IN VARCHAR2,
   i_selected IN VARCHAR2 DEFAULT NULL,
   i_disabled IN VARCHAR2 DEFAULT NULL
) IS
   lar_type_nm tar_select_vals;
   l_selected  VARCHAR2(1);
   l_cv        SYS_REFCURSOR;
BEGIN
   logs.dbg('Get Problem Source codeset');
   OPEN l_cv FOR
     SELECT LPAD(' ',3*(LEVEL-1),'.') || prob_src_nm AS prob_src_nm, prob_src_id
       FROM ps_prob_src
      WHERE active_flg = 'Y'
      START WITH prnt_prob_src_id IS NULL
      CONNECT BY PRIOR prob_src_id = prnt_prob_src_id
      ORDER SIBLINGS BY display_order;
      
   FETCH l_cv BULK COLLECT INTO lar_type_nm;
   CLOSE l_cv;
   
   logs.dbg('Add the blank option to the front');
   lar_type_nm(0).LABEL := '';
   lar_type_nm(0).VALUE := '';

   logs.dbg('Load up the HTML drop-down list');
   htp.formSelectOpen(cname => i_name, cattributes => i_disabled);
   FOR i IN lar_type_nm.FIRST .. lar_type_nm.LAST LOOP
      IF ((i_selected IS NULL AND i = 0) OR i_selected = lar_type_nm(i).VALUE) THEN
         l_selected := 'Y';
      END IF;
      htp.formSelectOption(lar_type_nm(i).LABEL,
                           l_selected,
                           'value="' || lar_type_nm(i).VALUE || '"');
      l_selected := NULL;
   END LOOP;
   htp.formSelectClose;
END prob_type_dd;

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------
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
) IS
   l_ps_data ps_dml.gcur_ps%ROWTYPE;
   l_enable_switch VARCHAR2(20);
   l_prob_id ps_prob.prob_id%TYPE;
BEGIN
   logs.dbg('Submit ['||i_submit||'] ProbID ['||i_prob_id||']');

   IF (i_submit IN (gc_lbl_cancel, gc_lbl_return)) THEN
      -- empty out the last ID since the user wants to start over
      logs.dbg('Nullifying i_prob_id');
      l_prob_id := NULL;
   ELSE
      l_prob_id := i_prob_id;
   END IF;
   
   IF (l_prob_id IS NOT NULL) THEN
      -- If the requester knew what the problem ID was, we need to gather
      -- problem/solution attributes from the database, for they will be 
      -- displayed either for viewing or editing.
      logs.dbg('Gathering known attributes for problem ['||l_prob_id||'].');
      DECLARE
         l_msg app_log.log_txt%TYPE;
      BEGIN
         l_ps_data := ps_dml.get_prob_sol(l_prob_id);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_msg := 'Invalid Problem ID ['||TO_CHAR(l_prob_id)||']';
            logs.warn(l_msg);
            main(i_msg => l_msg);
            RETURN;
      END;

      -- If request was for a View page, the DISABLED token will disable form fields
      IF (i_submit = gc_lbl_view) THEN
         logs.dbg('Disabling editable fields.');
         l_enable_switch := 'DISABLED';
      ELSE
         l_enable_switch := '';
      END IF;
   END IF;
   
   IF (i_submit IS NULL OR i_submit IN (gc_lbl_view,gc_lbl_edit,gc_lbl_cancel,gc_lbl_return)) THEN
      logs.dbg('Displaying main submission form.');
      header('Problem-Solution KnowledgeBase');
      htp.p('<H1><a href="ps_ui.main">Repository of Common Problems and their Solutions.</a></H1>');

      IF (i_msg IS NULL) THEN
         htp.p('<br />');
      ELSE
         htp.p('<H4>'||'Previous Action Feedback >> '||i_msg||'</H3>');
      END IF;

      table_3col('Main content table');
      
      htp.p('<tr>');
      htp.p('<td>&nbsp;</td>');
      
      htp.p('<td>');

      IF (l_prob_id IS NULL) THEN
         htp.p('<H2>Enter what you have gathered so far about the problem.</H2>');
      ELSE
         htp.p('<H2>'||i_submit||' Problem and Solution'||'</H2>');
      END IF;
      htp.para;
      
      htp.formOpen(curl => 'ps_ui.main', ctarget => '_self', cattributes => 'id="mainForm"');
      htp.formHidden(cname => 'i_prob_id', cvalue => l_ps_data.prob_id);
      htp.p('Error ID or Problem Name<br/>');
      htp.formText(cname => 'i_prob_key', csize => 30, cmaxlength => 50, 
         cvalue => l_ps_data.prob_key, cattributes => l_enable_switch);
      htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_search);
      htp.para;
      htp.p('Problem Source (optional)<br/>');
      prob_type_dd('i_prob_src_id', l_ps_data.prob_src_id, l_enable_switch);
      htp.para;
      htp.p('Error Message (if any)<br/>');
      htp.formTextAreaOpen2(cname => 'i_prob_key_txt', nrows => 2, 
         ncolumns => 80, cattributes => l_enable_switch);
      htp.p(l_ps_data.prob_key_txt);
      htp.formTextAreaClose;
      htp.para;
      htp.p('Problem Description and Notes<br/>');
      htp.formTextAreaOpen2(cname => 'i_prob_notes', nrows => 10, ncolumns => 80, cattributes => l_enable_switch);
      htp.p(l_ps_data.prob_notes);
         
      htp.formTextAreaClose;
      htp.para;
      htp.p('Solution (if known)<br/>');
      htp.formTextAreaOpen2(cname => 'i_sol_notes', nrows => 10, 
         ncolumns => 80, cattributes => l_enable_switch);
      htp.p(l_ps_data.sol_notes);
      htp.formTextAreaClose;
      htp.p('<center>');

      IF (i_submit IS NULL OR i_submit IN (gc_lbl_cancel,gc_lbl_return)) THEN
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_add);
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_cancel);
      ELSIF (i_submit = gc_lbl_view) THEN
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_edit);
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_cancel);
      ELSIF (i_submit = gc_lbl_edit) THEN
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_view);
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_update);
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_delete);
         htp.formSubmit(cname => 'i_submit', cvalue => gc_lbl_cancel);
      END IF;
      htp.p('</center>');
      htp.formClose;
      htp.p('</td>');
      
      htp.p('</tr>');
      htp.p('</table');
      footer;
      
   ELSIF (i_submit = gc_lbl_search) THEN

      logs.dbg('Calling upon Search form.');
      search(i_prob_key);

   ELSIF (i_submit = gc_lbl_add) THEN

      logs.dbg('Adding problem data to DB.');
      DECLARE
         l_new_prob_id ps_prob.prob_id%TYPE;
         l_msg         VARCHAR2(200);
      BEGIN
         ps_dml.ins_prob(l_new_prob_id,
                         i_prob_key,
                         i_prob_key_txt,
                         i_prob_notes,
                         i_prob_src_id);

         l_msg := 'Problem';

         logs.dbg('Adding solution data to database.');
         IF (i_sol_notes IS NOT NULL) THEN
            ps_dml.ins_sol(l_new_prob_id, i_sol_notes);
            l_msg := l_msg || ' and solution';
         END IF;
         l_msg := l_msg || ' added to the database.';
         main(l_msg);
      END;

   ELSIF (i_submit = gc_lbl_update) THEN

      logs.dbg('Updating DB with latest problem data.');
      DECLARE
         l_msg VARCHAR2(200);
      BEGIN
         l_msg := 'Problem';
         IF ((i_prob_key <> l_ps_data.prob_key OR
              i_prob_key IS NULL AND l_ps_data.prob_key IS NOT NULL OR
              i_prob_key IS NOT NULL AND l_ps_data.prob_key IS NULL)
              OR
             (i_prob_key_txt <> l_ps_data.prob_key_txt OR
              i_prob_key_txt IS NULL AND l_ps_data.prob_key_txt IS NOT NULL OR
              i_prob_key_txt IS NOT NULL AND l_ps_data.prob_key_txt IS NULL)
              OR
             (i_prob_notes <> l_ps_data.prob_notes OR
              i_prob_notes IS NULL AND l_ps_data.prob_notes IS NOT NULL OR
              i_prob_notes IS NOT NULL AND l_ps_data.prob_notes IS NULL)) THEN
         
            ps_dml.upd_prob(i_prob_id,
                            i_prob_key,
                            i_prob_key_txt,
                            i_prob_notes,
                            i_prob_src_id);
            l_msg := 'Problem';

         END IF;

         IF (i_sol_notes <> l_ps_data.sol_notes OR
             i_sol_notes IS NULL AND l_ps_data.sol_notes IS NOT NULL OR
             i_sol_notes IS NOT NULL AND l_ps_data.sol_notes IS NULL) THEN
            
            ps_dml.upd_sol(l_ps_data.sol_id, l_ps_data.prob_id, i_sol_notes);
            l_msg := l_msg || ' and solution';

         END IF;

         l_msg := l_msg || ' updated in the database.';
         main(l_msg);

      END;
   
   ELSIF (i_submit = gc_lbl_delete) THEN
      logs.dbg('Removing problem ['||l_prob_id||'] from DB.');
      DECLARE
         l_msg VARCHAR2(200);
      BEGIN
         ps_dml.del_prob(l_ps_data.prob_id);
         l_msg := 'Problem ID '||l_ps_data.prob_id||' and its solutions removed.';
         main(l_msg);        
      END;
   END IF;
   
END main;

--------------------------------------------------------------------------------
PROCEDURE search(i_search_str IN VARCHAR2) IS
   l_count INTEGER := 0;
BEGIN
   header('Problem-Solution KnowledgeBase | Search Results');
   htp.p('<H1>Search Results</H1>');
   htp.p('<H3>'||'Searched using tokens: '||i_search_str||'</H3>');

   table_3col('Search results table',10,40,40,1);

   htp.p('<tr>');
   htp.p('<th>Problem Key</th><th>Problem Text and Notes</th><th>Solution</th>');
   htp.p('</tr>');
   
   logs.dbg('Searching using '||i_search_str);
   FOR lr IN ps_dml.gcur_ps(i_search_str) LOOP
      l_count := l_count + 1;
      htp.p('<tr>');
      htp.p(
         '<td valign="top">'||'<a href="ps_ui.main?i_prob_id='||lr.prob_id||'&i_submit=View">[View] '||
                 '<a href="ps_ui.main?i_prob_id='||lr.prob_id||'&i_submit=Edit">[Edit] '||
                 '<br />'||lr.prob_key||'</td>'||
         '<td valign="top">'||lr.prob_key_txt||'<br/><p>'||SUBSTR(lr.prob_notes,1,200)||'</p></td>'||
         '<td valign="top">'||SUBSTR(lr.sol_notes,1,200)||'</td>'
      );
      htp.p('</tr>');
   END LOOP;

   IF (l_count = 0) THEN
      htp.p('<tr><td colspan="3" align="center"> No Matches Found </td></tr>');
   END IF;

   htp.p('</table>');

   htp.p('<br />');
   htp.formOpen(curl => 'ps_ui.main',ctarget => '_self');
   htp.formSubmit(cname => NULL, cvalue => gc_lbl_return);
   htp.formClose;
   footer;
END search;

END ps_ui;
/
