PL/SQL Developer Test script 3.0
38
begin
  -- Call the procedure
  env.init_client_ctx(i_client_id => 'bcoulam');

   -- Looking for log_id to increment properly, for log_ts to be accurate, for routine_nm to be Unknown unless given by the test,
   -- for call_stack to now be filled, for error_stack to be empty unless the test call to app_log_api is within an exception handler,
   -- for client_id to be correct, and the other client columns to be filled with valid info.
  
  DELETE FROM app_log;
  
  app_log_api.ins(i_log_txt => :i_log_txt);
  
  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd);
                  
  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd);

  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd,
                  i_routine_nm => :i_routine_nm);

  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd,
                  i_routine_nm => :i_routine_nm,
                  i_line_num => :i_line_num);
                  

  app_log_api.ins(i_log_txt => :i_log_txt,
                  i_sev_cd => :i_sev_cd,
                  i_msg_cd => :i_msg_cd,
                  i_routine_nm => $$PLSQL_UNIT,
                  i_line_num => $$PLSQL_LINE);
  COMMIT;                                                                      
end;
5
i_log_txt
1
﻿This is a test log message.
5
i_sev_cd
1
﻿INFO
5
i_msg_cd
1
﻿Ad-Hoc Msg
5
i_routine_nm
1
﻿bogus_proc
5
i_line_num
1
500
3
0
