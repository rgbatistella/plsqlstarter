CREATE OR REPLACE PACKAGE ldap
  AUTHID CURRENT_USER
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
--                               PUBLIC CURSORS 
-------------------------------------------------------------------------------- 
 
-------------------------------------------------------------------------------- 
--                                PUBLIC TYPES 
-------------------------------------------------------------------------------- 
SUBTYPE t_dn       IS VARCHAR2(256);
SUBTYPE t_attr_nm  IS VARCHAR2(256);
SUBTYPE t_attr_val IS VARCHAR2(32767);

TYPE tr_attr_val IS RECORD (
   attr_nm  t_attr_nm,
   attr_val t_attr_val
);
-- numerically indexed associative array of record
TYPE t_attr_val_tab IS TABLE OF tr_attr_val INDEX BY PLS_INTEGER;
-- name indexed associative array of values
TYPE t_val_arr IS TABLE OF t_attr_val INDEX BY t_attr_nm;
-- DN-indexed collection of attribute name/value arrays (a nested collection)
TYPE t_attrs_matrix IS TABLE OF t_attr_val_tab INDEX BY t_dn;
 
-------------------------------------------------------------------------------- 
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC. 
-------------------------------------------------------------------------------- 
tree_base CONSTANT VARCHAR2(256) := 'o=<treebase>';

-------------------------------------------------------------------------------- 
--                              PUBLIC FUNCTIONS 
-------------------------------------------------------------------------------- 
 
/**----------------------------------------------------------------------------- 
get_filtered_attrs
 Provides the base wrapper over DBMS_LDAP required by the other routines offered
 by this package.

%param i_filter A valid ldap filter, like "(cn=myusername)" or 
                     "(&(objectclass=inetOrgPerson)(sn=Wildm*))"
%param i_attr_list A comma-delimited list of valid entry attribute types, such as
                   "sn,givenName,empID,dept". If the list is empty, all attributes
                   for matching entries will be returned. If the named attribute
                   is missing for the entry, the value for the attribute will be
                   empty as well.
%param i_search_base Optional. Provide a different value if you need the search to
                   start at a different point in the tree. Defaults to 
%param i_search_scope Optional. Defaults to the whole tree beneath the search base.
                      Specify dbms_ldap.SCOPE_ONELEVEL or SCOPE_BASE if that makes
                      sense for your search.
------------------------------------------------------------------------------*/ 
FUNCTION get_filtered_attrs
(
   i_filter IN VARCHAR2,
   i_attr_list    IN VARCHAR2 DEFAULT NULL,
   i_search_base  IN VARCHAR2 DEFAULT tree_base,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_attrs_matrix;

/**----------------------------------------------------------------------------- 
get_entry_attr: 
 Given a unique LDAP identifier for an entry, finds it and returns the value(s)
 of the named attribute. If there are more than one entry matching the filter,
 they will be ignored. Only the attribute of the first entry will be examined.

%param i_entry_filter A valid ldap filter, like "(cn=myusername)" or 
                     "(&(objectclass=inetOrgPerson)(sn=Wildm*))"
%param i_attr_nm A valid entry attribute type. If the attribute is empty or not 
                 found, the returned value will be empty.
%param i_search_base Optional. Provide a different value if you need the search to
                   start at a different point in the tree.
%param i_search_scope Optional. Defaults to the whole tree beneath the search base.
                      Specify dbms_ldap.SCOPE_ONELEVEL or SCOPE_BASE if that makes
                      sense for your search.
------------------------------------------------------------------------------*/ 
FUNCTION get_entry_attr
(
   i_entry_filter IN VARCHAR2,
   i_attr_nm      IN VARCHAR2,
   i_search_base  IN VARCHAR2,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN VARCHAR2;

/**----------------------------------------------------------------------------- 
get_user_attr: 
 Given a unique LDAP identifier for a user, finds the user and returns the value(s)
 of the named attribute.

%see get_entry_attr for parameter explanations.
------------------------------------------------------------------------------*/ 
FUNCTION get_user_attr
(
   i_user_filter  IN VARCHAR2,
   i_attr_nm      IN VARCHAR2,
   i_search_base  IN VARCHAR2 DEFAULT NULL,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN VARCHAR2;

/**----------------------------------------------------------------------------- 
get_entry_attrs: 
 Given a unique LDAP identifier for an entry, finds it and returns the value(s)
 of the attributes in the comma-delimited list. If there are more than one 
 entry matching the filter, they will be ignored. Only the attributes of the 
 first entry will be examined.

%param i_entry_filter A valid ldap filter, like "(cn=myusername)" or 
                     "(&(objectclass=inetOrgPerson)(sn=Wildm*))"
%param i_attr_list A comma-delimited list of valid entry attribute types, such as
                   "sn,givenName,empID,dept". If an attribute is empty or not 
                   found, the returned value for that attribute will be empty.
%param i_search_base Optional. Provide a different value if you need the search to
                   start at a different point in the tree.
%param i_search_scope Optional. Defaults to the whole tree beneath the search base.
                      Specify dbms_ldap.SCOPE_ONELEVEL or SCOPE_BASE if that makes
                      sense for your search.
%return A collection of attribute/value pairs, indexed numerically beginning at 1.                      
------------------------------------------------------------------------------*/ 
FUNCTION get_entry_attrs
(
   i_entry_filter IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_attr_val_tab;

/**----------------------------------------------------------------------------- 
get_entry_attrs2: 
 Overloaded version to return string-indexed array. Given a unique LDAP 
 identifier for an entry, finds it and returns the value(s) of the list of 
 attributes.

%see get_entry_attrs for parameter explanations.

%return A collection of values, indexed by the attribute names.                      
------------------------------------------------------------------------------*/ 
FUNCTION get_entry_attrs2
(
   i_entry_filter IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_val_arr;

/**----------------------------------------------------------------------------- 
get_user_attrs: 
 Given a unique LDAP identifier for a user, finds the user and returns the value(s)
 of the list of attributes. If the search base is not specified, the search
 base defaults to the top level People node (a literal kept in the package body).

%see get_entry_attrs for parameter explanations.
%return A collection of attribute/value pairs, indexed numerically beginning at 1.                      
------------------------------------------------------------------------------*/ 
FUNCTION get_user_attrs
(
   i_user_filter  IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2 DEFAULT NULL,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_attr_val_tab;

/**----------------------------------------------------------------------------- 
get_user_attrs2: 
 Overloaded version to return string-indexed array. Given a unique LDAP 
 identifier for a user, finds the user and returns the value(s) of the list of 
 attributes. If the search base is not specified, the search base defaults to 
 the top level People node (a literal kept in the package body).

%see get_entry_attrs for parameter explanations.
%return A collection of values, indexed by the attribute names.                      
------------------------------------------------------------------------------*/ 
FUNCTION get_user_attrs2
(
   i_user_filter  IN VARCHAR2,
   i_attr_list    IN VARCHAR2,
   i_search_base  IN VARCHAR2 DEFAULT NULL,
   i_search_scope IN PLS_INTEGER DEFAULT dbms_ldap.SCOPE_SUBTREE
) RETURN t_val_arr;

-------------------------------------------------------------------------------- 
--                              PUBLIC PROCEDURES 
-------------------------------------------------------------------------------- 

/**----------------------------------------------------------------------------- 
show_user_attrs:
 A test routine to display all the known attributes of a given user. Internal
 logic prevents it from being used in production.
------------------------------------------------------------------------------*/ 
PROCEDURE show_user_attrs
(
   i_user_filter  IN VARCHAR2
);

/**----------------------------------------------------------------------------- 
test_bind:
 A test routine just to ensure the bind parameters are correct and the server
 can be reached over the configured port.
------------------------------------------------------------------------------*/ 
PROCEDURE test_bind;
 
END ldap;
/
