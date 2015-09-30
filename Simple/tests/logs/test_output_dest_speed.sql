SET SERVEROUTPUT ON SIZE 1000000
SET TERMOUT OFF
DECLARE
   l_test VARCHAR2(20) := 'screen bare';
BEGIN
   timer.startme(l_test);
   FOR i IN 1..&&iterations LOOP
      dbms_output.put_line('X');
   END LOOP;
   timer.stopme(l_test);
   logs.set_targets(i_stdout => FALSE, i_table => TRUE, i_file => FALSE);
   logs.info('Test ['||l_test||'] of [&&iterations] took ['||timer.elapsed(l_test)||'] seconds.');
END;
/
SET TERMOUT ON
   
SET SERVEROUTPUT ON SIZE 1000000
SET TERMOUT OFF
DECLARE
   l_test VARCHAR2(20) := 'screen';
BEGIN
   timer.startme(l_test);
   logs.set_targets(i_stdout => TRUE, i_table => FALSE, i_file => FALSE);
   FOR i IN 1..&&iterations LOOP
      logs.info('X');
   END LOOP;
   timer.stopme(l_test);
   logs.set_targets(i_stdout => FALSE, i_table => TRUE, i_file => FALSE);
   logs.info('Test ['||l_test||'] of [&&iterations] took ['||timer.elapsed(l_test)||'] seconds.');
END;
/
SET TERMOUT ON

SET SERVEROUTPUT ON SIZE 1000000
DECLARE
   l_test VARCHAR2(20) := 'file';
BEGIN
   timer.startme(l_test);
   logs.set_targets(i_stdout => FALSE, i_table => FALSE, i_file => TRUE);
   FOR i IN 1..&&iterations LOOP
      logs.info('X');
   END LOOP;
   timer.stopme(l_test);
   logs.set_targets(i_stdout => FALSE, i_table => TRUE, i_file => FALSE);
   logs.info('Test ['||l_test||'] of [&&iterations] took ['||timer.elapsed(l_test)||'] seconds.');
END;
/
   
SET SERVEROUTPUT ON SIZE 1000000
DECLARE
   l_test VARCHAR2(20) := 'table';
BEGIN
   timer.startme(l_test);
   logs.set_targets(i_stdout => FALSE, i_table => TRUE, i_file => FALSE);
   FOR i IN 1..&&iterations LOOP
      logs.info('X');
   END LOOP;
   timer.stopme(l_test);
   logs.set_targets(i_stdout => FALSE, i_table => TRUE, i_file => FALSE);
   logs.info('Test ['||l_test||'] of [&&iterations] took ['||timer.elapsed(l_test)||'] seconds.');
END;
/

-- start waiter here before calling the sending proc below
   
SET SERVEROUTPUT ON SIZE 1000000
DECLARE
   l_test VARCHAR2(20) := 'pipe';
   l_result INTEGER;
BEGIN
   timer.startme(l_test);
   l_result := dbms_pipe.create_pipe('DEBUG');
   FOR i IN 1..&&iterations LOOP
      dbms_pipe.pack_message('X');
      l_result := dbms_pipe.send_message('DEBUG');
   END LOOP;
   l_result := dbms_pipe.remove_pipe('DEBUG');
   timer.stopme(l_test);
   logs.set_targets(i_stdout => FALSE, i_table => TRUE, i_file => FALSE);
   logs.info('Test ['||l_test||'] of [&&iterations] took ['||timer.elapsed(l_test)||'] seconds.');
END;
/

--TRUNCATE TABLE app_log;
SELECT * FROM app_log;
SELECT t.*, t.rowid FROM app_log t WHERE log_txt LIKE 'Test%';
