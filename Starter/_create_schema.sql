/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

%design
 Script to create the user which owns the framework tables and packages. If 
 you wish to use an existing user to own these packages, make sure you comment
 out the line in the driving script that calls this script.

 This script uses substition variables. It assumes that a calling script
 defined the variables:
 
 fmwk_home, fmwk_pswd, temp_tablespace and default_tablespace

 If you wish further flexibility, simply alter this script.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      2007Oct15 Creation

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

PROMPT Creating user &&fmwk_home...

------------                       CREATE USER                        ----------
CREATE USER &&fmwk_home
  IDENTIFIED BY "&&fmwk_pswd"
  DEFAULT TABLESPACE &&default_tablespace
  TEMPORARY TABLESPACE &&temp_tablespace
  QUOTA UNLIMITED ON &&default_tablespace
  QUOTA UNLIMITED ON &&index_tablespace;
  
-- Grant/Revoke role privileges 
GRANT SELECT_CATALOG_ROLE TO &&fmwk_home;
GRANT EXECUTE_CATALOG_ROLE TO &&fmwk_home;
GRANT SELECT ANY DICTIONARY TO &&fmwk_home;
--GRANT EXECUTE ON dbms_lock TO &&fmwk_home;

PROMPT Granting appropriate privileges to &&fmwk_home...

------------                     CREATE PROFILE                       ----------
-- Add resource limits here if you wish them



------------           GRANT/REVOKE SYSTEM PRIVILEGES                 -----------
-- Note: Those useful for extensions to the framework are commented out.
-- Comment back in as you write definer/invoker routines that require them.

-- ANY privs
GRANT CREATE ANY CONTEXT TO &&fmwk_home;
GRANT CREATE ANY SYNONYM TO &&fmwk_home;
GRANT DROP ANY SYNONYM TO &&fmwk_home;
--GRANT ANALYZE ANY TO &&fmwk_home;
--GRANT AUDIT ANY TO &&fmwk_home;
--GRANT CREATE PUBLIC DATABASE LINK TO &&fmwk_home;
--GRANT DROP PUBLIC DATABASE LINK;
--GRANT ADMINISTER DATABASE TRIGGER TO &&fmwk_home;
--GRANT CREATE ANY TRIGGER TO &&fmwk_home;
--GRANT ALTER ANY TRIGGER TO &&fmwk_home;
--GRANT DROP ANY TRIGGER TO &&fmwk_home;

-- Create privs
--GRANT CREATE CLUSTER TO &&fmwk_home;
--GRANT CREATE JOB TO &&fmwk_home; -- 10g+
--GRANT CREATE DATABASE LINK TO &&fmwk_home;
--GRANT CREATE INDEXTYPE TO &&fmwk_home;
--GRANT CREATE MATERIALIZED VIEW TO &&fmwk_home;
--GRANT CREATE OPERATOR TO &&fmwk_home;
GRANT CREATE PROCEDURE TO &&fmwk_home;
--GRANT CREATE ROLE TO &&fmwk_home;
GRANT CREATE SEQUENCE TO &&fmwk_home;
GRANT CREATE SESSION TO &&fmwk_home;
GRANT CREATE SYNONYM TO &&fmwk_home;
GRANT CREATE TABLE TO &&fmwk_home;
GRANT CREATE TRIGGER TO &&fmwk_home;
GRANT CREATE TYPE TO &&fmwk_home;
GRANT CREATE VIEW TO &&fmwk_home;
-- Alter privs
GRANT ALTER SESSION TO &&fmwk_home;
-- Other privs
GRANT DEBUG CONNECT SESSION TO &&fmwk_home;
--GRANT MANAGE SCHEDULER TO &&fmwk_home; --10g+


PROMPT Done.
