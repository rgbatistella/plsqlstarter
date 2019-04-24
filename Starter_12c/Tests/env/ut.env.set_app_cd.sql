SET SERVEROUTPUT ON SIZE 1000000
DECLARE
   l_app_cd VARCHAR2(10);
BEGIN
   env.set_app_cd('CORE');
   l_app_cd := SYS_CONTEXT('app_core_ctx','app_cd');
   io.p('l_app_cd',l_app_cd);
END;
/
