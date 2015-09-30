SET SERVEROUTPUT ON SIZE 1000000
BEGIN
   dbms_output.put_line('Testing nested timers...');
   timer.startme('driver');
   
     dbms_output.put_line('Calling fake proc A...');
     timer.startme('procA');
        dbms_lock.sleep(5);

           dbms_output.put_line('Calling fake proc B...');
           timer.startme('procB');
              dbms_lock.sleep(5);
           timer.stopme('procB');
           dbms_output.put_line('proc B took '||timer.elapsed('procB')||' seconds');

     timer.stopme('procA');
     dbms_output.put_line('proc A took '||timer.elapsed('procA')||' seconds');
     
   timer.stopme('driver');
   dbms_output.put_line('driver took '||timer.elapsed('driver')||' seconds');
   
   dbms_output.put_line('Tested unnamed timer...');
   timer.startme;
   dbms_lock.sleep(3);
   timer.stopme;
   dbms_output.put_line('timer took '||timer.elapsed||' seconds');
END;
/
