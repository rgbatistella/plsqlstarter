PL/SQL Developer Test script 3.0
20
DECLARE
BEGIN
   dbms_output.put_line('get_highdt: '||TO_CHAR(dt.get_highdt,'YYYYMonDD HH24:MI:SS')); 

   dbms_output.put_line('get_sysdt: '||TO_CHAR(dt.get_sysdt,'YYYYMonDD HH24:MI:SS')); 

   dbms_output.put_line('get_sysdtm: '||TO_CHAR(dt.get_sysdtm,'YYYYMonDD HH24:MI:SS')); 

   dbms_output.put_line('get_systs: '||TO_CHAR(dt.get_systs,'YYYYMonDD HH24:MI:SS')); 

   dbms_output.put_line('get_day: '||dt.get_day_name('3'));
   dbms_output.put_line('minutes_to_dhm: '||dt.minutes_to_dhm(1653));
   dbms_output.put_line('minutes_to_hm: '||dt.minutes_to_hm(192));
   dbms_output.put_line('get_age_str: '||dt.get_time_diff_str(TO_DATE('2008Jan01','YYYYMonDD'),TO_DATE('2008Jan03 13:00','YYYYMonDD HH24:MI'),'hm'));

   dbms_output.put_line('get_age_num: '||TO_CHAR(dt.get_time_diff(TRUNC(SYSDATE),TRUNC(SYSDATE+1),'hour')));

   dbms_output.put_line('trunc_dt: '||TO_CHAR(dt.trunc_dt(SYSDATE,15),'YYYYMonDD HH24:MI:SS')); 

END;
0
0
