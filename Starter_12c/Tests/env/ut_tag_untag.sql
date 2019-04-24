-- First set for calls to tag/untag, relying on transparent determination of module/action/client_info
CREATE OR REPLACE PACKAGE a
AS
PROCEDURE driver;
PROCEDURE one_off;
END a;
/
CREATE OR REPLACE PACKAGE b
AS
PROCEDURE proc1;
END b;
/
CREATE OR REPLACE PACKAGE c
AS
PROCEDURE proc1;
END c;
/
CREATE OR REPLACE PACKAGE BODY a
AS
PROCEDURE driver
IS
BEGIN
   env.tag;
   dbms_lock.sleep(5);
   b.proc1;
   dbms_lock.sleep(5);
   env.tag;
   dbms_lock.sleep(5);
   b.proc1;
   dbms_lock.sleep(5);
   env.tag;
   dbms_lock.sleep(5);
   b.proc1;
   dbms_lock.sleep(5);
   env.untag(i_restore_prior_tag => FALSE);
END driver;
PROCEDURE one_off
IS
BEGIN
   env.tag;
   dbms_lock.sleep(8);
   env.untag(FALSE);
END one_off;
END a;
/
CREATE OR REPLACE PACKAGE BODY b
AS
PROCEDURE proc1
IS
BEGIN
   env.tag;
   dbms_lock.sleep(5);
   c.proc1;
   dbms_lock.sleep(5); -- to demonstrate when lower level untags
   env.untag;
END proc1;
END b;
/
CREATE OR REPLACE PACKAGE BODY c
AS
PROCEDURE proc1
IS
BEGIN
   env.tag;
   dbms_lock.sleep(5);
   env.untag;
END proc1;
END c;
/

EXEC a.driver;
-- have separate window continuously querying v$session:
-- 10g+
-- SELECT SID,serial#,username,status,PROGRAM,MODULE,action,client_info,client_identifier,blocking_session_status,event FROM v$session WHERE username = '&schema';
-- 9i
-- SELECT SID,serial#,username,status,PROGRAM,MODULE,action,client_info,client_identifier FROM v$session WHERE username = '&schema';


-- Second set for calls to tag/untag with explicit values
CREATE OR REPLACE PACKAGE a
AS
PROCEDURE driver;
PROCEDURE one_off;
END a;
/
CREATE OR REPLACE PACKAGE b
AS
PROCEDURE proc1;
END b;
/
CREATE OR REPLACE PACKAGE c
AS
PROCEDURE proc1;
END c;
/
CREATE OR REPLACE PACKAGE BODY a
AS
PROCEDURE driver
IS
BEGIN
   env.tag('A','driver','Begin');
   dbms_lock.sleep(5);
   b.proc1;
   dbms_lock.sleep(5); -- to demonstrate when lower level untags
   env.tag('A','driver','Middle');
   dbms_lock.sleep(5);
   b.proc1;
   dbms_lock.sleep(5); -- to demonstrate when lower level untags
   env.tag('A','driver','End');
   dbms_lock.sleep(5);
   b.proc1;
   dbms_lock.sleep(5); -- to demonstrate when lower level untags
   env.untag(i_restore_prior_tag => FALSE);
END driver;
PROCEDURE one_off
IS
BEGIN
   env.tag('OneOff','Sleeping');
   dbms_lock.sleep(8);
   env.untag(FALSE);
END one_off;
END a;
/
CREATE OR REPLACE PACKAGE BODY b
AS
PROCEDURE proc1
IS
BEGIN
   env.tag('B','proc1','Working...');
   dbms_lock.sleep(5);
   c.proc1;
   dbms_lock.sleep(5); -- to demonstrate when lower level untags
   env.untag;
END proc1;
END b;
/
CREATE OR REPLACE PACKAGE BODY c
AS
PROCEDURE proc1
IS
BEGIN
   env.tag('C','proc1','Reached inner sanctum of C');
   dbms_lock.sleep(5);
   env.untag;
END proc1;
END c;
/

EXEC a.driver;
-- have separate window continuously querying v$session:
-- 10g+
-- SELECT SID,serial#,username,status,PROGRAM,MODULE,action,client_info,client_identifier,blocking_session_status,event FROM v$session WHERE username = '&schema';
-- 9i
-- SELECT SID,serial#,username,status,PROGRAM,MODULE,action,client_info,client_identifier FROM v$session WHERE username = '&schema';
