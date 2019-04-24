/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

%design
 Script to create the the test schemas that match those mentioned in APP_ENV.

 This script uses substition variables. It assumes that a calling script
 defined the variables test_user, def_tablespace and temp_tablespace. If not, 
 you will be prompted for them, so be prepared with the answer.

 If you wish further flexibility, simply alter this script.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2008Mar13 Creation

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

PROMPT Creating user &&test_user...

------------                       CREATE USER                        ----------
CREATE USER &&test_user
  IDENTIFIED BY &&test_user
  DEFAULT TABLESPACE &&default_tablespace
  TEMPORARY TABLESPACE &&temp_tablespace
  QUOTA UNLIMITED ON &&default_tablespace;
  
-- Grant role privileges 
GRANT &&fmwk_home+_full TO &&test_user;

-- Grants so invoker-rights framework code can see V$ views
GRANT SELECT ON v_$instance TO &&test_user;
GRANT SELECT ON v_$mystat TO &&test_user;
GRANT SELECT ON v_$session TO &&test_user;
GRANT SELECT ON v_$version TO &&test_user;

-- Grant ANY privileges
--GRANT CREATE ANY CONTEXT TO &&test_user;

-- Typical Create privs required for application-owning accounts
GRANT CREATE MATERIALIZED VIEW TO &&test_user;
GRANT CREATE PROCEDURE TO &&test_user;
GRANT CREATE SEQUENCE TO &&test_user;
GRANT CREATE SESSION TO &&test_user;
GRANT CREATE SYNONYM TO &&test_user;
GRANT CREATE TABLE TO &&test_user;
GRANT CREATE TRIGGER TO &&test_user;
GRANT CREATE TYPE TO &&test_user;
GRANT CREATE VIEW TO &&test_user;
-- Alter privs
GRANT ALTER SESSION TO &&test_user;
-- Other privs
GRANT DEBUG CONNECT SESSION TO &&test_user;
-- Only valid on 10g+
GRANT CREATE JOB TO &&test_user;
GRANT MANAGE SCHEDULER TO &&test_user;


PROMPT Done.
