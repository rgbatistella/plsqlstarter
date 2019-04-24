CREATE OR REPLACE PACKAGE BODY ldap
/******************************************************************************* 
%author 
Bill Coulam (bcoulam@dbartisans.com) 
 
Contains constants and routines for interfacing with internal LDAP directories. 
 
<pre> 
Artisan      Date      Comments 
============ ========= ======================================================== 
bcoulam      1998Oct30 Creation
bcoulam      2009Aug18 Added get_filtered_attrs as base layer for all the other
                       getter routines, eliminating duplication in 3 of them.
 
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
g_ldap_port     PLS_INTEGER;
g_ldap_host      VARCHAR2(1024);
g_ldap_bind_user VARCHAR2(256);
g_ldap_bind_pswd VARCHAR2(256);
g_people_base    VARCHAR2(256);
g_wallet_path    VARCHAR2(1024);
g_wallet_pswd    VARCHAR2(100);

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES 
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
parse_list:
 Parses a delimited list into a collection of strings. Requires a sparsely 
 populated, clean list of delimited strings in order to be speedy.

%param i_string  Delimited string, otherwise known as a list.
%param i_splitchar Character to use as the delimiter. The delimiter can be multiple
                   characters, like ::, =>, etc.
%return The filled PL/SQL table of strings parsed out of the delimited list.
------------------------------------------------------------------------------*/
FUNCTION parse_list
(
   i_list      IN VARCHAR2,
   i_splitchar IN VARCHAR2 DEFAULT ','
) RETURN dbms_ldap.string_collection
IS
   l_curr_pos   NUMBER;
   l_next_pos   NUMBER;
   l_num_values NUMBER;
   l_str_tab    dbms_ldap.string_collection;

BEGIN
   l_num_values := 0;
   l_curr_pos   := 1;

   l_next_pos := INSTR(i_list, i_splitchar);
   WHILE (l_next_pos <> 0) LOOP
      l_num_values := l_num_values + 1;
      l_str_tab(l_num_values) := SUBSTR(i_list,
                                        l_curr_pos,
                                        l_next_pos - l_curr_pos);
   
      l_curr_pos := l_next_pos + LENGTH(i_splitchar);
      l_next_pos := INSTR(i_list, i_splitchar, l_curr_pos);
   
   END LOOP;

   l_str_tab(l_num_values + 1) := SUBSTR(i_list, l_curr_pos);
   
   RETURN l_str_tab;
   
END parse_list;

/**-----------------------------------------------------------------------------
switch_to_ssl
 If the configured port is not the standard port, will attempt to open an SSL
 channel with the LDAP server given a valid session handle.
------------------------------------------------------------------------------*/
PROCEDURE switch_to_ssl(i_ldap_session IN dbms_ldap.SESSION)
IS
   l_returned PLS_INTEGER := -1;
BEGIN
   -- Establish SSL connection over existing LDAP session  
   l_returned := dbms_ldap.open_ssl(i_ldap_session,
                                    -- this location must start with "file:" or it won't work
                                    -- customize the location based on where your wallet is stored
                                    g_wallet_path,
                                    g_wallet_pswd,
                                    2 -- one-way authentication required
                                    );
   logs.dbg('open_ssl returned [' || TO_CHAR(l_returned) || ']');
END switch_to_ssl;

/**-----------------------------------------------------------------------------
init
 Takes the host and port and attempts to handshake with the LDAP server. If the
 server can be reached, a session is started and a handle to the server is 
 returned for later DBMS_LDAP calls.
------------------------------------------------------------------------------*/
PROCEDURE init (o_ldap_session OUT dbms_ldap.SESSION)
IS
   l_ldap_session dbms_ldap.SESSION;
BEGIN
   logs.dbg('Host ['||g_ldap_host||'] Port ['||g_ldap_port||']');
   l_ldap_session := dbms_ldap.init(g_ldap_host, g_ldap_port);
   -- Assume SSL is desired if not standard port   
   IF (g_ldap_port <> dbms_ldap.PORT) THEN
      logs.dbg('Switching to SSL...');
      switch_to_ssl(l_ldap_session);
   END IF;
   o_ldap_session := l_ldap_session;
END init;

/**-----------------------------------------------------------------------------
bind
 Bind to the LDAP server using a valid session handle, a DN and password that 
 should be found somewhere in the LDAP tree. If the DN is not found or the 
 password is incorrect, the bind will fail.
------------------------------------------------------------------------------*/
PROCEDURE bind (i_ldap_session IN dbms_ldap.SESSION)
IS
   l_returned PLS_INTEGER := -1;
BEGIN
   -- Authenticate and attach to the directory server
   logs.dbg('Bind User ['||g_ldap_bind_user||'] Bind Password ['||g_ldap_bind_pswd||']');
   l_returned := dbms_ldap.simple_bind_s(i_ldap_session, g_ldap_bind_user, g_ldap_bind_pswd);
   logs.dbg('simple_bind_s returned [' || TO_CHAR(l_returned) || ']');
   
   IF (l_returned = dbms_ldap.SUCCESS) THEN
      logs.dbg('Bind SUCCESS!');
   ELSE
      logs.dbg('Bind FAILURE!');
   END IF; -- if the search worked
END bind;

/**-----------------------------------------------------------------------------
unbind
 Disconnect from the LDAP server using the session handle.
------------------------------------------------------------------------------*/
PROCEDURE unbind (io_ldap_session IN OUT dbms_ldap.SESSION)
IS
   l_returned PLS_INTEGER := -1;
BEGIN
   l_returned := dbms_ldap.unbind_s(io_ldap_session);
   logs.dbg('unbind_s returned [' || TO_CHAR(l_returned) || ']');
END unbind;

/**-----------------------------------------------------------------------------
free_msgs
 Frees the chain of messages associated with the message handle returned by
 synchronous search functions. Only required if a DBMS_LDAP search has been
 performed. 
------------------------------------------------------------------------------*/
PROCEDURE free_msgs(i_message IN dbms_ldap.MESSAGE)
IS
   l_returned PLS_INTEGER := -1;
BEGIN
   l_returned := dbms_ldap.msgfree(i_message);
   logs.dbg('msgfree returned [' || TO_CHAR(l_returned) || ']');
END free_msgs;   

/**-----------------------------------------------------------------------------
search
 Performs simple synchronous LDAP search using given parameters.
 
%note Even when dbms_ldap.search_s is fed a bogus filter, it still returns 0 
      (DBMS_LDAP.SUCCESS). The true test of whether a search worked is whether
      any entries were returned. So we were able to factor out this call, since
      any test of l_returned was meaningless. 
------------------------------------------------------------------------------*/
PROCEDURE search
(
   i_session       IN dbms_ldap.SESSION,
   i_search_base   IN VARCHAR2,
   i_search_scope  IN PLS_INTEGER,
   i_search_filter IN VARCHAR2,
   i_attrs         IN dbms_ldap.STRING_COLLECTION,
   o_message       OUT dbms_ldap.MESSAGE
) IS
   l_returned PLS_INTEGER := -1;
BEGIN
   l_returned := dbms_ldap.search_s(ld       => i_session,
                                    base     => i_search_base,
                                    scope    => i_search_scope,
                                    filter   => i_search_filter,
                                    attrs    => i_attrs,
                                    attronly => 0, -- both attr types and values
                                    res      => o_message);
   logs.dbg('search_s returned [' || TO_CHAR(l_returned) || ']');
END search;

-------------------------------------------------------------------------------- 
--                        PUBLIC FUNCTIONS AND PROCEDURES 
-------------------------------------------------------------------------------- 
FUNCTION get_filtered_attrs
(
   i_filter IN VARCHAR2,
   i_attr_list    IN VARCHAR2 DEFAULT NULL,
   i_search_base  IN VARCHAR2 DEFAULT tree_base,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_attrs_matrix
IS
   l_session   dbms_ldap.SESSION;
   l_attrs     dbms_ldap.STRING_COLLECTION;
   l_message   dbms_ldap.MESSAGE;
   l_entry     dbms_ldap.MESSAGE;
   l_ber_elmt  dbms_ldap.BER_ELEMENT;
   l_vals      dbms_ldap.STRING_COLLECTION;
   l_dn        t_dn;
   l_attrs_matrix t_attrs_matrix;
   l_attr_name t_attr_nm;
   l_attr_idx  INTEGER := 0;
   l_num_entries INTEGER := 0;
   l_attr_val_tab t_attr_val_tab;
   l_dn_requested BOOLEAN := FALSE;
   l_all_attrs_requested BOOLEAN := FALSE;
BEGIN
   -- Accepting option of exceptions raised by DBMS_LDAP library.
   dbms_ldap.use_exception := TRUE;
   
   init(l_session); -- session handle returned
   bind(l_session); -- session handle passed
   
   -- Issue the search by the given attribute
   IF (i_attr_list IS NULL OR TRIM(i_attr_list) = '*') THEN
      l_attrs(1) := '*'; -- get all attributes if none requested
      l_all_attrs_requested := TRUE;
   ELSE
      -- Relies on caller knowing what the valid attribute types (names) are
      l_attrs := parse_list(i_attr_list);
      FOR i IN l_attrs.FIRST .. l_attrs.LAST LOOP
         IF (LOWER(l_attrs(i)) = 'dn') THEN
            l_dn_requested := TRUE;
         END IF;
      END LOOP;
   END IF;
   
   search(i_session       => l_session,
          i_search_base   => i_search_base,
          i_search_scope  => i_search_scope,
          i_search_filter => i_filter,
          i_attrs         => l_attrs,
          o_message       => l_message);
   
   -- Future: Consider a limit of perhaps 1,000 - 5,000 entries. Beyond that,
   --         raise an error requiring a more limiting filter.
   -- Count the number of entries returned
   l_num_entries := dbms_ldap.count_entries(l_session, l_message);
   logs.dbg('count_entries returned ['||TO_CHAR(l_num_entries)||'] matches.');

   IF (l_num_entries > 0) THEN
         
      -- Get the first entry
      l_entry := dbms_ldap.first_entry(l_session, l_message);
      
      <<entries>>
      WHILE l_entry IS NOT NULL LOOP
         -- Re-initialize variables used in the loop
         l_dn := NULL;
         l_attr_name := NULL;
         l_attr_idx := 0;
         l_attr_val_tab.DELETE;
         l_ber_elmt := NULL;
         
         -- Get unique identifier for the entry
         l_dn := dbms_ldap.get_dn(l_session, l_entry);
         logs.dbg('DN is ' || l_dn);
         
         -- If DN was requested as an attribute, put that in the front of the 
         -- collection of attibutes returned.
         IF (l_dn_requested) THEN
            l_attr_idx := l_attr_idx + 1;
            l_attr_val_tab(l_attr_idx).attr_nm := 'dn';
            l_attr_val_tab(l_attr_idx).attr_val := l_dn;
         END IF;
      
         -- This check is necessary because when dn is the only attribute requested,
         -- the entry comes back such that attempts to get attributes yield an
         -- INVALID BER ELEMENT error.
         IF (l_attrs.count > 1 OR (l_attrs.count = 1 AND l_dn_requested = FALSE)) THEN
            -- Get the first attribute for WHILE loop entry evaluation
            l_attr_name := dbms_ldap.first_attribute(l_session,
                                                     l_entry,
                                                     l_ber_elmt); -- BER is OUT parm here
            logs.dbg('First attribute: '||l_attr_name);
            
            <<attrs>>
            LOOP
            
               l_attr_idx := l_attr_idx + 1;

               IF (l_attr_name IS NOT NULL) THEN
                 
                  l_vals := dbms_ldap.get_values(l_session,
                                                 l_entry,
                                                 l_attr_name);
                        
                  logs.dbg('Number of '||l_attr_name||' values is : '||l_vals.COUNT);
                        
                  IF (l_vals.COUNT > 0) THEN
                     <<vals>>
                     FOR i IN l_vals.FIRST .. l_vals.LAST LOOP
                        IF (i <> l_vals.FIRST) THEN
                           l_attr_val_tab(l_attr_idx).attr_val := 
                              l_attr_val_tab(l_attr_idx).attr_val||','||l_vals(i);
                        ELSE
                           l_attr_val_tab(l_attr_idx).attr_nm  := l_attr_name;
                           l_attr_val_tab(l_attr_idx).attr_val := l_vals(i);
                        END IF;

                     END LOOP vals;
                  ELSE -- attribute not even used by the entry
                     l_attr_val_tab(l_attr_idx).attr_nm := l_attr_name;
                     l_attr_val_tab(l_attr_idx).attr_val := NULL;
                  END IF; -- if attribute has values
               END IF; -- if attribute found                     

               l_attr_name := dbms_ldap.next_attribute(l_session,
                                                       l_entry,
                                                       l_ber_elmt); -- BER is IN parm here
               
               IF l_all_attrs_requested THEN
                  EXIT WHEN l_attr_name IS NULL;
               ELSE
                  EXIT attrs WHEN l_attr_idx = l_attrs.count;
               END IF;
               
               logs.dbg('Next attribute: '||l_attr_name);
            END LOOP attrs;
            
            -- free BER element
            IF (l_ber_elmt IS NOT NULL) THEN
               dbms_ldap.ber_free(l_ber_elmt, 0);
            END IF;
         
         END IF; -- if more than 1 attribute, or one attribute is not DN
         
         l_attrs_matrix(l_dn) := l_attr_val_tab;
               
         l_entry := dbms_ldap.next_entry(l_session, l_entry);

      END LOOP entries;      

   END IF; -- if there are entries
   
   free_msgs(l_message);
   unbind(l_session);
   
   RETURN l_attrs_matrix;
   
END get_filtered_attrs;

--------------------------------------------------------------------------------
FUNCTION get_entry_attr
(
   i_entry_filter  IN VARCHAR2,
   i_attr_nm IN VARCHAR2,
   i_search_base IN VARCHAR2,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN VARCHAR2
IS
   -- "rs" means Result Set
   rs ldap.t_attrs_matrix;
   rs_idx ldap.t_dn;
   rs_attrs ldap.t_attr_val_tab;

   l_return_str t_attr_val;
   
BEGIN
   rs := get_filtered_attrs(i_entry_filter, i_attr_nm, i_search_base, i_search_scope);
   IF (rs.count > 0) THEN
      logs.dbg('Count of entries: '||rs.count);
      rs_idx := rs.FIRST;
      logs.dbg('First str index is '||rs_idx);
      IF (rs_idx IS NOT NULL) THEN
         rs_attrs := rs(rs_idx);
         logs.dbg('There are '||rs_attrs.count||' attributes for '||rs_idx);
         IF (rs_attrs.count > 0) THEN
            l_return_str := rs_attrs(1).attr_val;
         END IF;
      END IF;
   END IF;                                     
      
   RETURN l_return_str;
   
END get_entry_attr;

--------------------------------------------------------------------------------
FUNCTION get_user_attr
(
   i_user_filter IN VARCHAR2,
   i_attr_nm     IN VARCHAR2,
   i_search_base IN VARCHAR2 DEFAULT NULL,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN VARCHAR2
IS
BEGIN
   RETURN get_entry_attr(i_user_filter, i_attr_nm, NVL(i_search_base, g_people_base), i_search_scope);
END get_user_attr;

--------------------------------------------------------------------------------
FUNCTION get_entry_attrs
(
   i_entry_filter IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_attr_val_tab
IS
   -- "rs" means Result Set
   rs ldap.t_attrs_matrix;
   rs_idx ldap.t_dn;
   rs_attrs ldap.t_attr_val_tab;

BEGIN
   rs := get_filtered_attrs(i_entry_filter, i_attr_list, i_search_base, i_search_scope);

   IF (rs.COUNT > 0) THEN
      logs.dbg('Count of entries: '||rs.count);
      rs_idx := rs.FIRST;
      logs.dbg('First str index is '||rs_idx);
      IF (rs_idx IS NOT NULL) THEN
         rs_attrs := rs(rs_idx);
         logs.dbg('There are '||rs_attrs.count||' attributes for '||rs_idx);
      END IF;
   END IF;                                    
      
   RETURN rs_attrs;
   
END get_entry_attrs;

--------------------------------------------------------------------------------
FUNCTION get_entry_attrs2
(
   i_entry_filter IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_val_arr
IS
   l_val_arr t_val_arr;
   l_attr_val_tab t_attr_val_tab;
BEGIN
   l_attr_val_tab := get_entry_attrs(i_entry_filter,i_attr_list,i_search_base,i_search_scope);
   IF (l_attr_val_tab.count > 0) THEN
      FOR i IN l_attr_val_tab.FIRST..l_attr_val_tab.LAST LOOP
         l_val_arr(l_attr_val_tab(i).attr_nm) := l_attr_val_tab(i).attr_val;
      END LOOP;
   END IF;
   RETURN l_val_arr;
END get_entry_attrs2;

--------------------------------------------------------------------------------
FUNCTION get_user_attrs
(
   i_user_filter  IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2 DEFAULT NULL,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_attr_val_tab
IS
BEGIN
   RETURN get_entry_attrs(i_user_filter, i_attr_list, NVL(i_search_base, g_people_base), i_search_scope);
END get_user_attrs;

--------------------------------------------------------------------------------
FUNCTION get_user_attrs2
(
   i_user_filter  IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2 DEFAULT NULL,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_val_arr
IS
BEGIN
   RETURN get_entry_attrs2(i_user_filter, i_attr_list, NVL(i_search_base, g_people_base), i_search_scope);
END get_user_attrs2;

--------------------------------------------------------------------------------
PROCEDURE show_user_attrs
(
   i_user_filter  IN VARCHAR2
) IS
   -- "rs" means Result Set
   rs ldap.t_attrs_matrix;
   rs_idx ldap.t_dn;
   rs_attrs ldap.t_attr_val_tab;
   
BEGIN
   rs := get_filtered_attrs(i_filter => i_user_filter, i_attr_list => NULL, i_search_base => g_people_base, i_search_scope => 2);
   IF (rs.COUNT > 0) THEN
      logs.dbg('Count of entries: '||rs.count);
      rs_idx := rs.FIRST;
      logs.dbg('First str index is '||rs_idx);
      WHILE rs_idx IS NOT NULL LOOP
         rs_attrs := rs(rs_idx);
         logs.dbg('There are '||rs_attrs.count||' attributes for '||rs_idx);
         dbms_output.put_line('[[' || rs_idx || ']]');
         IF (rs_attrs IS NOT NULL AND rs_attrs.COUNT > 0) THEN
            FOR i IN rs_attrs.FIRST .. rs_attrs.LAST LOOP
               dbms_output.put_line('    ' || rs_attrs(i).attr_nm || ': ' || rs_attrs(i).attr_val);
            END LOOP;
         END IF;
         rs_idx := rs.NEXT(rs_idx);
         logs.dbg('Next is '||rs_idx);
      END LOOP;
   END IF;   
END show_user_attrs;

--------------------------------------------------------------------------------
PROCEDURE test_bind IS
   l_session dbms_ldap.SESSION;
BEGIN
   -- Accepting option of exceptions raised by DBMS_LDAP library.
   dbms_ldap.use_exception := TRUE;
   init(l_session); -- session handle returned
   bind(l_session); -- session handle passed
   unbind(l_session);
END test_bind;

--------------------------------------------------------------------------------
--                  PACKAGE INITIALIZATIOINS (RARELY USED)
--------------------------------------------------------------------------------
BEGIN
   g_ldap_host      := parm.get_val('ldap.url'); -- assumes URL contains protocol, hostname and port
   -- dbms_ldap.init won't work if LDAP server URL contains protocol, so strip it
   IF (INSTR(g_ldap_host,'ldap://') > 0) THEN
      g_ldap_host := REPLACE(g_ldap_host,'ldap://');
      g_ldap_port := dbms_ldap.PORT;
   END IF;
   IF (INSTR(g_ldap_host,'ldaps://') > 0) THEN
      g_ldap_host := REPLACE(g_ldap_host,'ldaps://');
      g_ldap_port := dbms_ldap.SSL_PORT;
   END IF;
   -- If LDAP server URL contains port (indicated by presence of colon after protocol-strip above)
   -- use it, otherwise stick with assumed ports
   IF (INSTR(g_ldap_host,':') > 0) THEN
      g_ldap_port := SUBSTR(g_ldap_host,INSTR(g_ldap_host,':')+1);
   END IF;

   g_ldap_bind_user := parm.get_val('ldap.manager.dn');
   g_ldap_bind_pswd := parm.get_val('ldap.manager.password');
   g_people_base := NVL(parm.get_val('ldap.user.base.dn'),'ou=People,'||tree_base);

   g_wallet_path := NVL(parm.get_val('Wallet Path'),'file:/opt/oracle/admin/wallet/');
   g_wallet_pswd := parm.get_val('Wallet Password');
      
END ldap;
/
