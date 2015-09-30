-- Tests of new timer.elapsed interface
SET SERVEROUTPUT ON SIZE 1000000
DECLARE
   l_count INTEGER := 0;
BEGIN
   dbms_output.put_line('Test 1: no time at all');
   timer.startme('notime');
   timer.stopme('notime');
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('notime'))||']'); -- seconds
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('notime','s'))||']'); -- seconds
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('notime','ms'))||']'); -- milliseconds
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('notime','cs'))||']'); -- centiseconds
   
   dbms_output.put_line('Test 2: something short');
   timer.startme('short');
   SELECT COUNT(*) INTO l_count FROM all_objects;
   timer.stopme('short');
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('short'))||']'); -- seconds
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('short','s'))||']'); -- seconds
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('short','ms'))||']'); -- milliseconds
   dbms_output.put_line('Expected [?] Actual['||TO_CHAR(timer.elapsed('short','cs'))||']'); -- centiseconds
   
   dbms_output.put_line('Test 3: 1 second');
   timer.startme('1second');
   dbms_lock.sleep(1);
   timer.stopme('1second');
   dbms_output.put_line('Expected [1] Actual['||TO_CHAR(timer.elapsed('1second'))||']'); -- seconds
   dbms_output.put_line('Expected [1] Actual['||TO_CHAR(timer.elapsed('1second','s'))||']'); -- seconds
   dbms_output.put_line('Expected [1000] Actual['||TO_CHAR(timer.elapsed('1second','ms'))||']'); -- milliseconds
   dbms_output.put_line('Expected [100] Actual['||TO_CHAR(timer.elapsed('1second','cs'))||']'); -- centiseconds
   
   dbms_output.put_line('Test 4: 10 seconds');
   timer.startme('10seconds');
   dbms_lock.sleep(10);
   timer.stopme('10seconds');
   dbms_output.put_line('Expected [10] Actual['||TO_CHAR(timer.elapsed('10seconds'))||']'); -- seconds
   dbms_output.put_line('Expected [10] Actual['||TO_CHAR(timer.elapsed('10seconds','s'))||']'); -- seconds
   dbms_output.put_line('Expected [10000] Actual['||TO_CHAR(timer.elapsed('10seconds','ms'))||']'); -- milliseconds
   dbms_output.put_line('Expected [1000] Actual['||TO_CHAR(timer.elapsed('10seconds','cs'))||']'); -- centiseconds

END;
/
