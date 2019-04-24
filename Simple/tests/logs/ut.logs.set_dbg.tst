PL/SQL Developer Test script 3.0
22
DECLARE
   l_log_txt app_log.log_txt%TYPE;
BEGIN
   -- just in case this has been run before, turn dbg off
   logs.set_dbg(i_dbg_val => 'Off');

   logs.dbg('This would have been my first debug message.');

   logs.set_dbg(i_dbg_val => 'On');
   logs.set_targets(i_stdout => FALSE, i_table => TRUE, i_file => FALSE);

   logs.dbg('But this is the only one that will show since I just turned debugging on.');

   SELECT log_txt
     INTO l_log_txt
     FROM app_log t
    WHERE log_id = (SELECT MAX(log_id)
                      FROM app_log);
                      
   dbms_output.put_line(l_log_txt);
   
END;
0
0
